package dao;

import bean.LeaveRecord;
import util.DatabaseConnection;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;

/**
 * ManagerDAO handles fetching pending requests and processing manager actions.
 * Optimized with explicit aliasing and case-insensitive type checking to fix Emergency Leave issues.
 */
public class ManagerDAO {

    private final SimpleDateFormat sdfDate = new SimpleDateFormat("dd/MM/yyyy");
    private final SimpleDateFormat sdfTime = new SimpleDateFormat("dd/MM/yyyy HH:mm");

    public List<LeaveRecord> getRequestsForReview() throws Exception {
        List<LeaveRecord> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder();
        
        sql.append("SELECT lr.*, u.FULLNAME, u.EMPID as USER_ID, u.HIREDATE, u.PROFILE_PICTURE, ")
           .append("lt.TYPE_CODE, ls.STATUS_CODE, ")
           // Added explicit aliases for Emergency columns to ensure data retrieval
           .append("e.EMERGENCY_CATEGORY as EMER_CAT, e.EMERGENCY_CONTACT as EMER_CON, ")
           .append("s.MEDICAL_FACILITY as SICK_FAC, s.REF_SERIAL_NO as SICK_REF, ")
           .append("h.HOSPITAL_NAME as HOSP_NAME, h.ADMIT_DATE as HOSP_ADMIT, h.DISCHARGE_DATE as HOSP_DIS, ")
           .append("m.CONSULTATION_CLINIC as MAT_CLINIC, m.EXPECTED_DUE_DATE as MAT_DUE, m.WEEK_PREGNANCY as MAT_WEEK, ")
           .append("p.SPOUSE_NAME as PAT_SPOUSE, p.MEDICAL_FACILITY as PAT_FAC, p.DELIVERY_DATE as PAT_DEL, ")
           .append("(SELECT a.FILE_NAME FROM LEAVE_REQUEST_ATTACHMENTS a WHERE a.LEAVE_ID = lr.LEAVE_ID FETCH FIRST 1 ROW ONLY) AS ATTACHMENT_NAME ")
           .append("FROM LEAVE_REQUESTS lr ")
           .append("JOIN USERS u ON lr.EMPID = u.EMPID ")
           .append("JOIN LEAVE_TYPES lt ON lr.LEAVE_TYPE_ID = lt.LEAVE_TYPE_ID ")
           .append("JOIN LEAVE_STATUSES ls ON lr.STATUS_ID = ls.STATUS_ID ")
           .append("LEFT JOIN LR_EMERGENCY e ON lr.LEAVE_ID = e.LEAVE_ID ")
           .append("LEFT JOIN LR_SICK s ON lr.LEAVE_ID = s.LEAVE_ID ")
           .append("LEFT JOIN LR_HOSPITALIZATION h ON lr.LEAVE_ID = h.LEAVE_ID ")
           .append("LEFT JOIN LR_MATERNITY m ON lr.LEAVE_ID = m.LEAVE_ID ")
           .append("LEFT JOIN LR_PATERNITY p ON lr.LEAVE_ID = p.LEAVE_ID ")
           .append("WHERE ls.STATUS_CODE IN ('PENDING', 'CANCELLATION_REQUESTED') ")
           .append("ORDER BY lr.APPLIED_ON DESC");

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql.toString());
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapResultSetToRecord(rs));
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
        
        String typeCodeRaw = rs.getString("TYPE_CODE");
        r.setTypeCode(typeCodeRaw);
        r.setStatusCode(rs.getString("STATUS_CODE"));
        r.setDurationDays(rs.getDouble("DURATION_DAYS"));
        r.setDuration(rs.getString("DURATION"));
        r.setLeaveTypeId(rs.getString("LEAVE_TYPE_ID"));
        
        if (rs.getDate("START_DATE") != null) r.setStartDate(sdfDate.format(rs.getDate("START_DATE")));
        if (rs.getDate("END_DATE") != null) r.setEndDate(sdfDate.format(rs.getDate("END_DATE")));
        if (rs.getTimestamp("APPLIED_ON") != null) r.setAppliedOn(sdfTime.format(rs.getTimestamp("APPLIED_ON")));
        
        r.setReason(rs.getString("REASON"));
        r.setManagerComment(rs.getString("MANAGER_COMMENT"));
        r.setAttachment(rs.getString("ATTACHMENT_NAME"));

        // Crucial: Use toUpperCase() and trim() to ensure the comparison works regardless of DB formatting
        String type = (typeCodeRaw != null) ? typeCodeRaw.trim().toUpperCase() : "";
        
        if (type.contains("SICK")) {
            r.setMedicalFacility(rs.getString("SICK_FAC"));
            r.setRefSerialNo(rs.getString("SICK_REF"));
        } else if (type.contains("EMERGENCY")) {
            // Updated to use the new EMER_CAT and EMER_CON aliases
            r.setEmergencyCategory(rs.getString("EMER_CAT"));
            r.setEmergencyContact(rs.getString("EMER_CON"));
        } else if (type.contains("HOSPITAL")) {
            r.setMedicalFacility(rs.getString("HOSP_NAME"));
            if(rs.getDate("HOSP_ADMIT") != null) r.setEventDate(sdfDate.format(rs.getDate("HOSP_ADMIT")));
            if(rs.getDate("HOSP_DIS") != null) r.setDischargeDate(sdfDate.format(rs.getDate("HOSP_DIS")));
        } else if (type.contains("MATERNITY")) {
            r.setMedicalFacility(rs.getString("MAT_CLINIC"));
            if(rs.getDate("MAT_DUE") != null) r.setEventDate(sdfDate.format(rs.getDate("MAT_DUE")));
            r.setWeekPregnancy(rs.getInt("MAT_WEEK"));
        } else if (type.contains("PATERNITY")) {
            r.setSpouseName(rs.getString("PAT_SPOUSE"));
            r.setMedicalFacility(rs.getString("PAT_FAC"));
            if(rs.getDate("PAT_DEL") != null) r.setEventDate(sdfDate.format(rs.getDate("PAT_DEL")));
        }
        
        return r;
    }

    public boolean processAction(int leaveId, String action, String comment) throws Exception {
        try (Connection con = DatabaseConnection.getConnection()) {
            con.setAutoCommit(false);
            try {
                int empId = 0, typeId = 0; 
                double days = 0;
                try (PreparedStatement ps = con.prepareStatement("SELECT EMPID, LEAVE_TYPE_ID, DURATION_DAYS FROM LEAVE_REQUESTS WHERE LEAVE_ID=?")) {
                    ps.setInt(1, leaveId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            empId = rs.getInt(1); 
                            typeId = rs.getInt(2); 
                            days = rs.getDouble(3);
                        } else return false;
                    }
                }

                String finalStatus = "";
                String balSql = "";

                if ("APPROVE".equals(action)) {
                    finalStatus = "APPROVED";
                    balSql = "UPDATE LEAVE_BALANCES SET PENDING = PENDING - ?, USED = USED + ? WHERE EMPID = ? AND LEAVE_TYPE_ID = ?";
                } else if ("REJECT".equals(action)) {
                    finalStatus = "REJECTED";
                    balSql = "UPDATE LEAVE_BALANCES SET PENDING = PENDING - ?, TOTAL = TOTAL + ? WHERE EMPID = ? AND LEAVE_TYPE_ID = ?";
                } else if ("APPROVE_CANCEL".equals(action)) {
                    finalStatus = "CANCELLED";
                    balSql = "UPDATE LEAVE_BALANCES SET USED = USED - ?, TOTAL = TOTAL + ? WHERE EMPID = ? AND LEAVE_TYPE_ID = ?";
                } else if ("REJECT_CANCEL".equals(action)) {
                    finalStatus = "APPROVED"; 
                    balSql = ""; 
                }

                String updSql = "UPDATE LEAVE_REQUESTS SET STATUS_ID = (SELECT STATUS_ID FROM LEAVE_STATUSES WHERE STATUS_CODE=?), MANAGER_COMMENT=? WHERE LEAVE_ID=?";
                try (PreparedStatement ps = con.prepareStatement(updSql)) {
                    ps.setString(1, finalStatus);
                    ps.setString(2, comment);
                    ps.setInt(3, leaveId);
                    ps.executeUpdate();
                }

                if (!balSql.isEmpty()) {
                    try (PreparedStatement ps = con.prepareStatement(balSql)) {
                        ps.setDouble(1, days);
                        ps.setDouble(2, days);
                        ps.setInt(3, empId);
                        ps.setInt(4, typeId);
                        ps.executeUpdate();
                    }
                }

                con.commit();
                return true;
            } catch (Exception e) {
                con.rollback();
                throw e;
            } finally {
                con.setAutoCommit(true);
            }
        }
    }
}