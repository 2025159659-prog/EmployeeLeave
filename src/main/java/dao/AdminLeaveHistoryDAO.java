package dao;

import bean.LeaveRecord;
import util.DatabaseConnection;

import java.sql.*;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * AdminLeaveHistoryDAO handles database operations for the admin leave history
 * view using Class Table Inheritance to fetch metadata from specific sub-tables.
 */
public class AdminLeaveHistoryDAO {

    private final SimpleDateFormat sdfDate = new SimpleDateFormat("dd/MM/yyyy");
    private final SimpleDateFormat sdfTime = new SimpleDateFormat("dd/MM/yyyy HH:mm");

    /* =========================================================
       FILTER YEARS
       ========================================================= */
    public List<String> getFilterYears() throws Exception {
        List<String> years = new ArrayList<>();

        String sql = """
            SELECT DISTINCT EXTRACT(YEAR FROM start_date) AS yr
            FROM leave.leave_requests
            ORDER BY yr DESC
        """;

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                years.add(rs.getString("yr"));
            }
        }
        return years;
    }

    /* =========================================================
       FETCH ALL HISTORY (ADMIN)
       ========================================================= */
    public List<LeaveRecord> getAllHistory(String status, String month, String year) throws Exception {

        List<LeaveRecord> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder();

        sql.append("""
            SELECT lr.*,
                   u.fullname,
                   u.empid AS user_id,
                   u.hiredate,
                   u.profile_picture,
                   lt.type_code,
                   ls.status_code,

                   e.emergency_category,
                   e.emergency_contact,

                   s.medical_facility AS sick_fac,
                   s.ref_serial_no    AS sick_ref,

                   h.hospital_name   AS hosp_name,
                   h.admit_date      AS hosp_admit,
                   h.discharge_date  AS hosp_dis,

                   m.consultation_clinic AS mat_clinic,
                   m.expected_due_date   AS mat_due,
                   m.week_pregnancy      AS mat_week,

                   p.spouse_name      AS pat_spouse,
                   p.medical_facility AS pat_fac,
                   p.delivery_date    AS pat_del,

                   (
                     SELECT a.file_name
                     FROM leave.leave_request_attachments a
                     WHERE a.leave_id = lr.leave_id
                     FETCH FIRST 1 ROW ONLY
                   ) AS attachment_name

            FROM leave.leave_requests lr
            JOIN leave.users u           ON lr.empid = u.empid
            JOIN leave.leave_types lt    ON lr.leave_type_id = lt.leave_type_id
            JOIN leave.leave_statuses ls ON lr.status_id = ls.status_id

            LEFT JOIN leave.lr_emergency e        ON lr.leave_id = e.leave_id
            LEFT JOIN leave.lr_sick s             ON lr.leave_id = s.leave_id
            LEFT JOIN leave.lr_hospitalization h  ON lr.leave_id = h.leave_id
            LEFT JOIN leave.lr_maternity m        ON lr.leave_id = m.leave_id
            LEFT JOIN leave.lr_paternity p        ON lr.leave_id = p.leave_id

            WHERE 1=1
        """);

        /* ===== STATUS FILTER ===== */
        if (status != null && !status.isEmpty() && !"ALL".equalsIgnoreCase(status)) {
            sql.append(" AND UPPER(ls.status_code) = ? ");
        }

        /* ===== YEAR FILTER ===== */
        if (year != null && !year.isEmpty()) {
            sql.append(" AND EXTRACT(YEAR FROM lr.start_date) = ? ");
        }

        /* ===== MONTH FILTER (FIXED) ===== */
        if (month != null
                && !month.isEmpty()
                && !"FULL YEAR".equalsIgnoreCase(month)) {
            sql.append(" AND EXTRACT(MONTH FROM lr.start_date) = ? ");
        }

        sql.append(" ORDER BY lr.applied_on DESC ");

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql.toString())) {

            int idx = 1;

            if (status != null && !status.isEmpty() && !"ALL".equalsIgnoreCase(status)) {
                ps.setString(idx++, status.toUpperCase());
            }

            if (year != null && !year.isEmpty()) {
                ps.setInt(idx++, Integer.parseInt(year));
            }

            if (month != null
                    && !month.isEmpty()
                    && !"FULL YEAR".equalsIgnoreCase(month)) {
                ps.setInt(idx++, Integer.parseInt(month));
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapResultSetToRecord(rs));
                }
            }
        }

        return list;
    }

    /* =========================================================
       MAP RESULTSET → LEAVERECORD
       ========================================================= */
    private LeaveRecord mapResultSetToRecord(ResultSet rs) throws SQLException {

        LeaveRecord r = new LeaveRecord();

        r.setLeaveId(rs.getInt("leave_id"));
        r.setEmpId(rs.getInt("user_id"));
        r.setFullName(rs.getString("fullname"));
        r.setHireDate(rs.getDate("hiredate"));
        r.setProfilePic(rs.getString("profile_picture"));

        r.setTypeCode(rs.getString("type_code"));
        r.setStatusCode(rs.getString("status_code"));
        r.setDurationDays(rs.getDouble("duration_days"));
        r.setDuration(rs.getString("duration"));
        r.setLeaveTypeId(rs.getString("leave_type_id"));

        if (rs.getDate("start_date") != null)
            r.setStartDate(sdfDate.format(rs.getDate("start_date")));

        if (rs.getDate("end_date") != null)
            r.setEndDate(sdfDate.format(rs.getDate("end_date")));

        if (rs.getTimestamp("applied_on") != null)
            r.setAppliedOn(sdfTime.format(rs.getTimestamp("applied_on")));

        r.setReason(rs.getString("reason"));
        r.setManagerComment(rs.getString("manager_comment"));
        r.setAttachment(rs.getString("attachment_name"));

        String type = rs.getString("type_code");

        if ("SICK".equals(type)) {
            r.setMedicalFacility(rs.getString("sick_fac"));
            r.setRefSerialNo(rs.getString("sick_ref"));

        } else if ("EMERGENCY".equals(type)) {
            r.setEmergencyCategory(rs.getString("emergency_category"));
            r.setEmergencyContact(rs.getString("emergency_contact"));

        } else if ("HOSPITALIZATION".equals(type)) {
            r.setMedicalFacility(rs.getString("hosp_name"));
            if (rs.getDate("hosp_admit") != null)
                r.setEventDate(sdfDate.format(rs.getDate("hosp_admit")));
            if (rs.getDate("hosp_dis") != null)
                r.setDischargeDate(sdfDate.format(rs.getDate("hosp_dis")));

        } else if ("MATERNITY".equals(type)) {
            r.setMedicalFacility(rs.getString("mat_clinic"));
            if (rs.getDate("mat_due") != null)
                r.setEventDate(sdfDate.format(rs.getDate("mat_due")));
            r.setWeekPregnancy(rs.getInt("mat_week"));

        } else if ("PATERNITY".equals(type)) {
            r.setSpouseName(rs.getString("pat_spouse"));
            r.setMedicalFacility(rs.getString("pat_fac"));
            if (rs.getDate("pat_del") != null)
                r.setEventDate(sdfDate.format(rs.getDate("pat_del")));
        }

        return r;
    }

    /* =========================================================
       WORKING DAYS CALCULATOR
       ========================================================= */
    public double calculateWorkingDays(LocalDate start, LocalDate end) throws Exception {

        double count = 0;
        Set<LocalDate> holidays = new HashSet<>();

        try (Connection con = DatabaseConnection.getConnection()) {
            String sql = "SELECT holiday_date FROM holidays WHERE holiday_date BETWEEN ? AND ?";

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setDate(1, java.sql.Date.valueOf(start));
                ps.setDate(2, java.sql.Date.valueOf(end));

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        holidays.add(rs.getDate("holiday_date").toLocalDate());
                    }
                }
            }
        }

        LocalDate curr = start;
        while (!curr.isAfter(end)) {
            if (curr.getDayOfWeek() != DayOfWeek.SATURDAY
                    && curr.getDayOfWeek() != DayOfWeek.SUNDAY
                    && !holidays.contains(curr)) {
                count++;
            }
            curr = curr.plusDays(1);
        }
        return count;
    }
}

