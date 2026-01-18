package dao;

import bean.Holiday;
import bean.LeaveBalance;
import util.DatabaseConnection;
import util.LeaveBalanceEngine;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Date;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;



public class EmployeeDAO {

    // =====================================
    // 1. Fetch Holidays (PostgreSQL FIX)
    // =====================================
    public List<Holiday> getHolidays(LocalDate start, LocalDate end) throws Exception {
        List<Holiday> list = new ArrayList<>();

        String sql = """
            SELECT holiday_id, holiday_name, holiday_type, holiday_date
            FROM leave.holidays
            WHERE holiday_date >= ? AND holiday_date <= ?
            ORDER BY holiday_date ASC
        """;

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setDate(1, Date.valueOf(start));
            ps.setDate(2, Date.valueOf(end));


            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Holiday h = new Holiday();
                    h.setId(rs.getInt("holiday_id"));
                    h.setName(rs.getString("holiday_name"));
                    h.setType(rs.getString("holiday_type"));
                    h.setDate(rs.getDate("holiday_date").toLocalDate());
                    list.add(h);
                }
            }
        }
        return list;
    }

    // =====================================
    // 2. Fetch Leave Balances
    // =====================================
    public List<LeaveBalance> getLeaveBalances(int empId, int year) throws Exception {
        List<LeaveBalance> balancesList = new ArrayList<>();

        try (Connection con = DatabaseConnection.getConnection()) {

            // A) Get Employee Info
            LocalDate hireDate = null;
            String gender = null;

            String empSql = "SELECT hiredate, gender FROM leave.users WHERE empid = ?";
            try (PreparedStatement ps = con.prepareStatement(empSql)) {
                ps.setInt(1, empId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        hireDate = rs.getDate("hiredate").toLocalDate();
                        gender = rs.getString("gender");
                    }
                }
            }

            if (hireDate == null) {
                hireDate = LocalDate.of(year, 1, 1);
            }

            // B) Fetch Usage
            Map<Integer, Double> usedMap = new HashMap<>();
            Map<Integer, Double> pendingMap = new HashMap<>();

            String aggSql = """
                SELECT lr.leave_type_id,
                       SUM(CASE WHEN UPPER(s.status_code) IN ('APPROVED','CANCELLATION_REQUESTED')
                            THEN COALESCE(NULLIF(lr.duration_days,0),
                            (lr.end_date - lr.start_date + 1)) ELSE 0 END) AS used_days,
                       SUM(CASE WHEN UPPER(s.status_code) = 'PENDING'
                            THEN COALESCE(NULLIF(lr.duration_days,0),
                            (lr.end_date - lr.start_date + 1)) ELSE 0 END) AS pending_days
                FROM leave.leave_requests lr
                JOIN leave.leave_statuses s ON s.status_id = lr.status_id
                WHERE lr.empid = ? AND EXTRACT(YEAR FROM lr.start_date) = ?
                GROUP BY lr.leave_type_id
            """;

            try (PreparedStatement ps = con.prepareStatement(aggSql)) {
                ps.setInt(1, empId);
                ps.setInt(2, year);

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        usedMap.put(rs.getInt("leave_type_id"), rs.getDouble("used_days"));
                        pendingMap.put(rs.getInt("leave_type_id"), rs.getDouble("pending_days"));
                    }
                }
            }

            // C) Process Leave Types
            String typeSql = """
                SELECT leave_type_id, type_code, description
                FROM leave.leave_types
                ORDER BY leave_type_id
            """;

            try (PreparedStatement ps = con.prepareStatement(typeSql);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    String code = rs.getString("type_code");

                    LeaveBalanceEngine.EntitlementResult er =
                            LeaveBalanceEngine.computeEntitlement(code, hireDate, gender);

                    if (er.baseEntitlement == 0 &&
                            (code.contains("MATERNITY") || code.contains("PATERNITY"))) {
                        continue;
                    }

                    LeaveBalance lb = new LeaveBalance();
                    lb.setLeaveTypeId(rs.getInt("leave_type_id"));
                    lb.setTypeCode(code);
                    lb.setDescription(rs.getString("description"));
                    lb.setEntitlement(er.proratedEntitlement);
                    lb.setUsed(usedMap.getOrDefault(lb.getLeaveTypeId(), 0.0));
                    lb.setPending(pendingMap.getOrDefault(lb.getLeaveTypeId(), 0.0));
                    lb.setTotalAvailable(lb.getEntitlement() - lb.getUsed() - lb.getPending());

                    balancesList.add(lb);
                }
            }
        }
        return balancesList;
    }
}


