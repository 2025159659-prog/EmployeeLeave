package dao;

import bean.LeaveRecord;
import util.DatabaseConnection;

import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;

public class ManagerDAO {

    private final SimpleDateFormat sdfDate = new SimpleDateFormat("dd/MM/yyyy");
    private final SimpleDateFormat sdfTime = new SimpleDateFormat("dd/MM/yyyy HH:mm");

    /* =========================================================
       GET ALL LEAVE REQUESTS FOR MANAGER REVIEW
       ========================================================= */
    public List<LeaveRecord> getRequestsForReview() throws Exception {

        List<LeaveRecord> list = new ArrayList<>();

        String sql = """
                        SELECT
                lr.leave_id,
                lr.empid,
                lr.leave_type_id       AS leave_type_id,   -- ✅ ADD EXPLICIT
                lr.start_date,
                lr.end_date,
                lr.duration,
                lr.duration_days,
                lr.applied_on,
                lr.reason,
                lr.manager_comment,
            
                u.empid            AS user_id,
                u.fullname,
                u.hiredate,
                u.profile_picture,
            
                lt.type_code,
                ls.status_code,
            
                e.emergency_category   AS emer_cat,
                e.emergency_contact    AS emer_con,
                s.medical_facility     AS sick_fac,
                s.ref_serial_no        AS sick_ref,
                h.hospital_name        AS hosp_name,
                h.admit_date           AS hosp_admit,
                h.discharge_date       AS hosp_dis,
                m.consultation_clinic  AS mat_clinic,
                m.expected_due_date    AS mat_due,
                m.week_pregnancy       AS mat_week,
                p.spouse_name          AS pat_spouse,
                p.medical_facility     AS pat_fac,
                p.delivery_date        AS pat_del
            FROM leave.leave_requests lr
            

            JOIN leave.users u               ON lr.empid = u.empid
            JOIN leave.leave_types lt        ON lr.leave_type_id = lt.leave_type_id
            JOIN leave.leave_statuses ls     ON lr.status_id = ls.status_id
            LEFT JOIN leave.lr_emergency e        ON lr.leave_id = e.leave_id
            LEFT JOIN leave.lr_sick s             ON lr.leave_id = s.leave_id
            LEFT JOIN leave.lr_hospitalization h  ON lr.leave_id = h.leave_id
            LEFT JOIN leave.lr_maternity m        ON lr.leave_id = m.leave_id
            LEFT JOIN leave.lr_paternity p        ON lr.leave_id = p.leave_id
            WHERE ls.status_code IN ('PENDING', 'CANCELLATION_REQUESTED')
            ORDER BY lr.applied_on DESC
        """;

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                list.add(mapResultSet(rs));
            }
        }
        return list;
    }

    /* =========================================================
       MAP RESULTSET → LEAVERECORD
       ========================================================= */
    private LeaveRecord mapResultSet(ResultSet rs) throws SQLException {

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

        String type = rs.getString("type_code");
        if (type == null) type = "";
        type = type.toUpperCase();

        if (type.contains("SICK")) {
            r.setMedicalFacility(rs.getString("sick_fac"));
            r.setRefSerialNo(rs.getString("sick_ref"));
        } else if (type.contains("EMERGENCY")) {
            r.setEmergencyCategory(rs.getString("emer_cat"));
            r.setEmergencyContact(rs.getString("emer_con"));
        } else if (type.contains("HOSPITAL")) {
            r.setMedicalFacility(rs.getString("hosp_name"));
            if (rs.getDate("hosp_admit") != null)
                r.setEventDate(sdfDate.format(rs.getDate("hosp_admit")));
            if (rs.getDate("hosp_dis") != null)
                r.setDischargeDate(sdfDate.format(rs.getDate("hosp_dis")));
        } else if (type.contains("MATERNITY")) {
            r.setMedicalFacility(rs.getString("mat_clinic"));
            if (rs.getDate("mat_due") != null)
                r.setEventDate(sdfDate.format(rs.getDate("mat_due")));
            r.setWeekPregnancy(rs.getInt("mat_week"));
        } else if (type.contains("PATERNITY")) {
            r.setSpouseName(rs.getString("pat_spouse"));
            r.setMedicalFacility(rs.getString("pat_fac"));
            if (rs.getDate("pat_del") != null)
                r.setEventDate(sdfDate.format(rs.getDate("pat_del")));
        }

        return r;
    }

    /* =========================================================
       PROCESS MANAGER ACTION (FIXED FLOW)
       ========================================================= */
    public boolean processAction(int leaveId, String action, String comment) throws Exception {

        try (Connection con = DatabaseConnection.getConnection()) {

            con.setAutoCommit(false);

            try {
                int empId;
                int leaveTypeId;
                double days;
                String currentStatus;
                String typeCode;

                /* 🔹 FETCH CURRENT STATE */
                String fetchSql = """
                    SELECT lr.empid, lr.leave_type_id, lr.duration_days,
                           ls.status_code, lt.type_code
                    FROM leave.leave_requests lr
                    JOIN leave.leave_statuses ls ON lr.status_id = ls.status_id
                    JOIN leave.leave_types lt ON lr.leave_type_id = lt.leave_type_id
                    WHERE lr.leave_id = ?
                """;

                try (PreparedStatement ps = con.prepareStatement(fetchSql)) {
                    ps.setInt(1, leaveId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) return false;

                        empId = rs.getInt("empid");
                        leaveTypeId = rs.getInt("leave_type_id");
                        days = rs.getDouble("duration_days");
                        currentStatus = rs.getString("status_code");
                        typeCode = rs.getString("type_code");
                    }
                }

                boolean isUnpaid = typeCode != null && typeCode.toUpperCase().contains("UNPAID");

                String finalStatus;
                String balanceSql = null;

                /* 🔹 VALIDATE FLOW */
                switch (action) {

                    case "APPROVE" -> {
                        if (!"PENDING".equals(currentStatus)) return false;
                        finalStatus = "APPROVED";
                        if (!isUnpaid) {
                            balanceSql = """
                                UPDATE leave.leave_balances
                                SET pending = pending - ?, used = used + ?
                                WHERE empid = ? AND leave_type_id = ?
                            """;
                        }
                    }

                    case "REJECT" -> {
                        if (!"PENDING".equals(currentStatus)) return false;
                        finalStatus = "REJECTED";
                        if (!isUnpaid) {
                            balanceSql = """
                                UPDATE leave.leave_balances
                                SET pending = pending - ?, total = total + ?
                                WHERE empid = ? AND leave_type_id = ?
                            """;
                        }
                    }

                    case "APPROVE_CANCEL" -> {
                        if (!"CANCELLATION_REQUESTED".equals(currentStatus)) return false;
                        finalStatus = "CANCELLED";
                        if (!isUnpaid) {
                            balanceSql = """
                                UPDATE leave.leave_balances
                                SET used = used - ?, total = total + ?
                                WHERE empid = ? AND leave_type_id = ?
                            """;
                        }
                    }

                    case "REJECT_CANCEL" -> {
                        if (!"CANCELLATION_REQUESTED".equals(currentStatus)) return false;
                        finalStatus = "APPROVED";
                    }

                    default -> throw new IllegalArgumentException("Invalid action: " + action);
                }

                /* 🔹 UPDATE LEAVE STATUS */
                try (PreparedStatement ps = con.prepareStatement("""
                    UPDATE leave.leave_requests
                    SET status_id = (
                        SELECT status_id FROM leave.leave_statuses WHERE status_code = ?
                    ),
                    manager_comment = ?
                    WHERE leave_id = ?
                """)) {
                    ps.setString(1, finalStatus);
                    ps.setString(2, comment);
                    ps.setInt(3, leaveId);
                    ps.executeUpdate();
                }

                /* 🔹 UPDATE BALANCE IF NEEDED */
                if (balanceSql != null) {
                    try (PreparedStatement ps = con.prepareStatement(balanceSql)) {
                        ps.setDouble(1, days);
                        ps.setDouble(2, days);
                        ps.setInt(3, empId);
                        ps.setInt(4, leaveTypeId);
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
