package dao;

import bean.LeaveRequest;
import bean.LeaveBalance;
import bean.LeaveRecord;
import util.DatabaseConnection;
import jakarta.servlet.http.Part;
import java.io.InputStream;
import java.sql.*;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.*;
import java.util.Date;

public class LeaveDAO {

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

    public LeaveRequest getLeaveById(int leaveId, int empId) throws Exception {
        String sql = "SELECT lr.*, ls.STATUS_CODE FROM LEAVE_REQUESTS lr " +
                     "JOIN LEAVE_STATUSES ls ON lr.STATUS_ID = ls.STATUS_ID " +
                     "WHERE lr.LEAVE_ID = ? AND lr.EMPID = ?";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, leaveId);
            ps.setInt(2, empId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    LeaveRequest lr = new LeaveRequest();
                    lr.setLeaveId(rs.getInt("LEAVE_ID"));
                    lr.setEmpId(rs.getInt("EMPID"));
                    lr.setLeaveTypeId(rs.getInt("LEAVE_TYPE_ID"));
                    lr.setStartDate(rs.getDate("START_DATE").toLocalDate());
                    lr.setEndDate(rs.getDate("END_DATE").toLocalDate());
                    lr.setDuration(rs.getString("DURATION"));
                    lr.setDurationDays(rs.getDouble("DURATION_DAYS"));
                    lr.setReason(rs.getString("REASON"));
                    lr.setStatusCode(rs.getString("STATUS_CODE"));
                    lr.setHalfSession(rs.getString("HALF_SESSION"));
                    lr.setMedicalFacility(rs.getString("MEDICAL_FACILITY"));
                    lr.setRefSerialNo(rs.getString("REF_SERIAL_NO"));
                    lr.setEmergencyCategory(rs.getString("EMERGENCY_CATEGORY"));
                    lr.setEmergencyContact(rs.getString("EMERGENCY_CONTACT"));
                    lr.setSpouseName(rs.getString("SPOUSE_NAME"));
                    
                    Date evt = rs.getDate("EVENT_DATE");
                    if (evt != null) lr.setEventDate(((java.sql.Date) evt).toLocalDate());
                    
                    Date dis = rs.getDate("DISCHARGE_DATE");
                    if (dis != null) lr.setDischargeDate(((java.sql.Date) dis).toLocalDate());
                    
                    return lr;
                }
            }
        }
        return null;
    }

    public double calculateWorkingDays(LocalDate start, LocalDate end) throws Exception {
        double count = 0;
        Set<LocalDate> holidays = new HashSet<>();
        try (Connection con = DatabaseConnection.getConnection()) {
            String sql = "SELECT HOLIDAY_DATE FROM HOLIDAYS WHERE HOLIDAY_DATE BETWEEN ? AND ?";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setDate(1, java.sql.Date.valueOf(start));
                ps.setDate(2, java.sql.Date.valueOf(end));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        holidays.add(rs.getDate("HOLIDAY_DATE").toLocalDate());
                    }
                }
            }
        }
        LocalDate curr = start;
        while (!curr.isAfter(end)) {
            DayOfWeek dow = curr.getDayOfWeek();
            if (dow != DayOfWeek.SATURDAY && dow != DayOfWeek.SUNDAY && !holidays.contains(curr)) {
                count++;
            }
            curr = curr.plusDays(1);
        }
        return count;
    }

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

            String sql = "INSERT INTO LEAVE_REQUESTS (EMPID, LEAVE_TYPE_ID, STATUS_ID, START_DATE, END_DATE, " +
                         "DURATION, DURATION_DAYS, REASON, HALF_SESSION, MEDICAL_FACILITY, REF_SERIAL_NO, " +
                         "EVENT_DATE, DISCHARGE_DATE, EMERGENCY_CATEGORY, EMERGENCY_CONTACT, SPOUSE_NAME, APPLIED_ON) " +
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
                
                try (ResultSet rs = ps.getGeneratedKeys()) { 
                    if (rs.next()) leaveId = rs.getInt(1); 
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

    public boolean updateLeave(LeaveRequest req, int empId) throws Exception {
        Connection con = null;
        try {
            con = DatabaseConnection.getConnection();
            con.setAutoCommit(false);

            double oldDuration = 0;
            int oldTypeId = 0;
            String checkSql = "SELECT DURATION_DAYS, LEAVE_TYPE_ID FROM LEAVE_REQUESTS WHERE LEAVE_ID = ? AND EMPID = ?";
            try (PreparedStatement ps = con.prepareStatement(checkSql)) {
                ps.setInt(1, req.getLeaveId());
                ps.setInt(2, empId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        oldDuration = rs.getDouble("DURATION_DAYS");
                        oldTypeId = rs.getInt("LEAVE_TYPE_ID");
                    } else return false;
                }
            }

            String sql = "UPDATE LEAVE_REQUESTS SET LEAVE_TYPE_ID=?, START_DATE=?, END_DATE=?, DURATION=?, " +
                         "HALF_SESSION=?, DURATION_DAYS=?, REASON=?, MEDICAL_FACILITY=?, REF_SERIAL_NO=?, " +
                         "EVENT_DATE=?, DISCHARGE_DATE=?, EMERGENCY_CATEGORY=?, EMERGENCY_CONTACT=?, SPOUSE_NAME=? " +
                         "WHERE LEAVE_ID=? AND EMPID=? " +
                         "AND STATUS_ID=(SELECT STATUS_ID FROM LEAVE_STATUSES WHERE UPPER(STATUS_CODE)='PENDING')";
            
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, req.getLeaveTypeId());
                ps.setDate(2, java.sql.Date.valueOf(req.getStartDate()));
                ps.setDate(3, java.sql.Date.valueOf(req.getEndDate()));
                ps.setString(4, req.getDuration());
                ps.setString(5, req.getHalfSession());
                ps.setDouble(6, req.getDurationDays());
                ps.setString(7, req.getReason());
                ps.setString(8, req.getMedicalFacility());
                ps.setString(9, req.getRefSerialNo());
                ps.setDate(10, req.getEventDate() != null ? java.sql.Date.valueOf(req.getEventDate()) : null);
                ps.setDate(11, req.getDischargeDate() != null ? java.sql.Date.valueOf(req.getDischargeDate()) : null);
                ps.setString(12, req.getEmergencyCategory());
                ps.setString(13, req.getEmergencyContact());
                ps.setString(14, req.getSpouseName());
                ps.setInt(15, req.getLeaveId());
                ps.setInt(16, empId);
                
                if (ps.executeUpdate() == 0) {
                    con.rollback();
                    return false;
                }
            }

            if (oldTypeId == req.getLeaveTypeId()) {
                double diff = req.getDurationDays() - oldDuration;
                String upd = "UPDATE LEAVE_BALANCES SET PENDING = PENDING + ?, TOTAL = TOTAL - ? WHERE EMPID = ? AND LEAVE_TYPE_ID = ?";
                try (PreparedStatement ps = con.prepareStatement(upd)) {
                    ps.setDouble(1, diff);
                    ps.setDouble(2, diff);
                    ps.setInt(3, empId);
                    ps.setInt(4, req.getLeaveTypeId());
                    ps.executeUpdate();
                }
            } else {
                String restore = "UPDATE LEAVE_BALANCES SET PENDING = PENDING - ?, TOTAL = TOTAL + ? WHERE EMPID = ? AND LEAVE_TYPE_ID = ?";
                try (PreparedStatement ps = con.prepareStatement(restore)) {
                    ps.setDouble(1, oldDuration);
                    ps.setDouble(2, oldDuration);
                    ps.setInt(3, empId);
                    ps.setInt(4, oldTypeId);
                    ps.executeUpdate();
                }
                String deduct = "UPDATE LEAVE_BALANCES SET PENDING = PENDING + ?, TOTAL = TOTAL - ? WHERE EMPID = ? AND LEAVE_TYPE_ID = ?";
                try (PreparedStatement ps = con.prepareStatement(deduct)) {
                    ps.setDouble(1, req.getDurationDays());
                    ps.setDouble(2, req.getDurationDays());
                    ps.setInt(3, empId);
                    ps.setInt(4, req.getLeaveTypeId());
                    ps.executeUpdate();
                }
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

    public boolean deleteLeave(int leaveId, int empId) throws Exception {
        Connection con = null;
        try {
            con = DatabaseConnection.getConnection();
            con.setAutoCommit(false);

            double duration = 0;
            int typeId = 0;
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
                    } else return false; 
                }
            }

            try (PreparedStatement ps = con.prepareStatement("DELETE FROM LEAVE_REQUESTS WHERE LEAVE_ID = ?")) {
                ps.setInt(1, leaveId);
                ps.executeUpdate();
            }

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

    public List<Map<String, Object>> getLeaveHistory(int empId, String status, String year) throws Exception {
        List<Map<String, Object>> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
            "SELECT lr.LEAVE_ID, lr.START_DATE, lr.END_DATE, lr.DURATION, lr.DURATION_DAYS, " +
            "lr.REASON, lr.MANAGER_COMMENT, lr.APPLIED_ON, lt.TYPE_CODE, ls.STATUS_CODE, att.FILE_NAME, " +
            "lr.LEAVE_TYPE_ID, lr.MEDICAL_FACILITY, lr.REF_SERIAL_NO, lr.EMERGENCY_CATEGORY, lr.EMERGENCY_CONTACT, " +
            "lr.SPOUSE_NAME, lr.EVENT_DATE, lr.DISCHARGE_DATE " +
            "FROM LEAVE_REQUESTS lr " +
            "JOIN LEAVE_TYPES lt ON lr.LEAVE_TYPE_ID = lt.LEAVE_TYPE_ID " +
            "JOIN LEAVE_STATUSES ls ON lr.STATUS_ID = ls.STATUS_ID " +
            "LEFT JOIN LEAVE_REQUEST_ATTACHMENTS att ON lr.LEAVE_ID = att.LEAVE_ID " +
            "WHERE lr.EMPID = ?"
        );

        if (status != null && !status.isEmpty() && !status.equalsIgnoreCase("ALL")) {
            sql.append(" AND ls.STATUS_CODE = ?");
        }
        if (year != null && !year.isEmpty()) {
            sql.append(" AND TO_CHAR(lr.START_DATE, 'YYYY') = ?");
        }
        sql.append(" ORDER BY lr.APPLIED_ON DESC");

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql.toString())) {
            
            int idx = 1;
            ps.setInt(idx++, empId);
            
            if (status != null && !status.isEmpty() && !status.equalsIgnoreCase("ALL")) {
                ps.setString(idx++, status.toUpperCase());
            }
            if (year != null && !year.isEmpty()) {
                ps.setString(idx++, year);
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("id", rs.getInt("LEAVE_ID"));
                    m.put("type", rs.getString("TYPE_CODE"));
                    m.put("start", rs.getDate("START_DATE").toString());
                    m.put("end", rs.getDate("END_DATE").toString());
                    m.put("duration", rs.getString("DURATION"));
                    m.put("totalDays", rs.getDouble("DURATION_DAYS"));
                    m.put("reason", rs.getString("REASON"));
                    m.put("status", rs.getString("STATUS_CODE"));
                    m.put("managerComment", rs.getString("MANAGER_COMMENT"));
                    m.put("appliedOn", rs.getTimestamp("APPLIED_ON").toString());
                    m.put("fileName", rs.getString("FILE_NAME"));
                    m.put("hasFile", rs.getString("FILE_NAME") != null);
                    
                    m.put("leaveTypeId", rs.getString("LEAVE_TYPE_ID"));
                    m.put("medicalFacility", rs.getString("MEDICAL_FACILITY"));
                    m.put("refSerialNo", rs.getString("REF_SERIAL_NO"));
                    m.put("emergencyCategory", rs.getString("EMERGENCY_CATEGORY"));
                    m.put("emergencyContact", rs.getString("EMERGENCY_CONTACT"));
                    m.put("spouseName", rs.getString("SPOUSE_NAME"));
                    
                    Date evt = rs.getDate("EVENT_DATE");
                    m.put("eventDate", evt != null ? evt.toString() : "");
                    
                    Date dis = rs.getDate("DISCHARGE_DATE");
                    m.put("dischargeDate", dis != null ? dis.toString() : "");
                    
                    list.add(m);
                }
            }
        }
        return list;
    }

    public List<LeaveRecord> getAllLeaveRecordsForAdmin(String status, String year, String month) throws Exception {
        List<LeaveRecord> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
            "SELECT lr.*, e.FULLNAME, e.PROFILE_PIC, e.HIRE_DATE, lt.TYPE_CODE, ls.STATUS_CODE, att.FILE_NAME as ATTACHMENT_NAME " +
            "FROM LEAVE_REQUESTS lr " +
            "JOIN EMPLOYEES e ON lr.EMPID = e.EMPID " +
            "JOIN LEAVE_TYPES lt ON lr.LEAVE_TYPE_ID = lt.LEAVE_TYPE_ID " +
            "JOIN LEAVE_STATUSES ls ON lr.STATUS_ID = ls.STATUS_ID " +
            "LEFT JOIN LEAVE_REQUEST_ATTACHMENTS att ON lr.LEAVE_ID = att.LEAVE_ID " +
            "WHERE 1=1 "
        );

        if (status != null && !status.equalsIgnoreCase("ALL")) sql.append(" AND ls.STATUS_CODE = ? ");
        if (year != null && !year.isEmpty()) sql.append(" AND TO_CHAR(lr.START_DATE, 'YYYY') = ? ");
        if (month != null && !month.isEmpty()) sql.append(" AND TO_CHAR(lr.START_DATE, 'MM') = ? ");
        
        sql.append(" ORDER BY lr.APPLIED_ON DESC");

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql.toString())) {
            
            int idx = 1;
            if (status != null && !status.equalsIgnoreCase("ALL")) ps.setString(idx++, status.toUpperCase());
            if (year != null && !year.isEmpty()) ps.setString(idx++, year);
            if (month != null && !month.isEmpty()) ps.setString(idx++, month);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    LeaveRecord r = new LeaveRecord();
                    r.setLeaveId(rs.getInt("LEAVE_ID"));
                    r.setEmpId(rs.getInt("EMPID"));
                    r.setFullName(rs.getString("FULLNAME"));
                    r.setProfilePic(rs.getString("PROFILE_PIC"));
                    r.setHireDate(rs.getDate("HIRE_DATE"));
                    r.setTypeCode(rs.getString("TYPE_CODE"));
                    r.setStatusCode(rs.getString("STATUS_CODE"));
                    r.setDurationDays(rs.getDouble("DURATION_DAYS"));
                    r.setDuration(rs.getString("DURATION"));
                    r.setStartDate(rs.getDate("START_DATE").toString());
                    r.setEndDate(rs.getDate("END_DATE").toString());
                    r.setAppliedOn(rs.getTimestamp("APPLIED_ON").toString());
                    r.setReason(rs.getString("REASON"));
                    r.setManagerComment(rs.getString("MANAGER_COMMENT"));
                    r.setAttachment(rs.getString("ATTACHMENT_NAME"));

                    r.setLeaveTypeId(rs.getString("LEAVE_TYPE_ID"));
                    r.setMedicalFacility(rs.getString("MEDICAL_FACILITY"));
                    r.setRefSerialNo(rs.getString("REF_SERIAL_NO"));
                    r.setEmergencyCategory(rs.getString("EMERGENCY_CATEGORY"));
                    r.setEmergencyContact(rs.getString("EMERGENCY_CONTACT"));
                    r.setSpouseName(rs.getString("SPOUSE_NAME"));
                    
                    Date evt = rs.getDate("EVENT_DATE");
                    r.setEventDate(evt != null ? evt.toString() : "");
                    
                    Date dis = rs.getDate("DISCHARGE_DATE");
                    r.setDischargeDate(dis != null ? dis.toString() : "");
                    
                    list.add(r);
                }
            }
        }
        return list;
    }

    public List<String> getHistoryYears(int empId) throws Exception {
        List<String> years = new ArrayList<>();
        String sql = "SELECT DISTINCT TO_CHAR(START_DATE, 'YYYY') as YR FROM LEAVE_REQUESTS WHERE EMPID = ? ORDER BY YR DESC";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, empId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    years.add(rs.getString("YR"));
                }
            }
        }
        return years;
    }

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

    public Map<Integer, Map<Integer, LeaveBalance>> getLeaveBalanceIndex() throws Exception {
        Map<Integer, Map<Integer, LeaveBalance>> index = new HashMap<>();
        String sql = "SELECT b.EMPID, b.LEAVE_TYPE_ID, t.TYPE_CODE, t.DESCRIPTION, " +
                     "b.ENTITLEMENT, b.CARRIED_FWD, b.USED, b.PENDING, b.TOTAL " +
                     "FROM LEAVE_BALANCES b " +
                     "JOIN LEAVE_TYPES t ON b.LEAVE_TYPE_ID = t.LEAVE_TYPE_ID";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                int empId = rs.getInt("EMPID");
                int typeId = rs.getInt("LEAVE_TYPE_ID");
                LeaveBalance lb = new LeaveBalance();
                lb.setEmpId(empId);
                lb.setLeaveTypeId(typeId);
                lb.setTypeCode(rs.getString("TYPE_CODE"));
                lb.setDescription(rs.getString("DESCRIPTION"));
                lb.setEntitlement(rs.getInt("ENTITLEMENT"));
                lb.setCarriedForward(rs.getInt("CARRIED_FWD"));
                lb.setUsed(rs.getDouble("USED"));
                lb.setPending(rs.getDouble("PENDING"));
                double total = rs.getDouble("TOTAL");
                double avail = total - lb.getUsed() - lb.getPending();
                lb.setTotalAvailable(avail < 0 ? 0 : avail);
                index.computeIfAbsent(empId, k -> new HashMap<>()).put(typeId, lb);
            }
        }
        return index;
    }
}