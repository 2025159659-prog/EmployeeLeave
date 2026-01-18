package dao;

import bean.LeaveBalance;
import util.LeaveBalanceEngine;
import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class LeaveBalanceDAO {

    private Connection conn;

    public LeaveBalanceDAO(Connection conn) {
        this.conn = conn;
    }

    /**
     * Initialize leave balances for new employee
     */
    public void initializeNewEmployeeBalances(int empId, LocalDate hireDate, String gender) throws SQLException {

        String g = (gender == null) ? "" : gender.trim().toUpperCase();
        boolean isMale = g.equals("M") || g.equals("MALE");
        boolean isFemale = g.equals("F") || g.equals("FEMALE");

        // ✅ FIXED: schema-qualified
        String typeSql = """
            SELECT LEAVE_TYPE_ID, TYPE_CODE
            FROM leave.leave_types
        """;

        // ✅ FIXED: schema-qualified
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
                int leaveTypeId = rs.getInt("LEAVE_TYPE_ID");
                String typeCode = rs.getString("TYPE_CODE").toUpperCase();

                // Gender filtering
                if (typeCode.contains("MATERNITY") && isMale) continue;
                if (typeCode.contains("PATERNITY") && isFemale) continue;

                LeaveBalanceEngine.EntitlementResult er =
                        LeaveBalanceEngine.computeEntitlement(typeCode, hireDate, g);

                double entitlement = er.proratedEntitlement;
                double carriedFwd = 0.0;
                double used = 0.0;
                double pending = 0.0;
                double total = (entitlement + carriedFwd) - used - pending;

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
     * Fetch balances for dashboard
     */
    public List<LeaveBalance> getEmployeeBalances(int empId) throws SQLException {

        List<LeaveBalance> list = new ArrayList<>();

        // ✅ FIXED: schema-qualified
        String sql = """
            SELECT lb.*, lt.type_code, lt.description
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
                    b.setEmpId(rs.getInt("EMPID"));
                    b.setLeaveTypeId(rs.getInt("LEAVE_TYPE_ID"));
                    b.setTypeCode(rs.getString("TYPE_CODE"));
                    b.setDescription(rs.getString("DESCRIPTION"));
                    b.setEntitlement(rs.getDouble("ENTITLEMENT"));
                    b.setCarriedForward(rs.getDouble("CARRIED_FWD"));
                    b.setUsed(rs.getDouble("USED"));
                    b.setPending(rs.getDouble("PENDING"));
                    b.setTotalAvailable(rs.getDouble("TOTAL"));
                    list.add(b);
                }
            }
        }
        return list;
    }
}
