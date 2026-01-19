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
       FETCH LEAVE TYPES
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
       FETCH SINGLE LEAVE (EDIT)
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

                String type = rs.getString("type_code").toUpperCase();

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

    /* =====================================================
       SUBMIT LEAVE
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
            try (PreparedStatement ps = con.prepareStatement("""
                INSERT INTO leave.leave_requests
                (empid, leave_type_id, status_id,
                 start_date, end_date,
                 duration, duration_days, reason,
                 half_session, applied_on)
                VALUES (?,?,?,?,?,?,?,?,?,
                        CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kuala_Lumpur')
            """, Statement.RETURN_GENERATED_KEYS)) {

                ps.setInt(1, req.getEmpId());
                ps.setInt(2, req.getLeaveTypeId());
                ps.setInt(3, statusId);
                ps.setDate(4, Date.valueOf(req.getStartDate()));
                ps.setDate(5, Date.valueOf(req.getEndDate()));
                ps.setString(6, req.getDuration());
                ps.setDouble(7, req.getDurationDays());
                ps.setString(8, req.getReason());
                ps.setString(9, req.getHalfSession());
                ps.executeUpdate();

                ResultSet rs = ps.getGeneratedKeys();
                rs.next();
                leaveId = rs.getInt(1);
            }

            insertAllMetadata(con, leaveId, req);
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
       INSERT / UPDATE METADATA (ALL TYPES)
       ===================================================== */
    private void insertAllMetadata(Connection con, int leaveId, LeaveRequest req) throws Exception {

        String typeCode;
        try (PreparedStatement ps = con.prepareStatement(
                "SELECT type_code FROM leave.leave_types WHERE leave_type_id=?")) {
            ps.setInt(1, req.getLeaveTypeId());
            ResultSet rs = ps.executeQuery();
            rs.next();
            typeCode = rs.getString(1).toUpperCase();
        }

        if (typeCode.contains("SICK")) {
            upsert(con, """
                INSERT INTO leave.lr_sick
                (leave_id, medical_facility, ref_serial_no)
                VALUES (?,?,?)
                ON CONFLICT (leave_id)
                DO UPDATE SET
                  medical_facility = EXCLUDED.medical_facility,
                  ref_serial_no    = EXCLUDED.ref_serial_no
            """, ps -> {
                ps.setInt(1, leaveId);
                ps.setString(2, req.getMedicalFacility());
                ps.setString(3, req.getRefSerialNo());
            });
        }

        else if (typeCode.contains("EMERGENCY")) {
            upsert(con, """
                INSERT INTO leave.lr_emergency
                (leave_id, emergency_category, emergency_contact)
                VALUES (?,?,?)
                ON CONFLICT (leave_id)
                DO UPDATE SET
                  emergency_category = EXCLUDED.emergency_category,
                  emergency_contact  = EXCLUDED.emergency_contact
            """, ps -> {
                ps.setInt(1, leaveId);
                ps.setString(2, req.getEmergencyCategory());
                ps.setString(3, req.getEmergencyContact());
            });
        }

        else if (typeCode.contains("HOSPITAL")) {
            upsert(con, """
                INSERT INTO leave.lr_hospitalization
                (leave_id, hospital_name, admit_date, discharge_date)
                VALUES (?,?,?,?)
                ON CONFLICT (leave_id)
                DO UPDATE SET
                  hospital_name = EXCLUDED.hospital_name,
                  admit_date    = EXCLUDED.admit_date,
                  discharge_date= EXCLUDED.discharge_date
            """, ps -> {
                ps.setInt(1, leaveId);
                ps.setString(2, req.getMedicalFacility());
                ps.setDate(3, req.getEventDate() != null ? Date.valueOf(req.getEventDate()) : null);
                ps.setDate(4, req.getDischargeDate() != null ? Date.valueOf(req.getDischargeDate()) : null);
            });
        }

        else if (typeCode.contains("PATERNITY")) {
            upsert(con, """
                INSERT INTO leave.lr_paternity
                (leave_id, spouse_name, medical_facility, delivery_date)
                VALUES (?,?,?,?)
                ON CONFLICT (leave_id)
                DO UPDATE SET
                  spouse_name = EXCLUDED.spouse_name,
                  medical_facility = EXCLUDED.medical_facility,
                  delivery_date = EXCLUDED.delivery_date
            """, ps -> {
                ps.setInt(1, leaveId);
                ps.setString(2, req.getSpouseName());
                ps.setString(3, req.getMedicalFacility());
                ps.setDate(4, req.getEventDate() != null ? Date.valueOf(req.getEventDate()) : null);
            });
        }

        else if (typeCode.contains("MATERNITY")) {
            upsert(con, """
                INSERT INTO leave.lr_maternity
                (leave_id, consultation_clinic, expected_due_date, week_pregnancy)
                VALUES (?,?,?,?)
                ON CONFLICT (leave_id)
                DO UPDATE SET
                  consultation_clinic = EXCLUDED.consultation_clinic,
                  expected_due_date = EXCLUDED.expected_due_date,
                  week_pregnancy = EXCLUDED.week_pregnancy
            """, ps -> {
                ps.setInt(1, leaveId);
                ps.setString(2, req.getMedicalFacility());
                ps.setDate(3, req.getEventDate() != null ? Date.valueOf(req.getEventDate()) : null);
                ps.setInt(4, req.getWeekPregnancy());
            });
        }
    }

    @FunctionalInterface
    private interface Filler {
        void fill(PreparedStatement ps) throws SQLException;
    }

    private void upsert(Connection con, String sql, Filler f) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            f.fill(ps);
            ps.executeUpdate();
        }
    }

    /* =====================================================
       BALANCE UPDATE
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
}
