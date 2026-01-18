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

    /**
     * Initialize leave balances for a new employee
     */
    public void initializeNewEmployeeBalances(int empId, LocalDate hireDate, String gender) throws SQLException {

        String g = (gender == null) ? "" : gender.trim().toUpperCase();
        boolean isMale = g.equals("M") || g.equals("MALE");
        boolean isFemale = g.equals("F") || g.equals("FEMALE");

        // ✅ PostgreSQL: schema-qualified
        String typeSql = """
            SELECT leave_type_id, type_code
            FROM leave.leave_types
            ORDER BY leave_type_id
        """;

        // ✅ PostgreSQL: schema-qualified
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

                // 🚫 Gender filtering
                if (typeCode.contains("MATERNITY") && isMale) continue;
                if (typeCode.contains("PATERNITY") && isFemale) continue;

                LeaveBalanceEngine.EntitlementResult er =
                        LeaveBalanceEngine.computeEntitlement(typeCode, hireDate, g);

                double entitlement = er.proratedEntitlement;
                double carriedFwd = 0.0;
                double used = 0.0;
                double pending = 0.0;
                double total = entitlement - used - pending;

                insertStmt.setInt(1, empId);
                insertStmt.setInt(2, leaveTypeId);
                insertStmt.setDouble(3, entitlement);
                insertStmt.setDouble(4, carriedFwd);
                insertStmt.setDouble(5, used);
                insertStmt.setDouble(6, pending);
                insertStmt.setDouble(7, total);

                insertStmt.addBatch();
            }

            insertStmt.executeBatch();
        }
    }

    /**
     * Fetch leave balances for dashboard / admin matrix
     */
    public List<LeaveBalance> getEmployeeBalances(int empId) throws SQLException {

        List<LeaveBalance> list = new ArrayList<>();

        // ✅ PostgreSQL: schema-qualified
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
                    b.setEntitlement(rs.getDouble("entitlement"));
                    b.setCarriedForward(rs.getDouble("carried_fwd"));
                    b.setUsed(rs.getDouble("used"));
                    b.setPending(rs.getDouble("pending"));
                    b.setTotalAvailable(rs.getDouble("total"));
                    list.add(b);
                }
            }
        }
        return list;
    }
}
