package dao;

import bean.LeaveRequest;
import util.DatabaseConnection;
import jakarta.servlet.http.Part;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.SQLException;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class LeaveDAO {

    /* =====================================================
       1. FETCH LEAVE TYPES
       ===================================================== */
    public List<Map<String, Object>> getAllLeaveTypes() throws Exception {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT leave_type_id, type_code, description FROM leave.leave_types ORDER BY type_code";

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
       2. FETCH SINGLE LEAVE (EDIT / DETAIL)
       ===================================================== */
    public LeaveRequest getLeaveById(int leaveId, int empId) throws Exception {
        String sql = """
            SELECT lr.*, lt.type_code, ls.status_code,
                   e.emergency_category, e.emergency_contact,
                   s.medical_facility AS sick_fac, s.ref_serial_no AS sick_ref,
                   h.hospital_name AS hosp_name, h.admit_date AS hosp_admit, h.discharge_date AS hosp_dis,
                   p.spouse_name AS pat_spouse, p.medical_facility AS pat_fac, p.delivery_date AS pat_del,
                   m.consultation_clinic AS mat_clinic, m.expected_due_date AS mat_due, m.week_pregnancy AS mat_week
            FROM leave.leave_requests lr
            JOIN leave.leave_types lt ON lr.leave_type_id = lt.leave_type_id
            JOIN leave.leave_statuses ls ON lr.status_id = ls.status_id
            LEFT JOIN leave.lr_emergency e ON lr.leave_id = e.leave_id
            LEFT JOIN leave.lr_sick s ON lr.leave_id = s.leave_id
            LEFT JOIN leave.lr_hospitalization h ON lr.leave_id = h.leave_id
            LEFT JOIN leave.lr_paternity p ON lr.leave_id = p.leave_id
            LEFT JOIN leave.lr_maternity m ON lr.leave_id = m.leave_id
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

                String type = rs.getString("type_code") != null ? rs.getString("type_code").toUpperCase() : "";

                if (type.contains("SICK")) {
                    lr.setMedicalFacility(rs.getString("sick_fac"));
                    lr.setRefSerialNo(rs.getString("sick_ref"));
                } else if (type.contains("EMERGENCY")) {
                    lr.setEmergencyCategory(rs.getString("emergency_category"));
                    lr.setEmergencyContact(rs.getString("emergency_contact"));
                } else if (type.contains("HOSPITAL")) {
                    lr.setMedicalFacility(rs.getString("hosp_name"));
                    if (rs.getDate("hosp_admit") != null) lr.setEventDate(rs.getDate("hosp_admit").toLocalDate());
                    if (rs.getDate("hosp_dis") != null) lr.setDischargeDate(rs.getDate("hosp_dis").toLocalDate());
                } else if (type.contains("PATERNITY")) {
                    lr.setSpouseName(rs.getString("pat_spouse"));
                    lr.setMedicalFacility(rs.getString("pat_fac"));
                    if (rs.getDate("pat_del") != null) lr.setEventDate(rs.getDate("pat_del").toLocalDate());
                } else if (type.contains("MATERNITY")) {
                    lr.setMedicalFacility(rs.getString("mat_clinic"));
                    if (rs.getDate("mat_due") != null) lr.setEventDate(rs.getDate("mat_due").toLocalDate());
                    lr.setWeekPregnancy(rs.getInt("mat_week"));
                }
                return lr;
            }
        }
    }

    /* =====================================================
       3. SUBMIT REQUEST
       ===================================================== */
    public boolean submitRequest(LeaveRequest req, Part filePart) throws Exception {
        Connection con = DatabaseConnection.getConnection();
        try {
            con.setAutoCommit(false);
            int statusId;
            try (PreparedStatement ps = con.prepareStatement("SELECT status_id FROM leave.leave_statuses WHERE status_code='PENDING'")) {
                ResultSet rs = ps.executeQuery();
                rs.next();
                statusId = rs.getInt(1);
            }

            int leaveId;
            String insertSql = """
                INSERT INTO leave.leave_requests (empid, leave_type_id, status_id, start_date, end_date, duration, duration_days, reason, half_session, applied_on)
                VALUES (?,?,?,?,?,?,?,?,?, (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kuala_Lumpur'))
            """;
            try (PreparedStatement ps = con.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {
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
            updateBalance(con, req.getEmpId(), req.getLeaveTypeId(), req.getDurationDays());

            if (filePart != null && filePart.getSize() > 0) {
                String attachSql = "INSERT INTO leave.leave_request_attachments (leave_id, file_data, mime_type, file_name, uploaded_on) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)";
                try (PreparedStatement ps = con.prepareStatement(attachSql)) {
                    ps.setInt(1, leaveId);
                    ps.setBinaryStream(2, filePart.getInputStream(), (int) filePart.getSize());
                    ps.setString(3, filePart.getContentType());
                    ps.setString(4, filePart.getSubmittedFileName());
                    ps.executeUpdate();
                }
            }
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
       4. UPDATE LEAVE (INI YANG TERTINGGAL TADI)
       ===================================================== */
    public boolean updateLeave(LeaveRequest req, int empId) throws Exception {
        Connection con = DatabaseConnection.getConnection();
        try {
            con.setAutoCommit(false);

            // 1. Cek status (Hanya PENDING boleh edit)
            String checkSql = """
                SELECT lr.status_id, lt.type_code 
                FROM leave.leave_requests lr
                JOIN leave.leave_types lt ON lr.leave_type_id = lt.leave_type_id
                WHERE lr.leave_id = ? AND lr.empid = ?
            """;
            
            int statusId;
            String typeCode;
            try (PreparedStatement ps = con.prepareStatement(checkSql)) {
                ps.setInt(1, req.getLeaveId());
                ps.setInt(2, empId);
                ResultSet rs = ps.executeQuery();
                if (!rs.next()) return false;
                statusId = rs.getInt("status_id");
                typeCode = rs.getString("type_code");
            }

            try (PreparedStatement ps = con.prepareStatement("SELECT status_id FROM leave.leave_statuses WHERE status_code = 'PENDING'")) {
                ResultSet rs = ps.executeQuery();
                rs.next();
                if (statusId != rs.getInt(1)) return false; 
            }

            // 2. Update table utama
            String updateMain = """
                UPDATE leave.leave_requests 
                SET start_date = ?, end_date = ?, duration = ?, duration_days = ?, reason = ?, half_session = ?
                WHERE leave_id = ? AND empid = ?
            """;
            try (PreparedStatement ps = con.prepareStatement(updateMain)) {
                ps.setDate(1, java.sql.Date.valueOf(req.getStartDate()));
                ps.setDate(2, java.sql.Date.valueOf(req.getEndDate()));
                ps.setString(3, req.getDuration());
                ps.setDouble(4, req.getDurationDays());
                ps.setString(5, req.getReason());
                ps.setString(6, req.getHalfSession());
                ps.setInt(7, req.getLeaveId());
                ps.setInt(8, empId);
                ps.executeUpdate();
            }

            // 3. Update Metadata (Padam lama, masuk baru)
            deleteOldMetadata(con, req.getLeaveId());
            insertInheritedData(con, req.getLeaveId(), req);

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
       5. LEAVE HISTORY & OTHERS
       ===================================================== */
    public List<Map<String, Object>> getLeaveHistory(int empId, String status, String year) throws Exception {
        List<Map<String, Object>> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder("""
            SELECT lr.leave_id, lt.type_code, ls.status_code, lr.start_date, lr.end_date, lr.duration_days, lr.applied_on, lr.reason, lr.manager_comment,
                   e.emergency_category, e.emergency_contact, s.medical_facility AS sick_fac, s.ref_serial_no AS sick_ref,
                   m.consultation_clinic AS mat_clinic, m.expected_due_date AS mat_due, m.week_pregnancy AS mat_week,
                   p.spouse_name AS pat_spouse, p.medical_facility AS pat_fac, p.delivery_date AS pat_del,
                   h.hospital_name AS hosp_name, h.admit_date AS hosp_admit, h.discharge_date AS hosp_dis,
                   EXISTS (SELECT 1 FROM leave.leave_request_attachments a WHERE a.leave_id = lr.leave_id) AS has_file
            FROM leave.leave_requests lr
            JOIN leave.leave_types lt ON lr.leave_type_id = lt.leave_type_id
            JOIN leave.leave_statuses ls ON lr.status_id = ls.status_id
            LEFT JOIN leave.lr_emergency e ON lr.leave_id = e.leave_id
            LEFT JOIN leave.lr_sick s ON lr.leave_id = s.leave_id
            LEFT JOIN leave.lr_maternity m ON lr.leave_id = m.leave_id
            LEFT JOIN leave.lr_paternity p ON lr.leave_id = p.leave_id
            LEFT JOIN leave.lr_hospitalization h ON lr.leave_id = h.leave_id
            WHERE lr.empid = ?
        """);

        if (status != null && !status.isBlank() && !"ALL".equalsIgnoreCase(status)) {
            sql.append(" AND UPPER(ls.status_code) = ? ");
        }
        if (year != null && !year.isBlank()) {
            sql.append(" AND EXTRACT(YEAR FROM lr.start_date) = ? ");
        }
        sql.append(" ORDER BY lr.applied_on DESC");

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql.toString())) {
            int idx = 1;
            ps.setInt(idx++, empId);
            if (status != null && !status.isBlank() && !"ALL".equalsIgnoreCase(status)) ps.setString(idx++, status.toUpperCase());
            if (year != null && !year.isBlank()) ps.setInt(idx++, Integer.parseInt(year));

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("leaveId", rs.getInt("leave_id"));
                    m.put("type", rs.getString("type_code"));
                    m.put("status", rs.getString("status_code"));
                    m.put("startDate", rs.getDate("start_date"));
                    m.put("endDate", rs.getDate("end_date"));
                    m.put("days", rs.getDouble("duration_days"));
                    m.put("appliedOn", rs.getTimestamp("applied_on"));
                    m.put("reason", rs.getString("reason"));
                    m.put("managerRemark", rs.getString("manager_comment"));
                    m.put("hasFile", rs.getBoolean("has_file"));

                    String type = rs.getString("type_code") != null ? rs.getString("type_code").toUpperCase() : "";
                    if (type.contains("EMERGENCY")) {
                        m.put("emergencyCategory", rs.getString("emergency_category"));
                        m.put("emergencyContact", rs.getString("emergency_contact"));
                    } else if (type.contains("SICK")) {
                        m.put("medicalFacility", rs.getString("sick_fac"));
                        m.put("refSerialNo", rs.getString("sick_ref"));
                    } else if (type.contains("MATERNITY")) {
                        m.put("medicalFacility", rs.getString("mat_clinic"));
                        m.put("eventDate", rs.getDate("mat_due"));
                        m.put("weekPregnancy", rs.getInt("mat_week"));
                    } else if (type.contains("PATERNITY")) {
                        m.put("spouseName", rs.getString("pat_spouse"));
                        m.put("medicalFacility", rs.getString("pat_fac"));
                        m.put("eventDate", rs.getDate("pat_del"));
                    } else if (type.contains("HOSPITAL")) {
                        m.put("medicalFacility", rs.getString("hosp_name"));
                        m.put("eventDate", rs.getDate("hosp_admit"));
                        m.put("dischargeDate", rs.getDate("hosp_dis"));
                    }
                    list.add(m);
                }
            }
        }
        return list;
    }

    public boolean deleteLeave(int leaveId, int empId) throws Exception {
        Connection con = DatabaseConnection.getConnection();
        try {
            con.setAutoCommit(false);
            int leaveTypeId;
            double days;
            String fetchSql = "SELECT leave_type_id, duration_days FROM leave.leave_requests WHERE leave_id = ? AND empid = ? AND status_id = (SELECT status_id FROM leave.leave_statuses WHERE status_code = 'PENDING')";
            try (PreparedStatement ps = con.prepareStatement(fetchSql)) {
                ps.setInt(1, leaveId);
                ps.setInt(2, empId);
                ResultSet rs = ps.executeQuery();
                if (!rs.next()) return false;
                leaveTypeId = rs.getInt("leave_type_id");
                days = rs.getDouble("duration_days");
            }
            deleteOldMetadata(con, leaveId);
            try (PreparedStatement ps = con.prepareStatement("DELETE FROM leave.leave_requests WHERE leave_id = ? AND empid = ?")) {
                ps.setInt(1, leaveId);
                ps.setInt(2, empId);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = con.prepareStatement("UPDATE leave.leave_balances SET pending = pending - ?, total = total + ? WHERE empid = ? AND leave_type_id = ?")) {
                ps.setDouble(1, days);
                ps.setDouble(2, days);
                ps.setInt(3, empId);
                ps.setInt(4, leaveTypeId);
                ps.executeUpdate();
            }
            con.commit();
            return true;
        } catch (Exception e) {
            con.rollback();
            throw e;
        } finally {
            con.close();
        }
    }

    public List<String> getHistoryYears(int empId) throws Exception {
        List<String> years = new ArrayList<>();
        String sql = "SELECT DISTINCT EXTRACT(YEAR FROM start_date) AS yr FROM leave.leave_requests WHERE empid = ? ORDER BY yr DESC";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, empId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    years.add(rs.getString("yr"));
                }
            }
        }
        return years;
    }

    public boolean requestCancellation(int leaveId, int empId) throws Exception {
        String sql = """
            UPDATE leave.leave_requests
            SET status_id = (SELECT status_id FROM leave.leave_statuses WHERE status_code = 'CANCELLATION_REQUESTED')
            WHERE leave_id = ? AND empid = ?
              AND status_id = (SELECT status_id FROM leave.leave_statuses WHERE status_code = 'APPROVED')
        """;
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, leaveId);
            ps.setInt(2, empId);
            return ps.executeUpdate() > 0;
        }
    }

    public double calculateWorkingDays(LocalDate start, LocalDate end) throws Exception {
        Set<LocalDate> holidays = new HashSet<>();
        String sql = "SELECT holiday_date FROM leave.holidays WHERE holiday_date BETWEEN ? AND ?";
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
            if (cur.getDayOfWeek() != DayOfWeek.SATURDAY && cur.getDayOfWeek() != DayOfWeek.SUNDAY && !holidays.contains(cur)) {
                count++;
            }
            cur = cur.plusDays(1);
        }
        return count;
    }

    /* =====================================================
       6. HELPER METHODS (PRIVATE)
       ===================================================== */
    private void updateBalance(Connection con, int empId, int typeId, double days) throws Exception {
        try (PreparedStatement ps = con.prepareStatement("UPDATE leave.leave_balances SET pending = pending + ?, total = total - ? WHERE empid=? AND leave_type_id=?")) {
            ps.setDouble(1, days);
            ps.setDouble(2, days);
            ps.setInt(3, empId);
            ps.setInt(4, typeId);
            ps.executeUpdate();
        }
    }

    private void deleteOldMetadata(Connection con, int leaveId) throws Exception {
        String[] tables = {"leave.lr_emergency", "leave.lr_sick", "leave.lr_hospitalization", "leave.lr_paternity", "leave.lr_maternity"};
        for (String table : tables) {
            try (PreparedStatement ps = con.prepareStatement("DELETE FROM " + table + " WHERE leave_id = ?")) {
                ps.setInt(1, leaveId);
                ps.executeUpdate();
            }
        }
    }

    private void insertInheritedData(Connection con, int leaveId, LeaveRequest req) throws Exception {
        String typeCode = "";
        try (PreparedStatement ps = con.prepareStatement("SELECT type_code FROM leave.leave_types WHERE leave_type_id = ?")) {
            ps.setInt(1, req.getLeaveTypeId());
            ResultSet rs = ps.executeQuery();
            if (rs.next()) typeCode = rs.getString(1);
        }
        if (typeCode == null) return;
        typeCode = typeCode.toUpperCase();

        if (typeCode.contains("EMERGENCY")) {
            try (PreparedStatement ps = con.prepareStatement("INSERT INTO leave.lr_emergency (leave_id, emergency_category, emergency_contact) VALUES (?,?,?)")) {
                ps.setInt(1, leaveId);
                ps.setString(2, req.getEmergencyCategory());
                ps.setString(3, req.getEmergencyContact());
                ps.executeUpdate();
            }
        } else if (typeCode.contains("SICK")) {
            try (PreparedStatement ps = con.prepareStatement("INSERT INTO leave.lr_sick (leave_id, medical_facility, ref_serial_no) VALUES (?,?,?)")) {
                ps.setInt(1, leaveId);
                ps.setString(2, req.getMedicalFacility());
                ps.setString(3, req.getRefSerialNo());
                ps.executeUpdate();
            }
        } else if (typeCode.contains("HOSPITAL")) {
            try (PreparedStatement ps = con.prepareStatement("INSERT INTO leave.lr_hospitalization (leave_id, hospital_name, admit_date, discharge_date) VALUES (?,?,?,?)")) {
                ps.setInt(1, leaveId);
                ps.setString(2, req.getMedicalFacility());
                ps.setDate(3, req.getEventDate() != null ? java.sql.Date.valueOf(req.getEventDate()) : null);
                ps.setDate(4, req.getDischargeDate() != null ? java.sql.Date.valueOf(req.getDischargeDate()) : null);
                ps.executeUpdate();
            }
        } else if (typeCode.contains("PATERNITY")) {
            try (PreparedStatement ps = con.prepareStatement("INSERT INTO leave.lr_paternity (leave_id, spouse_name, medical_facility, delivery_date) VALUES (?,?,?,?)")) {
                ps.setInt(1, leaveId);
                ps.setString(2, req.getSpouseName());
                ps.setString(3, req.getMedicalFacility());
                ps.setDate(4, req.getEventDate() != null ? java.sql.Date.valueOf(req.getEventDate()) : null);
                ps.executeUpdate();
            }
        } else if (typeCode.contains("MATERNITY")) {
            try (PreparedStatement ps = con.prepareStatement("INSERT INTO leave.lr_maternity (leave_id, consultation_clinic, expected_due_date, week_pregnancy) VALUES (?,?,?,?)")) {
                ps.setInt(1, leaveId);
                ps.setString(2, req.getMedicalFacility());
                ps.setDate(3, req.getEventDate() != null ? java.sql.Date.valueOf(req.getEventDate()) : null);
                ps.setInt(4, req.getWeekPregnancy());
                ps.executeUpdate();
            }
        }
    }
}
