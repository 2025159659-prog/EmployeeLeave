package dao;

import bean.LeaveRequest;
import util.DatabaseConnection;
import jakarta.servlet.http.Part;

import java.sql.*;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.*;

public class LeaveDAO {

    /* =====================================================
       FETCH LEAVE TYPES (APPLY LEAVE)
       ===================================================== */
    public List<Map<String, Object>> getAllLeaveTypes() throws Exception {

        List<Map<String, Object>> list = new ArrayList<>();

        String sql = """
            SELECT leave_type_id, type_code, description
            FROM leave.leave_types
            ORDER BY type_code
        """;

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> m = new HashMap<>();
                m.put("id", rs.getInt("leave_type_id"));
                m.put("code", rs.getString("type_code"));
                m.put("desc", rs.getString("description"));
                list.add(m);
            }
        }
        return list;
    }

    /* =====================================================
       FETCH SINGLE LEAVE (EDIT / DETAIL)
       ===================================================== */
    public LeaveRequest getLeaveById(int leaveId, int empId) throws Exception {

                String sql = """
                    SELECT lr.*,
                           lt.type_code,
                           ls.status_code,
            
                           e.emergency_category,
                           e.emergency_contact,
            
                           s.medical_facility AS sick_fac,
                           s.ref_serial_no    AS sick_ref,
            
                           h.hospital_name   AS hosp_name,
                           h.admit_date      AS hosp_admit,
                           h.discharge_date  AS hosp_dis,
            
                           p.spouse_name      AS pat_spouse,
                           p.medical_facility AS pat_fac,
                           p.delivery_date    AS pat_del,
            
                           m.consultation_clinic AS mat_clinic,
                           m.expected_due_date   AS mat_due,
                           m.week_pregnancy      AS mat_week
            
                    FROM leave.leave_requests lr
                    JOIN leave.leave_types lt    ON lr.leave_type_id = lt.leave_type_id
                    JOIN leave.leave_statuses ls ON lr.status_id = ls.status_id
            
                    LEFT JOIN leave.lr_emergency e       ON lr.leave_id = e.leave_id
                    LEFT JOIN leave.lr_sick s            ON lr.leave_id = s.leave_id
                    LEFT JOIN leave.lr_hospitalization h ON lr.leave_id = h.leave_id
                    LEFT JOIN leave.lr_paternity p       ON lr.leave_id = p.leave_id
                    LEFT JOIN leave.lr_maternity m       ON lr.leave_id = m.leave_id
            
                    WHERE lr.leave_id = ? AND lr.empid = ?
                """;
            
                try (Connection con = DatabaseConnection.getConnection();
                     PreparedStatement ps = con.prepareStatement(sql)) {
            
                    ps.setInt(1, leaveId);
                    ps.setInt(2, empId);
            
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) return null;
            
                        LeaveRequest lr = new LeaveRequest();
            
                        // 🔹 Base
                        lr.setLeaveId(rs.getInt("leave_id"));
                        lr.setEmpId(rs.getInt("empid"));
                        lr.setLeaveTypeId(rs.getInt("leave_type_id"));
                        lr.setStartDate(rs.getDate("start_date").toLocalDate());
                        lr.setEndDate(rs.getDate("end_date").toLocalDate());
                        lr.setDuration(rs.getString("duration"));
                        lr.setDurationDays(rs.getDouble("duration_days"));
                        lr.setReason(rs.getString("reason"));
                        lr.setHalfSession(rs.getString("half_session"));
                        lr.setStatusCode(rs.getString("status_code"));
                        lr.setManagerComment(rs.getString("manager_comment"));
            
                        String type = rs.getString("type_code");
                        if (type == null) type = "";
                        type = type.toUpperCase();
            
                        // 🔹 METADATA BY TYPE
                        if (type.contains("SICK")) {
                            lr.setMedicalFacility(rs.getString("sick_fac"));
                            lr.setRefSerialNo(rs.getString("sick_ref"));
            
                        } else if (type.contains("EMERGENCY")) {
                            lr.setEmergencyCategory(rs.getString("emergency_category"));
                            lr.setEmergencyContact(rs.getString("emergency_contact"));
            
                        } else if (type.contains("HOSPITAL")) {
                            lr.setMedicalFacility(rs.getString("hosp_name"));
                            if (rs.getDate("hosp_admit") != null)
                                lr.setEventDate(rs.getDate("hosp_admit").toLocalDate());
                            if (rs.getDate("hosp_dis") != null)
                                lr.setDischargeDate(rs.getDate("hosp_dis").toLocalDate());
            
                        } else if (type.contains("PATERNITY")) {
                            lr.setSpouseName(rs.getString("pat_spouse"));
                            lr.setMedicalFacility(rs.getString("pat_fac"));
                            if (rs.getDate("pat_del") != null)
                                lr.setEventDate(rs.getDate("pat_del").toLocalDate());
            
                        } else if (type.contains("MATERNITY")) {
                            lr.setMedicalFacility(rs.getString("mat_clinic"));
                            if (rs.getDate("mat_due") != null)
                                lr.setEventDate(rs.getDate("mat_due").toLocalDate());
                            lr.setWeekPregnancy(rs.getInt("mat_week"));
                        }
            
                        return lr;
                    }
                }
            }

        return null;
    }

    /* =====================================================
       WORKING DAYS CALCULATION
       ===================================================== */
    public double calculateWorkingDays(LocalDate start, LocalDate end) throws Exception {

        Set<LocalDate> holidays = new HashSet<>();

        String sql = """
            SELECT holiday_date
            FROM leave.holidays
            WHERE holiday_date BETWEEN ? AND ?
        """;

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setDate(1, java.sql.Date.valueOf(start));
            ps.setDate(2, java.sql.Date.valueOf(end));

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    holidays.add(rs.getDate(1).toLocalDate());
                }
            }
        }

        double count = 0;
        LocalDate cur = start;

        while (!cur.isAfter(end)) {
            if (cur.getDayOfWeek() != DayOfWeek.SATURDAY &&
                cur.getDayOfWeek() != DayOfWeek.SUNDAY &&
                !holidays.contains(cur)) {
                count++;
            }
            cur = cur.plusDays(1);
        }
        return count;
    }

    /* =====================================================
       SUBMIT LEAVE REQUEST
       ===================================================== */
    public boolean submitRequest(LeaveRequest req, Part filePart) throws Exception {

        Connection con = DatabaseConnection.getConnection();
        try {
            con.setAutoCommit(false);

            int statusId;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT status_id FROM leave.leave_statuses WHERE status_code='PENDING'")) {
                ResultSet rs = ps.executeQuery();
                rs.next();
                statusId = rs.getInt(1);
            }

            int leaveId;
            String insertSql = """
                INSERT INTO leave.leave_requests
                (
                 empid, leave_type_id, status_id,
                 start_date, end_date,
                 duration, duration_days, reason,
                 half_session, applied_on
                )
                VALUES
                (
                 ?, ?, ?, ?, ?, ?, ?, ?, ?, 
                 (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kuala_Lumpur')
                )
            """;

            try (PreparedStatement ps = con.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {
                ps.setInt(1, req.getEmpId());
                ps.setInt(2, req.getLeaveTypeId());
                ps.setInt(3, statusId);
                ps.setDate(4, java.sql.Date.valueOf(req.getStartDate()));
                ps.setDate(5, java.sql.Date.valueOf(req.getEndDate()));
                ps.setString(6, req.getDuration());
                ps.setDouble(7, req.getDurationDays());
                ps.setString(8, req.getReason());
                ps.setString(9, req.getHalfSession());
                ps.executeUpdate();

                ResultSet rs = ps.getGeneratedKeys();
                rs.next();
                leaveId = rs.getInt(1);
            }

            insertInheritedData(con, leaveId, req);

            if (filePart != null && filePart.getSize() > 0) {
                try (PreparedStatement ps = con.prepareStatement("""
                    INSERT INTO leave.leave_request_attachments
                    (leave_id, file_name, mime_type, file_size, file_data, uploaded_on)
                    VALUES (?,?,?,?,?,CURRENT_TIMESTAMP)
                """)) {
                    ps.setInt(1, leaveId);
                    ps.setString(2, filePart.getSubmittedFileName());
                    ps.setString(3, filePart.getContentType());
                    ps.setLong(4, filePart.getSize());
                    ps.setBinaryStream(5, filePart.getInputStream());
                    ps.executeUpdate();
                }
            }

            updateBalance(con, req.getEmpId(), req.getLeaveTypeId(), req.getDurationDays());
            con.commit();
            return true;

        } catch (Exception e) {
            con.rollback();
            throw e;
        } finally {
            con.close();
        }
    }

    /* =====================================================
       EMPLOYEE LEAVE HISTORY (WITH METADATA)
       ===================================================== */
    public List<Map<String, Object>> getLeaveHistory(int empId, String status, String year) throws Exception {

        List<Map<String, Object>> list = new ArrayList<>();

        StringBuilder sql = new StringBuilder("""
            SELECT 
                lr.leave_id,
                lt.type_code,
                ls.status_code,
                lr.start_date,
                lr.end_date,
                lr.duration_days,
                lr.applied_on,
                lr.reason,
                lr.manager_comment,
                e.emergency_category,
                e.emergency_contact,
                EXISTS (
                    SELECT 1 
                    FROM leave.leave_request_attachments a
                    WHERE a.leave_id = lr.leave_id
                ) AS has_file
            FROM leave.leave_requests lr
            JOIN leave.leave_types lt ON lr.leave_type_id = lt.leave_type_id
            JOIN leave.leave_statuses ls ON lr.status_id = ls.status_id
            LEFT JOIN leave.lr_emergency e ON lr.leave_id = e.leave_id
            WHERE lr.empid = ?
        """);

        if (status != null && !status.isBlank() && !"ALL".equalsIgnoreCase(status)) {
            sql.append(" AND UPPER(ls.status_code) = ? ");
        }
        if (year != null && !year.isBlank()) {
            sql.append(" AND EXTRACT(YEAR FROM lr.start_date) = ? ");
        }

        sql.append(" ORDER BY lr.applied_on DESC");

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql.toString())) {

            int idx = 1;
            ps.setInt(idx++, empId);

            if (status != null && !status.isBlank() && !"ALL".equalsIgnoreCase(status)) {
                ps.setString(idx++, status.toUpperCase());
            }
            if (year != null && !year.isBlank()) {
                ps.setInt(idx++, Integer.parseInt(year));
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();

                    m.put("leaveId", rs.getInt("leave_id"));
                    m.put("type", rs.getString("type_code"));
                    m.put("status", rs.getString("status_code"));
                    m.put("startDate", rs.getDate("start_date"));
                    m.put("endDate", rs.getDate("end_date"));
                    m.put("days", rs.getDouble("duration_days"));
                    m.put("appliedOn", rs.getTimestamp("applied_on"));
                    m.put("reason", rs.getString("reason"));
                    m.put("managerRemark", rs.getString("manager_comment"));
                    m.put("hasFile", rs.getBoolean("has_file"));

                    String type = rs.getString("type_code");
                    if (type != null && type.toUpperCase().contains("EMERGENCY")) {
                        m.put("emergencyCategory", rs.getString("emergency_category"));
                        m.put("emergencyContact", rs.getString("emergency_contact"));
                    }

                    list.add(m);
                }
            }
        }
        return list;
    }

    /* =====================================================
       CHILD TABLE HANDLER
       ===================================================== */
    private void insertInheritedData(Connection con, int leaveId, LeaveRequest req) throws Exception {

        String typeCode = "";
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT type_code FROM leave.leave_types WHERE leave_type_id=?")) {
            ps.setInt(1, req.getLeaveTypeId());
            ResultSet rs = ps.executeQuery();
            if (rs.next()) typeCode = rs.getString(1);
        }

        if ("EMERGENCY".equalsIgnoreCase(typeCode)) {
            try (PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO leave.lr_emergency VALUES (?,?,?)")) {
                ps.setInt(1, leaveId);
                ps.setString(2, req.getEmergencyCategory());
                ps.setString(3, req.getEmergencyContact());
                ps.executeUpdate();
            }
        }
    }

    /* =====================================================
       BALANCE UPDATE (PENDING)
       ===================================================== */
    private void updateBalance(Connection con, int empId, int typeId, double days) throws Exception {

        try (PreparedStatement ps = con.prepareStatement("""
            UPDATE leave.leave_balances
            SET pending = pending + ?, total = total - ?
            WHERE empid=? AND leave_type_id=?
        """)) {
            ps.setDouble(1, days);
            ps.setDouble(2, days);
            ps.setInt(3, empId);
            ps.setInt(4, typeId);
            ps.executeUpdate();
        }
    }
        /* =====================================================
       HISTORY YEARS (USED BY LeaveHistory SERVLET)
       ===================================================== */
    public List<String> getHistoryYears(int empId) throws Exception {

        List<String> years = new ArrayList<>();

        String sql = """
            SELECT DISTINCT EXTRACT(YEAR FROM start_date) AS yr
            FROM leave.leave_requests
            WHERE empid = ?
            ORDER BY yr DESC
        """;

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, empId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    years.add(rs.getString("yr"));
                }
            }
        }
        return years;
    }

    /* =====================================================
       DELETE LEAVE (USED BY DeleteLeave SERVLET)
       ===================================================== */
    public boolean deleteLeave(int leaveId, int empId) throws Exception {

        Connection con = DatabaseConnection.getConnection();
        try {
            con.setAutoCommit(false);

            int leaveTypeId;
            double days;

            String fetchSql = """
                SELECT leave_type_id, duration_days
                FROM leave.leave_requests
                WHERE leave_id=? AND empid=?
                  AND status_id = (
                      SELECT status_id
                      FROM leave.leave_statuses
                      WHERE status_code='PENDING'
                  )
            """;

            try (PreparedStatement ps = con.prepareStatement(fetchSql)) {
                ps.setInt(1, leaveId);
                ps.setInt(2, empId);
                ResultSet rs = ps.executeQuery();
                if (!rs.next()) return false;

                leaveTypeId = rs.getInt("leave_type_id");
                days = rs.getDouble("duration_days");
            }

            try (PreparedStatement ps = con.prepareStatement(
                    "DELETE FROM leave.leave_requests WHERE leave_id=? AND empid=?")) {
                ps.setInt(1, leaveId);
                ps.setInt(2, empId);
                ps.executeUpdate();
            }

            try (PreparedStatement ps = con.prepareStatement("""
                UPDATE leave.leave_balances
                SET pending = pending - ?, total = total + ?
                WHERE empid=? AND leave_type_id=?
            """)) {
                ps.setDouble(1, days);
                ps.setDouble(2, days);
                ps.setInt(3, empId);
                ps.setInt(4, leaveTypeId);
                ps.executeUpdate();
            }

            con.commit();
            return true;

        } catch (Exception e) {
            con.rollback();
            throw e;
        } finally {
            con.close();
        }
    }

    /* =====================================================
       REQUEST CANCELLATION (USED BY CancelLeave SERVLET)
       ===================================================== */
    public boolean requestCancellation(int leaveId, int empId) throws Exception {

        String sql = """
            UPDATE leave.leave_requests
            SET status_id = (
                SELECT status_id
                FROM leave.leave_statuses
                WHERE status_code='CANCELLATION_REQUESTED'
            )
            WHERE leave_id=? AND empid=?
              AND status_id = (
                SELECT status_id
                FROM leave.leave_statuses
                WHERE status_code='APPROVED'
              )
        """;

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, leaveId);
            ps.setInt(2, empId);
            return ps.executeUpdate() > 0;
        }
    }

    /* =====================================================
       UPDATE LEAVE (USED BY EditLeave SERVLET)
       ===================================================== */
    public boolean updateLeave(LeaveRequest req, int empId) throws Exception {

        Connection con = DatabaseConnection.getConnection();
        try {
            con.setAutoCommit(false);

            int statusId;

            try (PreparedStatement ps = con.prepareStatement("""
                SELECT status_id
                FROM leave.leave_requests
                WHERE leave_id=? AND empid=?
            """)) {
                ps.setInt(1, req.getLeaveId());
                ps.setInt(2, empId);
                ResultSet rs = ps.executeQuery();
                if (!rs.next()) return false;
                statusId = rs.getInt("status_id");
            }

            try (PreparedStatement ps = con.prepareStatement("""
                SELECT status_id
                FROM leave.leave_statuses
                WHERE status_code='PENDING'
            """)) {
                ResultSet rs = ps.executeQuery();
                rs.next();
                if (statusId != rs.getInt(1)) return false;
            }

            try (PreparedStatement ps = con.prepareStatement("""
                UPDATE leave.leave_requests
                SET start_date=?, end_date=?, duration=?, duration_days=?,
                    reason=?, half_session=?
                WHERE leave_id=? AND empid=?
            """)) {
                ps.setDate(1, java.sql.Date.valueOf(req.getStartDate()));
                ps.setDate(2, java.sql.Date.valueOf(req.getEndDate()));
                ps.setString(3, req.getDuration());
                ps.setDouble(4, req.getDurationDays());
                ps.setString(5, req.getReason());
                ps.setString(6, req.getHalfSession());
                ps.setInt(7, req.getLeaveId());
                ps.setInt(8, empId);
                ps.executeUpdate();
            }

            con.commit();
            return true;

        } catch (Exception e) {
            con.rollback();
            throw e;
        } finally {
            con.close();
        }
    }

}


