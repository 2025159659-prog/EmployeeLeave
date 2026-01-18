package dao;

import bean.Holiday;
import bean.LeaveBalance;
import util.DatabaseConnection;
import util.LeaveBalanceEngine;

import java.sql.*;
import java.time.LocalDate;
import java.util.*;

public class EmployeeDAO {

	// 1. Fetch Holidays
		public List<Holiday> getHolidays(LocalDate start, LocalDate end) throws Exception {
		    List<Holiday> list = new ArrayList<>();
		    String sql = "SELECT HOLIDAY_ID, HOLIDAY_NAME, HOLIDAY_TYPE, HOLIDAY_DATE "
		            + "FROM HOLIDAYS "
		            + "WHERE TRUNC(HOLIDAY_DATE) >= ? AND TRUNC(HOLIDAY_DATE) <= ? "
		            + "ORDER BY HOLIDAY_DATE ASC";
		
		    try (Connection con = DatabaseConnection.getConnection();
		         PreparedStatement ps = con.prepareStatement(sql)) {
		
		        ps.setDate(1, java.sql.Date.valueOf(start));
		        ps.setDate(2, java.sql.Date.valueOf(end));
		
		        try (ResultSet rs = ps.executeQuery()) {
		            while (rs.next()) {
		                Holiday h = new Holiday();
		                h.setId(rs.getInt("HOLIDAY_ID"));
		                h.setName(rs.getString("HOLIDAY_NAME"));
		                h.setType(rs.getString("HOLIDAY_TYPE"));
		                h.setDate(rs.getDate("HOLIDAY_DATE").toLocalDate());
		                list.add(h);
		            }
		        }
		    }
		    return list;
		}

	// 2. Fetch Leave Balances
	public List<LeaveBalance> getLeaveBalances(int empId, int year) throws Exception {
		List<LeaveBalance> balancesList = new ArrayList<>();

		try (Connection con = DatabaseConnection.getConnection()) {
			// A) Get Employee Info
			LocalDate hireDate = null;
			String gender = null;
			String empSql = "SELECT HIREDATE, GENDER FROM USERS WHERE EMPID = ?";
			try (PreparedStatement ps = con.prepareStatement(empSql)) {
				ps.setInt(1, empId);
				try (ResultSet rs = ps.executeQuery()) {
					if (rs.next()) {
						if (rs.getDate("HIREDATE") != null)
							hireDate = rs.getDate("HIREDATE").toLocalDate();
						gender = rs.getString("GENDER");
					}
				}
			}
			if (hireDate == null)
				hireDate = LocalDate.of(year, 1, 1);

			// B) Fetch Usage
			Map<Integer, Double> usedMap = new HashMap<>();
			Map<Integer, Double> pendingMap = new HashMap<>();
			String aggSql = "SELECT lr.LEAVE_TYPE_ID, "
					+ "SUM(CASE WHEN TRIM(UPPER(s.STATUS_CODE)) IN ('APPROVED', 'CANCELLATION_REQUESTED') THEN "
					+ "COALESCE(NULLIF(lr.DURATION_DAYS, 0), (lr.END_DATE - lr.START_DATE + 1)) ELSE 0 END) AS USED_DAYS, "
					+ "SUM(CASE WHEN TRIM(UPPER(s.STATUS_CODE)) = 'PENDING' THEN "
					+ "COALESCE(NULLIF(lr.DURATION_DAYS, 0), (lr.END_DATE - lr.START_DATE + 1)) ELSE 0 END) AS PENDING_DAYS "
					+ "FROM LEAVE_REQUESTS lr JOIN LEAVE_STATUSES s ON s.STATUS_ID = lr.STATUS_ID "
					+ "WHERE lr.EMPID = ? AND EXTRACT(YEAR FROM lr.START_DATE) = ? GROUP BY lr.LEAVE_TYPE_ID";

			try (PreparedStatement ps = con.prepareStatement(aggSql)) {
				ps.setInt(1, empId);
				ps.setInt(2, year);
				try (ResultSet rs = ps.executeQuery()) {
					while (rs.next()) {
						usedMap.put(rs.getInt("LEAVE_TYPE_ID"), rs.getDouble("USED_DAYS"));
						pendingMap.put(rs.getInt("LEAVE_TYPE_ID"), rs.getDouble("PENDING_DAYS"));
					}
				}
			}

			// C) Process Leave Types
			String typeSql = "SELECT LEAVE_TYPE_ID, TYPE_CODE, DESCRIPTION FROM LEAVE_TYPES ORDER BY LEAVE_TYPE_ID ASC";
			try (PreparedStatement ps = con.prepareStatement(typeSql); ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					String code = rs.getString("TYPE_CODE");

					// Calculation logic
					LeaveBalanceEngine.EntitlementResult er = LeaveBalanceEngine.computeEntitlement(code, hireDate,
							gender);

					// Filter by eligibility
					if (er.baseEntitlement == 0 && (code.contains("MATERNITY") || code.contains("PATERNITY"))) {
						continue;
					}

					LeaveBalance lb = new LeaveBalance();
					lb.setLeaveTypeId(rs.getInt("LEAVE_TYPE_ID"));
					lb.setTypeCode(code);
					lb.setDescription(rs.getString("DESCRIPTION"));
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
