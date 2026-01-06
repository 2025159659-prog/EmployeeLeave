package dao;

import bean.LeaveRecord;
import util.DatabaseConnection;
import java.sql.*;
import java.util.*;

public class LeaveHistoryDAO {
    public List<String> getHistoryYears(int empId) throws Exception {
        List<String> years = new ArrayList<>();
        String sql = "SELECT DISTINCT EXTRACT(YEAR FROM START_DATE) AS YR FROM LEAVE_REQUESTS WHERE EMPID = ? ORDER BY YR DESC";
        try (Connection con = DatabaseConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, empId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) years.add(rs.getString("YR"));
            }
        }
        return years;
    }

    public List<LeaveRecord> getLeaveHistory(int empId, String status, String year) throws Exception {
        List<LeaveRecord> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder("SELECT lr.*, lt.TYPE_CODE, ls.STATUS_CODE, ")
            .append("(SELECT a.FILE_NAME FROM LEAVE_REQUEST_ATTACHMENTS a WHERE a.LEAVE_ID = lr.LEAVE_ID ORDER BY a.UPLOADED_ON DESC FETCH FIRST 1 ROW ONLY) AS ATTACH_NAME ")
            .append("FROM LEAVE_REQUESTS lr JOIN LEAVE_TYPES lt ON lr.LEAVE_TYPE_ID = lt.LEAVE_TYPE_ID ")
            .append("JOIN LEAVE_STATUSES ls ON lr.STATUS_ID = ls.STATUS_ID WHERE lr.EMPID = ? ");

        if (status != null && !status.isBlank() && !"ALL".equalsIgnoreCase(status)) sql.append(" AND UPPER(ls.STATUS_CODE) = ? ");
        if (year != null && !year.isBlank()) sql.append(" AND EXTRACT(YEAR FROM lr.START_DATE) = ? ");
        sql.append(" ORDER BY lr.APPLIED_ON DESC");

        try (Connection con = DatabaseConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql.toString())) {
            int idx = 1; ps.setInt(idx++, empId);
            if (status != null && !status.isBlank() && !"ALL".equalsIgnoreCase(status)) ps.setString(idx++, status.trim().toUpperCase());
            if (year != null && !year.isBlank()) ps.setInt(idx++, Integer.parseInt(year));

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    LeaveRecord lr = new LeaveRecord();
                    lr.setId(rs.getInt("LEAVE_ID"));
                    lr.setTypeCode(rs.getString("TYPE_CODE"));
                    lr.setStatusCode(rs.getString("STATUS_CODE"));
                    lr.setStartDate(rs.getDate("START_DATE"));
                    lr.setEndDate(rs.getDate("END_DATE"));
                    lr.setAppliedOn(rs.getTimestamp("APPLIED_ON"));
                    lr.setReason(rs.getString("REASON"));
                    lr.setAdminComment(rs.getString("ADMIN_COMMENT"));
                    lr.setFileName(rs.getString("ATTACH_NAME"));
                    lr.setHasFile(lr.getFileName() != null);
                    String dur = rs.getString("DURATION");
                    lr.setDbDuration(dur == null ? "FULL_DAY" : dur.trim().toUpperCase());
                    lr.setHalfSession(rs.getString("HALF_SESSION"));
                    double days = rs.getDouble("DURATION_DAYS");
                    lr.setTotalDays((!rs.wasNull() && days > 0) ? days : lr.calculateDateDiff());
                    list.add(lr);
                }
            }
        }
        return list;
    }
}