package dao;

import bean.LeaveRequest;
import bean.LeaveBalance;
import util.DatabaseConnection;
import jakarta.servlet.http.Part;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.*;

public class LeaveDAO {

    /* =====================================================
       FETCH LEAVE TYPES (FOR APPLY LEAVE)
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


    /**
 * Fetch leave request by ID + EMPID (FOR EDIT LEAVE)
 */
public LeaveRequest getLeaveById(int leaveId, int empId) throws Exception {

    String sql = """
        SELECT lr.*, lt.type_code, ls.status_code
        FROM leave.leave_requests lr
        JOIN leave.leave_types lt ON lr.leave_type_id = lt.leave_type_id
        JOIN leave.leave_statuses ls ON lr.status_id = ls.status_id
        WHERE lr.leave_id = ? AND lr.empid = ?
    """;

    try (Connection con = DatabaseConnection.getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {

        ps.setInt(1, leaveId);
        ps.setInt(2, empId);

        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                LeaveRequest lr = new LeaveRequest();
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

            int statusId = 0;
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT status_id FROM leave.leave_statuses WHERE UPPER(status_code)='PENDING'")) {
                ResultSet rs = ps.executeQuery();
                if (rs.next()) statusId = rs.getInt(1);
            }

            int leaveId;
            String parentSql = """
                INSERT INTO leave.leave_requests
                (empid, leave_type_id, status_id, start_date, end_date,
                 duration, duration_days, reason, half_session, applied_on)
                VALUES (?,?,?,?,?,?,?,?,?,CURRENT_TIMESTAMP)
            """;

            try (PreparedStatement ps = con.prepareStatement(parentSql, Statement.RETURN_GENERATED_KEYS)) {
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
       UPDATE / DELETE / CANCEL
       ===================================================== */
    public boolean updateLeave(LeaveRequest req, int empId) throws Exception { return true; }

    public boolean deleteLeave(int leaveId, int empId) throws Exception { return true; }

    public boolean requestCancellation(int leaveId, int empId) throws Exception { return true; }

    /* =====================================================
       HISTORY
       ===================================================== */
    public List<Map<String, Object>> getLeaveHistory(int empId, String status, String year) throws Exception {
        return new ArrayList<>();
    }

    public List<String> getHistoryYears(int empId) throws Exception {
        return new ArrayList<>();
    }

    /* =====================================================
       CHILD TABLE INSERT
       ===================================================== */
    private void insertInheritedData(Connection con, int leaveId, LeaveRequest req) throws Exception {

        String typeCode = "";
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT type_code FROM leave.leave_types WHERE leave_type_id=?")) {
            ps.setInt(1, req.getLeaveTypeId());
            ResultSet rs = ps.executeQuery();
            if (rs.next()) typeCode = rs.getString(1);
        }

        if ("EMERGENCY".equals(typeCode)) {
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
       BALANCE ENGINE SAFE
       ===================================================== */
    private void updateBalance(Connection con, int empId, int typeId, double days) throws Exception {

        try (PreparedStatement ps = con.prepareStatement("""
            UPDATE leave.leave_balances
            SET pending = pending + ?, total = total - ?
            WHERE empid = ? AND leave_type_id = ?
        """)) {
            ps.setDouble(1, days);
            ps.setDouble(2, days);
            ps.setInt(3, empId);
            ps.setInt(4, typeId);
            ps.executeUpdate();
        }
    }
}




