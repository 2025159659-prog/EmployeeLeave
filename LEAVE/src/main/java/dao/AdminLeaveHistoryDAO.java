package dao;

import bean.LeaveRecord;
import util.DatabaseConnection;
import java.sql.*;
import java.sql.Date;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * AdminLeaveHistoryDAO handles database operations for the admin leave history view.
 */
public class AdminLeaveHistoryDAO {

    private final SimpleDateFormat sdfDate = new SimpleDateFormat("dd/MM/yyyy");
    private final SimpleDateFormat sdfTime = new SimpleDateFormat("dd/MM/yyyy HH:mm");

    public List<String> getFilterYears() throws Exception {
        List<String> years = new ArrayList<>();
        String sql = "SELECT DISTINCT EXTRACT(YEAR FROM START_DATE) AS YR FROM LEAVE_REQUESTS ORDER BY YR DESC";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                years.add(rs.getString("YR"));
            }
        }
        return years;
    }

    /**
     * Fetches global leave history. 
     * IMPORTANT: Ensure your LEAVE_REQUESTS table has these columns:
     * MEDICAL_FACILITY, REF_SERIAL_NO, EVENT_DATE, DISCHARGE_DATE, EMERGENCY_CATEGORY, EMERGENCY_CONTACT, SPOUSE_NAME
     */
    public List<LeaveRecord> getAllHistory(String status, String month, String year) throws Exception {
        List<LeaveRecord> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder();
        
        sql.append("SELECT lr.LEAVE_ID, lr.EMPID, lr.START_DATE, lr.END_DATE, lr.DURATION, lr.DURATION_DAYS, ")
           .append("lr.APPLIED_ON, lr.REASON, lr.MANAGER_COMMENT, ")
           // Explicitly selecting metadata columns to ensure they are available in ResultSet
           .append("lr.MEDICAL_FACILITY, lr.REF_SERIAL_NO, lr.EVENT_DATE, lr.DISCHARGE_DATE, ")
           .append("lr.EMERGENCY_CATEGORY, lr.EMERGENCY_CONTACT, lr.SPOUSE_NAME, ")
           .append("u.FULLNAME, u.EMPID as USER_ID, u.HIREDATE, u.PROFILE_PICTURE, ")
           .append("lt.TYPE_CODE, ls.STATUS_CODE, ")
           .append("(SELECT a.FILE_NAME FROM LEAVE_REQUEST_ATTACHMENTS a WHERE a.LEAVE_ID = lr.LEAVE_ID FETCH FIRST 1 ROW ONLY) AS ATTACHMENT_NAME ")
           .append("FROM LEAVE_REQUESTS lr ")
           .append("JOIN USERS u ON lr.EMPID = u.EMPID ")
           .append("JOIN LEAVE_TYPES lt ON lr.LEAVE_TYPE_ID = lt.LEAVE_TYPE_ID ")
           .append("JOIN LEAVE_STATUSES ls ON lr.STATUS_ID = ls.STATUS_ID ")
           .append("WHERE 1=1 ");

        if (status != null && !status.isEmpty() && !"ALL".equalsIgnoreCase(status)) {
            sql.append(" AND UPPER(ls.STATUS_CODE) = ? ");
        }
        if (year != null && !year.isEmpty()) {
            sql.append(" AND EXTRACT(YEAR FROM lr.START_DATE) = ? ");
        }
        if (month != null && !month.isEmpty()) {
            sql.append(" AND EXTRACT(MONTH FROM lr.START_DATE) = ? ");
        }
        
        sql.append(" ORDER BY lr.APPLIED_ON DESC");

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            
            int idx = 1;
            if (status != null && !status.isEmpty() && !"ALL".equalsIgnoreCase(status)) {
                ps.setString(idx++, status.toUpperCase());
            }
            if (year != null && !year.isEmpty()) {
                ps.setInt(idx++, Integer.parseInt(year));
            }
            if (month != null && !month.isEmpty()) {
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

    private LeaveRecord mapResultSetToRecord(ResultSet rs) throws SQLException {
        LeaveRecord r = new LeaveRecord();
        r.setLeaveId(rs.getInt("LEAVE_ID"));
        r.setEmpId(rs.getInt("USER_ID"));
        r.setFullName(rs.getString("FULLNAME"));
        r.setHireDate(rs.getDate("HIREDATE"));
        r.setProfilePic(rs.getString("PROFILE_PICTURE"));
        
        r.setTypeCode(rs.getString("TYPE_CODE"));
        r.setStatusCode(rs.getString("STATUS_CODE"));
        r.setDurationDays(rs.getDouble("DURATION_DAYS"));
        r.setDuration(rs.getString("DURATION"));
        
        if (rs.getDate("START_DATE") != null) r.setStartDate(sdfDate.format(rs.getDate("START_DATE")));
        if (rs.getDate("END_DATE") != null) r.setEndDate(sdfDate.format(rs.getDate("END_DATE")));
        if (rs.getTimestamp("APPLIED_ON") != null) r.setAppliedOn(sdfTime.format(rs.getTimestamp("APPLIED_ON")));
        
        r.setReason(rs.getString("REASON"));
        r.setManagerComment(rs.getString("MANAGER_COMMENT"));
        
        // Populate Metadata for "View Data" Details Popup
        r.setMedicalFacility(rs.getString("MEDICAL_FACILITY"));
        r.setRefSerialNo(rs.getString("REF_SERIAL_NO"));
        
        Date evt = rs.getDate("EVENT_DATE");
        r.setEventDate(evt != null ? sdfDate.format(evt) : "");
        
        Date dis = rs.getDate("DISCHARGE_DATE");
        r.setDischargeDate(dis != null ? sdfDate.format(dis) : "");
        
        r.setEmergencyCategory(rs.getString("EMERGENCY_CATEGORY"));
        r.setEmergencyContact(rs.getString("EMERGENCY_CONTACT"));
        r.setSpouseName(rs.getString("SPOUSE_NAME"));
        
        r.setAttachment(rs.getString("ATTACHMENT_NAME"));
        
        return r;
    }
    


    /**
     * Utility: Calculate working days (excluding weekends and holidays).
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
}