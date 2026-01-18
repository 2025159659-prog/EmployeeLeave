package dao;

import bean.LeaveRequest;
import bean.LeaveBalance;
import util.DatabaseConnection;
import jakarta.servlet.http.Part;

import java.io.InputStream;
import java.sql.*;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.*;

public class LeaveDAO {

    /* =====================================================
       FETCH LEAVE TYPES (FIXED SCHEMA ISSUE)
       ===================================================== */
    public List<Map<String, Object>> getAllLeaveTypes() throws Exception {

        List<Map<String, Object>> list = new ArrayList<>();

        String sql = """
            SELECT 
                leave_type_id,
                type_code,
                description
            FROM leave.leave_types
            ORDER BY leave_type_id
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
       GET SINGLE LEAVE
       ===================================================== */
    public LeaveRequest getLeaveById(int leaveId, int empId) throws Exception {

        String sql = """
            SELECT lr.*, ls.status_code, lt.type_code,
                   e.emergency_category, e.emergency_contact,
                   s.medical_facility AS s_fac, s.ref_serial_no AS s_ref,
                   h.hospital_name AS h_name, h.admit_date AS h_admit, h.discharge_date AS h_dis,
                   m.consultation_clinic AS m_clinic, m.expected_due_date AS m_due, m.week_pregnancy AS m_week,
                   p.spouse_name AS p_spouse, p.medical_facility AS p_fac, p.delivery_date AS p_del
            FROM leave.leave_requests lr
            JOIN leave.leave_statuses ls ON lr.status_id = ls.status_id
            JOIN leave.leave_types lt ON lr.leave_type_id = lt.leave_type_id
            LEFT JOIN leave.lr_emergency e ON lr.leave_id = e.leave_id
            LEFT JOIN leave.lr_sick s ON lr.leave_id = s.leave_id
            LEFT JOIN leave.lr_hospitalization h ON lr.leave_id = h.leave_id
            LEFT JOIN leave.lr_maternity m ON lr.leave_id = m.leave_id
            LEFT JOIN leave.lr_paternity p ON lr.leave_id = p.leave_id
            WHERE lr.leave_id = ? AND lr.empid = ?
        """;

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, leaveId);
            ps.setInt(2, empId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;

                LeaveRequest lr = new LeaveRequest();
                lr.setLeaveId(rs.getInt("leave_id"));
                lr.setEmpId(rs.getInt("empid"));
                lr.setLeaveTypeId(rs.getInt("leave_type_id"));
                lr.setStartDate(rs.getDate("start_date").toLocalDate());
                lr.setEndDate(rs.getDate("end_date").toLocalDate());
                lr.setDuration(rs.getString("duration"));
                lr.setDurationDays(rs.getDouble("duration_days"));
                lr.setReason(rs.getString("reason"));
                lr.setStatusCode(rs.getString("status_code"));
                lr.setHalfSession(rs.getString("half_session"));

                String type = rs.getString("type_code");

                switch (type) {
                    case "EMERGENCY" -> {
                        lr.setEmergencyCategory(rs.getString("emergency_category"));
                        lr.setEmergencyContact(rs.getString("emergency_contact"));
                    }
                    case "SICK" -> {
                        lr.setMedicalFacility(rs.getString("s_fac"));
                        lr.setRefSerialNo(rs.getString("s_ref"));
                    }
                    case "HOSPITALIZATION" -> {
                        lr.setMedicalFacility(rs.getString("h_name"));
                        if (rs.getDate("h_admit") != null)
                            lr.setEventDate(rs.getDate("h_admit").toLocalDate());
                        if (rs.getDate("h_dis") != null)
                            lr.setDischargeDate(rs.getDate("h_dis").toLocalDate());
                    }
                    case "MATERNITY" -> {
                        lr.setMedicalFacility(rs.getString("m_clinic"));
                        if (rs.getDate("m_due") != null)
                            lr.setEventDate(rs.getDate("m_due").toLocalDate());
                        lr.setWeekPregnancy(rs.getInt("m_week"));
                    }
                    case "PATERNITY" -> {
                        lr.setSpouseName(rs.getString("p_spouse"));
                        lr.setMedicalFacility(rs.getString("p_fac"));
                        if (rs.getDate("p_del") != null)
                            lr.setEventDate(rs.getDate("p_del").toLocalDate());
                    }
                }
                return lr;
            }
        }
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

            ps.setDate(1, Date.valueOf(start));
            ps.setDate(2, Date.valueOf(end));

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    holidays.add(rs.getDate(1).toLocalDate());
            }
        }

        double count = 0;
        LocalDate curr = start;

        while (!curr.isAfter(end)) {
            if (curr.getDayOfWeek() != DayOfWeek.SATURDAY &&
                curr.getDayOfWeek() != DayOfWeek.SUNDAY &&
                !holidays.contains(curr)) {
                count++;
            }
            curr = curr.plusDays(1);
        }
        return count;
    }

    /* =====================================================
       BALANCE UPDATE (ENGINE SAFE)
       ===================================================== */
    private void updateBalance(Connection con, int empId, int typeId, double days) throws Exception {

        String sql = """
            UPDATE leave.leave_balances
            SET pending = pending + ?,
                total = total - ?
            WHERE empid = ? AND leave_type_id = ?
        """;

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setDouble(1, days);
            ps.setDouble(2, days);
            ps.setInt(3, empId);
            ps.setInt(4, typeId);
            ps.executeUpdate();
        }
    }
}
