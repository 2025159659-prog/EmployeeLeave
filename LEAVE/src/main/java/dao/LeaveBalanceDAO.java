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
     * Initializes specific leave types for a new employee based on Gender.
     * Male employees will NOT receive Maternity records.
     * Female employees will NOT receive Paternity records.
     * Total records created: Exactly 6.
     */
    public void initializeNewEmployeeBalances(int empId, LocalDate hireDate, String gender) throws SQLException {
        // Normalize gender input
        String g = (gender == null) ? "" : gender.trim().toUpperCase();
        boolean isMale = g.equals("M") || g.equals("MALE");
        boolean isFemale = g.equals("F") || g.equals("FEMALE");

        // 1. Get all available leave types from the lookup table
        String typeSql = "SELECT LEAVE_TYPE_ID, TYPE_CODE FROM LEAVE_TYPES";
        
        // 2. Prepared statement matching Oracle Schema
        String insertSql = "INSERT INTO LEAVE_BALANCES (EMPID, LEAVE_TYPE_ID, ENTITLEMENT, CARRIED_FWD, USED, PENDING, TOTAL) " +
                          "VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement typeStmt = conn.prepareStatement(typeSql);
             ResultSet rs = typeStmt.executeQuery();
             PreparedStatement insertStmt = conn.prepareStatement(insertSql)) {

            while (rs.next()) {
                int leaveTypeId = rs.getInt("LEAVE_TYPE_ID");
                String typeCode = rs.getString("TYPE_CODE").toUpperCase();

                // =========================================================
                // STRICT GENDER FILTERING LOGIC
                // =========================================================
                
                // If the leave type is Maternity but the employee is Male -> SKIP
                if (typeCode.contains("MATERNITY") && isMale) {
                    continue; 
                }
                
                // If the leave type is Paternity but the employee is Female -> SKIP
                if (typeCode.contains("PATERNITY") && isFemale) {
                    continue;
                }
                
                // =========================================================

                // Calculate prorated entitlement using the Statutory Engine (EA 1955)
                LeaveBalanceEngine.EntitlementResult result = LeaveBalanceEngine.computeEntitlement(typeCode, hireDate, g);

                double entitlement = result.proratedEntitlement;
                double carriedFwd = 0.0;
                double used = 0.0;
                double pending = 0.0;
                // Total Available Calculation
                double total = (entitlement + carriedFwd) - used - pending;

                // Bind parameters for Oracle
                insertStmt.setInt(1, empId);
                insertStmt.setInt(2, leaveTypeId);
                insertStmt.setDouble(3, entitlement);
                insertStmt.setDouble(4, carriedFwd);
                insertStmt.setDouble(5, used);
                insertStmt.setDouble(6, pending);
                insertStmt.setDouble(7, total);
                
                insertStmt.addBatch();
            }
            
            // Execute the filtered batch (6 rows)
            insertStmt.executeBatch();
        }
    }

    /**
     * Retrieves current balances for an employee.
     * Dashboard uses this to render leave cards.
     */
    public List<LeaveBalance> getEmployeeBalances(int empId) throws SQLException {
        List<LeaveBalance> list = new ArrayList<>();
        String sql = "SELECT lb.*, lt.TYPE_CODE, lt.DESCRIPTION " +
                     "FROM LEAVE_BALANCES lb " +
                     "JOIN LEAVE_TYPES lt ON lb.LEAVE_TYPE_ID = lt.LEAVE_TYPE_ID " +
                     "WHERE lb.EMPID = ? " +
                     "ORDER BY lt.LEAVE_TYPE_ID ASC";
        
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, empId);
            try (ResultSet rs = pstmt.executeQuery()) {
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