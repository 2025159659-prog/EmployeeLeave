package dao;

import bean.LeaveRecord;
import bean.LeaveRequest;
import util.DatabaseConnection;
import jakarta.servlet.http.Part;
import java.io.InputStream;
import java.sql.*;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.*;

public class LeaveDAO {

    /**
     * Fetch all leave types for dropdown selection.
     */
    public List<Map<String, Object>> getAllLeaveTypes() throws Exception {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT LEAVE_TYPE_ID, TYPE_CODE, DESCRIPTION FROM LEAVE_TYPES ORDER BY TYPE_CODE";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> m = new HashMap<>();
                m.put("id", rs.getInt("LEAVE_TYPE_ID"));
                m.put("code", rs.getString("TYPE_CODE"));
                m.put("desc", rs.getString("DESCRIPTION"));
                list.add(m);
            }
        }
        return list;
    }

    /**
     * Fetch a specific leave request (Used for editing).
     */
    public LeaveRecord getLeaveById(int leaveId, int empId) throws Exception {
        String sql = "SELECT lr.*, ls.STATUS_CODE FROM LEAVE_REQUESTS lr " +
                     "JOIN LEAVE_STATUSES ls ON ls.STATUS_ID = lr.STATUS_ID " +
                     "WHERE lr.LEAVE_ID = ? AND lr.EMPID = ?";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, leaveId);
            ps.setInt(2, empId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    LeaveRecord lr = new LeaveRecord();
                    lr.setId(rs.getInt("LEAVE_ID"));
                    lr.setLeaveTypeId(rs.getInt("LEAVE_TYPE_ID"));
                    lr.setStartDate(rs.getDate("START_DATE"));
                    lr.setEndDate(rs.getDate("END_DATE"));
                    lr.setDbDuration(rs.getString("DURATION"));
                    lr.setHalfSession(rs.getString("HALF_SESSION"));
                    lr.setReason(rs.getString("REASON"));
                    lr.setStatusCode(rs.getString("STATUS_CODE"));
                    return lr;
                }
            }
        }
        return null;
    }

    /**
     * Update an existing pending leave request.
     */
    public boolean updateLeave(LeaveRecord lr, int empId) throws Exception {
        String sql = "UPDATE LEAVE_REQUESTS SET LEAVE_TYPE_ID=?, START_DATE=?, END_DATE=?, DURATION=?, " +
                     "HALF_SESSION=?, DURATION_DAYS=?, REASON=? WHERE LEAVE_ID=? AND EMPID=? " +
                     "AND STATUS_ID=(SELECT STATUS_ID FROM LEAVE_STATUSES WHERE UPPER(STATUS_CODE)='PENDING')";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, lr.getLeaveTypeId());
            ps.setDate(2, new java.sql.Date(lr.getStartDate().getTime()));
            ps.setDate(3, new java.sql.Date(lr.getEndDate().getTime()));
            ps.setString(4, lr.getDbDuration());
            ps.setString(5, lr.getHalfSession());
            ps.setDouble(6, lr.getTotalDays());
            ps.setString(7, lr.getReason());
            ps.setInt(8, lr.getId());
            ps.setInt(9, empId);
            return ps.executeUpdate() == 1;
        }
    }

    /**
     * Calculate working days excluding Weekends and Holidays.
     */
    public double calculateWorkingDays(LocalDate start, LocalDate end) throws Exception {
        double count = 0;
        Set<LocalDate> holidays = new HashSet<>();
        try (Connection con = DatabaseConnection.getConnection()) {
            String sql = "SELECT HOLIDAY_DATE FROM HOLIDAYS WHERE HOLIDAY_DATE BETWEEN ? AND ?";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setDate(1, java.sql.Date.valueOf(start));
                ps.setDate(2, java.sql.Date.valueOf(end));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) holidays.add(rs.getDate("HOLIDAY_DATE").toLocalDate());
                }
            }
        }
        LocalDate curr = start;
        while (!curr.isAfter(end)) {
            if (curr.getDayOfWeek() != DayOfWeek.SATURDAY && curr.getDayOfWeek() != DayOfWeek.SUNDAY && !holidays.contains(curr)) {
                count++;
            }
            curr = curr.plusDays(1);
        }
        return count;
    }

    /**
     * Submit a new leave request with attachment and balance update.
     */
    public boolean submitRequest(LeaveRequest req, Part filePart) throws Exception {
        Connection con = null;
        try {
            con = DatabaseConnection.getConnection();
            con.setAutoCommit(false);

            int statusId = 0;
            String statusSql = "SELECT STATUS_ID FROM LEAVE_STATUSES WHERE UPPER(STATUS_CODE) = 'PENDING'";
            try (PreparedStatement ps = con.prepareStatement(statusSql); 
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) statusId = rs.getInt("STATUS_ID");
            }

            String sql = "INSERT INTO LEAVE_REQUESTS (EMPID, LEAVE_TYPE_ID, STATUS_ID, START_DATE, END_DATE, DURATION, DURATION_DAYS, REASON, HALF_SESSION, MEDICAL_FACILITY, REF_SERIAL_NO, EVENT_DATE, DISCHARGE_DATE, EMERGENCY_CATEGORY, EMERGENCY_CONTACT, SPOUSE_NAME, APPLIED_ON) " +
                         "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?, SYSDATE)";
            
            int leaveId = 0;
            try (PreparedStatement ps = con.prepareStatement(sql, new String[]{"LEAVE_ID"})) {
                ps.setInt(1, req.getEmpId());
                ps.setInt(2, req.getLeaveTypeId());
                ps.setInt(3, statusId);
                ps.setDate(4, java.sql.Date.valueOf(req.getStartDate()));
                ps.setDate(5, java.sql.Date.valueOf(req.getEndDate()));
                ps.setString(6, req.getDuration());
                ps.setDouble(7, req.getDurationDays());
                ps.setString(8, req.getReason());
                ps.setString(9, req.getHalfSession());
                ps.setString(10, req.getMedicalFacility());
                ps.setString(11, req.getRefSerialNo());
                ps.setDate(12, req.getEventDate() != null ? java.sql.Date.valueOf(req.getEventDate()) : null);
                ps.setDate(13, req.getDischargeDate() != null ? java.sql.Date.valueOf(req.getDischargeDate()) : null);
                ps.setString(14, req.getEmergencyCategory());
                ps.setString(15, req.getEmergencyContact());
                ps.setString(16, req.getSpouseName());
                ps.executeUpdate();
                
                try (ResultSet keys = ps.getGeneratedKeys()) { 
                    if (keys.next()) leaveId = keys.getInt(1); 
                    else throw new SQLException("Generated ID failed.");
                }
            }

            if (filePart != null && filePart.getSize() > 0) {
                String fileSql = "INSERT INTO LEAVE_REQUEST_ATTACHMENTS (LEAVE_ID, FILE_NAME, MIME_TYPE, FILE_SIZE, FILE_DATA, UPLOADED_ON) VALUES (?,?,?,?,?, SYSDATE)";
                try (PreparedStatement ps = con.prepareStatement(fileSql); 
                     InputStream in = filePart.getInputStream()) {
                    ps.setInt(1, leaveId);
                    ps.setString(2, filePart.getSubmittedFileName());
                    ps.setString(3, filePart.getContentType());
                    ps.setLong(4, filePart.getSize());
                    ps.setBinaryStream(5, in);
                    ps.executeUpdate();
                }
            }

            String merge = "MERGE INTO LEAVE_BALANCES b USING (SELECT ? AS E, ? AS T FROM dual) x ON (b.EMPID=x.E AND b.LEAVE_TYPE_ID=x.T) " +
                           "WHEN NOT MATCHED THEN INSERT (EMPID, LEAVE_TYPE_ID, ENTITLEMENT, CARRIED_FWD, USED, PENDING, TOTAL) VALUES (?,?,0,0,0,0,0)";
            try (PreparedStatement ps = con.prepareStatement(merge)) {
                ps.setInt(1, req.getEmpId()); 
                ps.setInt(2, req.getLeaveTypeId());
                ps.setInt(3, req.getEmpId()); 
                ps.setInt(4, req.getLeaveTypeId());
                ps.executeUpdate();
            }

            String upd = "UPDATE LEAVE_BALANCES SET PENDING = NVL(PENDING,0) + ?, " +
                         "TOTAL = (NVL(ENTITLEMENT,0) + NVL(CARRIED_FWD,0)) - (NVL(USED,0) + (NVL(PENDING,0) + ?)) " +
                         "WHERE EMPID = ? AND LEAVE_TYPE_ID = ?";
            try (PreparedStatement ps = con.prepareStatement(upd)) {
                ps.setDouble(1, req.getDurationDays()); 
                ps.setDouble(2, req.getDurationDays());
                ps.setInt(3, req.getEmpId()); 
                ps.setInt(4, req.getLeaveTypeId());
                ps.executeUpdate();
            }

            con.commit();
            return true;
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (con != null) con.close();
        }
    }

    //Delete a pending leave request and restore the balance.
    public boolean deleteLeave(int leaveId, int empId) throws Exception {
        Connection con = null;
        try {
            con = DatabaseConnection.getConnection();
            con.setAutoCommit(false);

            double duration = 0;
            int typeId = 0;
            
            // Verify ownership and PENDING status, then get data for restoration
            String checkSql = "SELECT DURATION_DAYS, LEAVE_TYPE_ID FROM LEAVE_REQUESTS " +
                             "WHERE LEAVE_ID = ? AND EMPID = ? " +
                             "AND STATUS_ID = (SELECT STATUS_ID FROM LEAVE_STATUSES WHERE UPPER(STATUS_CODE) = 'PENDING')";
            
            try (PreparedStatement ps = con.prepareStatement(checkSql)) {
                ps.setInt(1, leaveId);
                ps.setInt(2, empId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        duration = rs.getDouble("DURATION_DAYS");
                        typeId = rs.getInt("LEAVE_TYPE_ID");
                    } else {
                        return false; 
                    }
                }
            }

            // Delete the leave request from History 
            try (PreparedStatement ps = con.prepareStatement("DELETE FROM LEAVE_REQUESTS WHERE LEAVE_ID = ?")) {
                ps.setInt(1, leaveId);
                ps.executeUpdate();
            }

            //  Restore the Leave Balance (Remove from PENDING, add back to TOTAL)
            String restoreSql = "UPDATE LEAVE_BALANCES SET PENDING = PENDING - ?, TOTAL = TOTAL + ? " +
                               "WHERE EMPID = ? AND LEAVE_TYPE_ID = ?";
            try (PreparedStatement ps = con.prepareStatement(restoreSql)) {
                ps.setDouble(1, duration);
                ps.setDouble(2, duration);
                ps.setInt(3, empId);
                ps.setInt(4, typeId);
                ps.executeUpdate();
            }

            con.commit();
            return true;
        } catch (Exception e) {
            if (con != null) con.rollback();
            throw e;
        } finally {
            if (con != null) con.close();
        }
    }

    
    // Request cancellation for an approved leave.
    public boolean requestCancellation(int leaveId, int empId) throws Exception {
        String sql = "UPDATE LEAVE_REQUESTS SET STATUS_ID = " +
                     "(SELECT STATUS_ID FROM LEAVE_STATUSES WHERE UPPER(STATUS_CODE) = 'CANCELLATION_REQUESTED') " +
                     "WHERE LEAVE_ID = ? AND EMPID = ? " +
                     "AND STATUS_ID = (SELECT STATUS_ID FROM LEAVE_STATUSES WHERE UPPER(STATUS_CODE) = 'APPROVED')";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, leaveId);
            ps.setInt(2, empId);
            return ps.executeUpdate() > 0;
        }
    }
}