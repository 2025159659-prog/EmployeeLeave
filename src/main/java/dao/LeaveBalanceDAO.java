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

    public List<LeaveBalance> getEmployeeBalances(int empId) throws SQLException {

        List<LeaveBalance> list = new ArrayList<>();

        String sql = """
            SELECT lb.empid, lb.leave_type_id, lb.entitlement,
                   lb.carried_fwd, lb.used, lb.pending, lb.total,
                   lt.type_code, lt.description
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

