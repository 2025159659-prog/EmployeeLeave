package dao;

import bean.LeaveRecord;
import util.DatabaseConnection;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.*;

public class AdminLeaveHistoryDAO {

    public List<String> getFilterYears() throws Exception {
        List<String> years = new ArrayList<>();
        String sql = "SELECT DISTINCT EXTRACT(YEAR FROM START_DATE) AS YR FROM LEAVE_REQUESTS ORDER BY YR DESC";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) years.add(rs.getString("YR"));
        }
        return years;
    }

    public List<LeaveRecord> getAdminLeaveHistory(String statusFilter, String yearFilter) throws Exception {
        List<LeaveRecord> history = new ArrayList<>();
        StringBuilder sql = new StringBuilder();
        
        sql.append("SELECT lr.*, u.FULLNAME, u.PROFILE_PICTURE, u.HIREDATE, lt.TYPE_CODE, ls.STATUS_CODE, ")
           .append("(SELECT a.FILE_NAME FROM LEAVE_REQUEST_ATTACHMENTS a WHERE a.LEAVE_ID = lr.LEAVE_ID ORDER BY a.UPLOADED_ON DESC FETCH FIRST 1 ROW ONLY) AS ATTACH_NAME ")
           .append("FROM LEAVE_REQUESTS lr ")
           .append("JOIN USERS u ON lr.EMPID = u.EMPID ")
           .append("JOIN LEAVE_TYPES lt ON lr.LEAVE_TYPE_ID = lt.LEAVE_TYPE_ID ")
           .append("JOIN LEAVE_STATUSES ls ON lr.STATUS_ID = ls.STATUS_ID ")
           .append("WHERE 1=1 ");

        if (statusFilter != null && !statusFilter.isBlank() && !"ALL".equalsIgnoreCase(statusFilter)) {
            sql.append(" AND UPPER(ls.STATUS_CODE) = ? ");
        }
        if (yearFilter != null && !yearFilter.isBlank()) {
            sql.append(" AND EXTRACT(YEAR FROM lr.START_DATE) = ? ");
        }
        sql.append(" ORDER BY lr.APPLIED_ON DESC");

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql.toString())) {
            
            int idx = 1;
            if (statusFilter != null && !statusFilter.isBlank() && !"ALL".equalsIgnoreCase(statusFilter)) {
                ps.setString(idx++, statusFilter.trim().toUpperCase());
            }
            if (yearFilter != null && !yearFilter.isBlank()) {
                ps.setInt(idx++, Integer.parseInt(yearFilter));
            }

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    LeaveRecord lr = new LeaveRecord();
                    lr.setId(rs.getInt("LEAVE_ID"));
                    lr.setEmpId(rs.getInt("EMPID"));
                    lr.setFullName(rs.getString("FULLNAME"));
                    lr.setProfilePic(rs.getString("PROFILE_PICTURE"));
                    lr.setHireDate(rs.getDate("HIREDATE"));
                    lr.setTypeCode(rs.getString("TYPE_CODE"));
                    lr.setStatusCode(rs.getString("STATUS_CODE"));
                    lr.setStartDate(rs.getDate("START_DATE"));
                    lr.setEndDate(rs.getDate("END_DATE"));
                    lr.setAppliedOn(rs.getTimestamp("APPLIED_ON"));
                    lr.setReason(rs.getString("REASON"));
                    lr.setAdminComment(rs.getString("ADMIN_COMMENT"));
                    lr.setFileName(rs.getString("ATTACH_NAME"));
                    lr.setHasFile(lr.getFileName() != null);
                    lr.setDbDuration(rs.getString("DURATION"));
                    lr.setHalfSession(rs.getString("HALF_SESSION"));
                    
                    double days = rs.getDouble("DURATION_DAYS");
                    lr.setTotalDays((!rs.wasNull() && days > 0) ? days : lr.calculateDateDiff());

                    // Mapping Dynamic Attributes (Inheritance)
                    Map<String, String> meta = new HashMap<>();
                    if(rs.getString("MEDICAL_FACILITY") != null) meta.put("Medical Facility", rs.getString("MEDICAL_FACILITY"));
                    if(rs.getString("REF_SERIAL_NO") != null) meta.put("Ref Serial No", rs.getString("REF_SERIAL_NO"));
                    if(rs.getDate("EVENT_DATE") != null) meta.put("Event Date", new SimpleDateFormat("dd/MM/yyyy").format(rs.getDate("EVENT_DATE")));
                    if(rs.getString("EMERGENCY_CATEGORY") != null) meta.put("Emergency Category", rs.getString("EMERGENCY_CATEGORY"));
                    if(rs.getString("EMERGENCY_CONTACT") != null) meta.put("Emergency Phone", rs.getString("EMERGENCY_CONTACT"));
                    if(rs.getString("SPOUSE_NAME") != null) meta.put("Spouse Name", rs.getString("SPOUSE_NAME"));
                    lr.setTypeSpecificData(meta);

                    history.add(lr);
                }
            }
        }
        return history;
    }
}