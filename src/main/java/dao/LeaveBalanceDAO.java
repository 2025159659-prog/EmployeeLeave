package dao;

import bean.LeaveBalance;
import util.LeaveBalanceEngine;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class LeaveBalanceDAO {

    private final Connection conn;

    public LeaveBalanceDAO(Connection conn) {
        this.conn = conn;
    }

    /* =====================================================
       INITIALIZE LEAVE BALANCES FOR NEW EMPLOYEE
       ===================================================== */
    public void initializeNewEmployeeBalances(
            int empId,
            LocalDate hireDate,
            String gender
    ) throws SQLException {

        String g = (gender == null) ? "" : gender.trim().toUpperCase();
        boolean isMale   = g.equals("M") || g.equals("MALE");
        boolean isFemale = g.equals("F") || g.equals("FEMALE");

        String typeSql = """
            SELECT leave_type_id, type_code
            FROM leave.leave_types
            ORDER BY leave_type_id
        """;

        String insertSql = """
            INSERT INTO leave.leave_balances
            (empid, leave_type_id, entitlement, carried_fwd, used, pending, total)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """;

        try (
            PreparedStatement typeStmt = conn.prepareStatement(typeSql);
            ResultSet rs = typeStmt.executeQuery();
            PreparedStatement insertStmt = conn.prepareStatement(insertSql)
        ) {
            while (rs.next()) {

                int leaveTypeId = rs.getInt("leave_type_id");
                String typeCode = rs.getString("type_code").toUpperCase();

                // ===== GENDER FILTER =====
                if (typeCode.contains("MATERNITY") && isMale) continue;
                if (typeCode.contains("PATERNITY") && isFemale) continue;

                LeaveBalanceEngine.EntitlementResult er =
                        LeaveBalanceEngine.computeEntitlement(
                                typeCode,
                                hireDate,
                                g
                        );

                // ⭐ PERBAIKAN: Gunakan 'double' untuk menyokong 0.5 hari dan buang pengisytiharan bertindan ⭐
                double entitlement = er.proratedEntitlement;
                double carriedFwd = 0.0;
                double used = 0.0;
                double pending = 0.0;
                
                // Kira baki keseluruhan menggunakan double
                double total = (entitlement + carriedFwd) - used - pending;

                insertStmt.setInt(1, empId);
                insertStmt.setInt(2, leaveTypeId);
                insertStmt.setDouble(3, entitlement); // Benarkan perpuluhan
                insertStmt.setDouble(4, carriedFwd);
                insertStmt.setDouble(5, used);
                insertStmt.setDouble(6, pending);
                insertStmt.setDouble(7, total);

                insertStmt.addBatch();
            }
            insertStmt.executeBatch();
        }
    }

    /* =====================================================
       GET EMPLOYEE LEAVE BALANCES (MENYOKONG 0.5 HARI)
       ===================================================== */
    public List<LeaveBalance> getEmployeeBalances(int empId)
            throws SQLException {

        List<LeaveBalance> list = new ArrayList<>();

        String sql = """
            SELECT lb.empid,
                   lb.leave_type_id,
                   lb.entitlement,
                   lb.carried_fwd,
                   lb.used,
                   lb.pending,
                   lb.total,
                   lt.type_code,
                   lt.description
            FROM leave.leave_balances lb
            JOIN leave.leave_types lt
              ON lb.leave_type_id = lt.leave_type_id
            WHERE lb.empid = ?
            ORDER BY lt.leave_type_id
        """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, empId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {

                    LeaveBalance b = new LeaveBalance();
                    b.setEmpId(rs.getInt("empid"));
                    b.setLeaveTypeId(rs.getInt("leave_type_id"));
                    b.setTypeCode(rs.getString("type_code"));
                    b.setDescription(rs.getString("description"));

                    String typeCode = rs.getString("type_code").toUpperCase();

                    /* ===============================
                       PENGENDALIAN KHAS UNTUK UNPAID
                       =============================== */
                    if (typeCode.equals("UNPAID")) {

                        double p = sumUnpaidDays(empId, "PENDING");
                        double u = sumUnpaidDays(empId, "APPROVED");

                        b.setEntitlement(3.0); 
                        b.setCarriedForward(0.0);
                        b.setPending(p);
                        b.setUsed(u);
                        b.setTotalAvailable(3.0 - p - u);

                    } else {
                        // ⭐ Gunakan getDouble() untuk membaca nilai 0.5 ⭐
                        b.setEntitlement(rs.getDouble("entitlement"));
                        b.setCarriedForward(rs.getDouble("carried_fwd"));
                        b.setUsed(rs.getDouble("used"));
                        b.setPending(rs.getDouble("pending"));
                        b.setTotalAvailable(rs.getDouble("total"));
                    }

                    list.add(b);
                }
            }
        }
        return list;
    }

    /* =====================================================
       HELPER: KIRA JUMLAH HARI UNPAID (DOUBLE)
       ===================================================== */
    private double sumUnpaidDays(int empId, String statusCode)
            throws SQLException {

        String sql = """
            SELECT COALESCE(SUM(lr.duration_days), 0.0)
            FROM leave.leave_requests lr
            JOIN leave.leave_types lt
              ON lr.leave_type_id = lt.leave_type_id
            JOIN leave.leave_statuses ls
              ON lr.status_id = ls.status_id
            WHERE lr.empid = ?
              AND UPPER(lt.type_code) = 'UNPAID'
              AND ls.status_code = ?
        """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, empId);
            ps.setString(2, statusCode);

            try (ResultSet rs = ps.executeQuery()) {
                // Pastikan nilai dikembalikan sebagai double
                return rs.next() ? rs.getDouble(1) : 0.0;
            }
        }
    }
}
