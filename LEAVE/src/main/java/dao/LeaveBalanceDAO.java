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
    public void initializeNewEmployeeBalances(int empId, LocalDate hireDate, String gender)
            throws SQLException {

        String g = (gender == null) ? "" : gender.trim().toUpperCase();
        boolean isMale = g.equals("M") || g.equals("MALE");
        boolean isFemale = g.equals("F") || g.equals("FEMALE");

        String typeSql = "SELECT LEAVE_TYPE_ID, TYPE_CODE FROM LEAVE_TYPES";
        String insertSql =
            "INSERT INTO LEAVE_BALANCES " +
            "(EMPID, LEAVE_TYPE_ID, ENTITLEMENT, CARRIED_FWD, USED, PENDING, TOTAL) " +
            "VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (
            PreparedStatement typeStmt = conn.prepareStatement(typeSql);
            ResultSet rs = typeStmt.executeQuery();
            PreparedStatement insertStmt = conn.prepareStatement(insertSql)
        ) {

            while (rs.next()) {
                int leaveTypeId = rs.getInt("LEAVE_TYPE_ID");
                String typeCode = rs.getString("TYPE_CODE").toUpperCase();

                if (typeCode.contains("MATERNITY") && isMale) continue;
                if (typeCode.contains("PATERNITY") && isFemale) continue;

                LeaveBalanceEngine.EntitlementResult er =
                    LeaveBalanceEngine.computeEntitlement(typeCode, hireDate, g);

                int entitlement = (int) er.proratedEntitlement;
                int carriedFwd = 0;
                int used = 0;
                int pending = 0;
                int total = entitlement;

                insertStmt.setInt(1, empId);
                insertStmt.setInt(2, leaveTypeId);
                insertStmt.setInt(3, entitlement);
                insertStmt.setInt(4, carriedFwd);
                insertStmt.setInt(5, used);
                insertStmt.setInt(6, pending);
                insertStmt.setInt(7, total);

                insertStmt.addBatch();
            }

            insertStmt.executeBatch();
        }
    }

    /**
     * Get leave balances for employee dashboard
     */
    public List<LeaveBalance> getEmployeeBalances(int empId) throws SQLException {

        List<LeaveBalance> list = new ArrayList<>();

        String sql =
            "SELECT lb.LEAVE_TYPE_ID, lb.ENTITLEMENT, lb.CARRIED_FWD, lb.USED, lb.PENDING, lb.TOTAL, " +
            "lt.TYPE_CODE, lt.DESCRIPTION " +
            "FROM LEAVE_BALANCES lb " +
            "JOIN LEAVE_TYPES lt ON lb.LEAVE_TYPE_ID = lt.LEAVE_TYPE_ID " +
            "WHERE lb.EMPID = ? " +
            "ORDER BY lt.LEAVE_TYPE_ID";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, empId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {

                    LeaveBalance b = new LeaveBalance();
                    b.setLeaveTypeId(rs.getInt("LEAVE_TYPE_ID"));
                    b.setTypeCode(rs.getString("TYPE_CODE"));
                    b.setDescription(rs.getString("DESCRIPTION"));
                    b.setEntitlement(rs.getInt("ENTITLEMENT"));
                    b.setCarriedForward(rs.getInt("CARRIED_FWD"));
                    b.setUsed(rs.getInt("USED"));
                    b.setPending(rs.getInt("PENDING"));
                    b.setTotalAvailable(rs.getInt("TOTAL"));

                    list.add(b);
                }
            }
        }
        return list;
    }
}
