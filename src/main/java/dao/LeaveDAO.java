package dao;

import bean.LeaveRequest;
import bean.LeaveBalance;
import bean.LeaveRecord;
import util.DatabaseConnection;
import jakarta.servlet.http.Part;
import java.io.InputStream;
import java.sql.*;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.*;

public class LeaveDAO {

	/**
	 * Fetch all leave types for dropdown selection.
	 */
							public List<Map<String, Object>> getAllLeaveTypes() throws Exception {
				
				    List<Map<String, Object>> list = new ArrayList<>();
				
				    String sql = """
				        SELECT 
				            leave_type_id,
				            type_code,
				            description
				        FROM leave_types
				        ORDER BY leave_type_id
				    """;
				
				    try (Connection con = DatabaseConnection.getConnection();
				         PreparedStatement ps = con.prepareStatement(sql);
				         ResultSet rs = ps.executeQuery()) {
				
				        while (rs.next()) {
				            Map<String, Object> m = new HashMap<>();
				
				            // 🔥 MAP IKUT APA JSP EXPECT
				            m.put("id", rs.getInt("leave_type_id"));
				            m.put("code", rs.getString("type_code"));
				            m.put("desc", rs.getString("description"));
				
				            list.add(m);
				        }
				    }
				
				    return list;
				}




	/**
	 * Fetch a specific leave request by ID and EmpID, including inheritance data.
	 */
	public LeaveRequest getLeaveById(int leaveId, int empId) throws Exception {
		String sql = "SELECT lr.*, ls.STATUS_CODE, lt.TYPE_CODE, " + "e.EMERGENCY_CATEGORY, e.EMERGENCY_CONTACT, "
				+ "s.MEDICAL_FACILITY as S_FAC, s.REF_SERIAL_NO as S_REF, "
				+ "h.HOSPITAL_NAME as H_NAME, h.ADMIT_DATE as H_ADMIT, h.DISCHARGE_DATE as H_DIS, "
				+ "m.CONSULTATION_CLINIC as M_CLINIC, m.EXPECTED_DUE_DATE as M_DUE, m.WEEK_PREGNANCY as M_WEEK, "
				+ "p.SPOUSE_NAME as P_SPOUSE, p.MEDICAL_FACILITY as P_FAC, p.DELIVERY_DATE as P_DEL "
				+ "FROM LEAVE_REQUESTS lr " + "JOIN LEAVE_STATUSES ls ON lr.STATUS_ID = ls.STATUS_ID "
				+ "JOIN LEAVE_TYPES lt ON lr.LEAVE_TYPE_ID = lt.LEAVE_TYPE_ID "
				+ "LEFT JOIN LR_EMERGENCY e ON lr.LEAVE_ID = e.LEAVE_ID "
				+ "LEFT JOIN LR_SICK s ON lr.LEAVE_ID = s.LEAVE_ID "
				+ "LEFT JOIN LR_HOSPITALIZATION h ON lr.LEAVE_ID = h.LEAVE_ID "
				+ "LEFT JOIN LR_MATERNITY m ON lr.LEAVE_ID = m.LEAVE_ID "
				+ "LEFT JOIN LR_PATERNITY p ON lr.LEAVE_ID = p.LEAVE_ID " + "WHERE lr.LEAVE_ID = ? AND lr.EMPID = ?";

		try (Connection con = DatabaseConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setInt(1, leaveId);
			ps.setInt(2, empId);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					LeaveRequest lr = new LeaveRequest();
					lr.setLeaveId(rs.getInt("LEAVE_ID"));
					lr.setEmpId(rs.getInt("EMPID"));
					lr.setLeaveTypeId(rs.getInt("LEAVE_TYPE_ID"));
					lr.setStartDate(rs.getDate("START_DATE").toLocalDate());
					lr.setEndDate(rs.getDate("END_DATE").toLocalDate());
					lr.setDuration(rs.getString("DURATION"));
					lr.setDurationDays(rs.getDouble("DURATION_DAYS"));
					lr.setReason(rs.getString("REASON"));
					lr.setStatusCode(rs.getString("STATUS_CODE"));
					lr.setHalfSession(rs.getString("HALF_SESSION"));

					String type = rs.getString("TYPE_CODE");
					if ("EMERGENCY".equals(type)) {
						lr.setEmergencyCategory(rs.getString("EMERGENCY_CATEGORY"));
						lr.setEmergencyContact(rs.getString("EMERGENCY_CONTACT"));
					} else if ("SICK".equals(type)) {
						lr.setMedicalFacility(rs.getString("S_FAC"));
						lr.setRefSerialNo(rs.getString("S_REF"));
					} else if ("HOSPITALIZATION".equals(type)) {
						lr.setMedicalFacility(rs.getString("H_NAME"));
						if (rs.getDate("H_ADMIT") != null)
							lr.setEventDate(rs.getDate("H_ADMIT").toLocalDate());
						if (rs.getDate("H_DIS") != null)
							lr.setDischargeDate(rs.getDate("H_DIS").toLocalDate());
					} else if ("MATERNITY".equals(type)) {
						lr.setMedicalFacility(rs.getString("M_CLINIC"));
						if (rs.getDate("M_DUE") != null)
							lr.setEventDate(rs.getDate("M_DUE").toLocalDate());
						lr.setWeekPregnancy(rs.getInt("M_WEEK"));
					} else if ("PATERNITY".equals(type)) {
						lr.setSpouseName(rs.getString("P_SPOUSE"));
						lr.setMedicalFacility(rs.getString("P_FAC"));
						if (rs.getDate("P_DEL") != null)
							lr.setEventDate(rs.getDate("P_DEL").toLocalDate());
					}
					return lr;
				}
			}
		}
		return null;
	}

	/**
	 * Calculate working days excluding Weekends and Holidays.
	 */
	public double calculateWorkingDays(LocalDate start, LocalDate end) throws Exception {
		double count = 0;
		Set<LocalDate> holidays = new HashSet<>();
		try (Connection con = DatabaseConnection.getConnection()) {
			String sql = "SELECT HOLIDAY_DATE FROM HOLIDAYS WHERE HOLIDAY_DATE BETWEEN ? AND ?";
			try (PreparedStatement ps = con.prepareStatement(sql)) {
				ps.setDate(1, java.sql.Date.valueOf(start));
				ps.setDate(2, java.sql.Date.valueOf(end));
				try (ResultSet rs = ps.executeQuery()) {
					while (rs.next()) {
						holidays.add(rs.getDate("HOLIDAY_DATE").toLocalDate());
					}
				}
			}
		}

		LocalDate curr = start;
		while (!curr.isAfter(end)) {
			DayOfWeek dow = curr.getDayOfWeek();
			if (dow != DayOfWeek.SATURDAY && dow != DayOfWeek.SUNDAY && !holidays.contains(curr)) {
				count++;
			}
			curr = curr.plusDays(1);
		}
		return count;
	}

	/**
	 * Submit a new leave request using Class Table Inheritance. Inserts into Parent
	 * (LEAVE_REQUESTS) then into the specific Child table.
	 */
	public boolean submitRequest(LeaveRequest req, Part filePart) throws Exception {
		Connection con = null;
		try {
			con = DatabaseConnection.getConnection();
			con.setAutoCommit(false);

// 1. Get Status ID for 'PENDING'
			int statusId = 0;
			String statusSql = "SELECT STATUS_ID FROM LEAVE_STATUSES WHERE UPPER(STATUS_CODE) = 'PENDING'";
			try (PreparedStatement ps = con.prepareStatement(statusSql); ResultSet rs = ps.executeQuery()) {
				if (rs.next())
					statusId = rs.getInt("STATUS_ID");
			}

// 2. Insert into BASE PARENT table (LEAVE_REQUESTS)
			String sqlParent = "INSERT INTO LEAVE_REQUESTS (EMPID, LEAVE_TYPE_ID, STATUS_ID, START_DATE, END_DATE, "
					+ "DURATION, DURATION_DAYS, REASON, HALF_SESSION, APPLIED_ON) "
					+ "VALUES (?,?,?,?,?,?,?,?,?, SYSDATE)";

			int leaveId = 0;
			try (PreparedStatement ps = con.prepareStatement(sqlParent, new String[] { "LEAVE_ID" })) {
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

				try (ResultSet rs = ps.getGeneratedKeys()) {
					if (rs.next())
						leaveId = rs.getInt(1);
				}
			}

// 3. Determine and Insert into SPECIFIC CHILD table based on Leave Type ID
			insertInheritedData(con, leaveId, req);

// 4. Handle File Attachment
			if (filePart != null && filePart.getSize() > 0) {
				String fileSql = "INSERT INTO LEAVE_REQUEST_ATTACHMENTS (LEAVE_ID, FILE_NAME, MIME_TYPE, FILE_SIZE, FILE_DATA, UPLOADED_ON) VALUES (?,?,?,?,?, SYSDATE)";
				try (PreparedStatement psF = con.prepareStatement(fileSql);
						InputStream in = filePart.getInputStream()) {
					psF.setInt(1, leaveId);
					psF.setString(2, filePart.getSubmittedFileName());
					psF.setString(3, filePart.getContentType());
					psF.setLong(4, filePart.getSize());
					psF.setBinaryStream(5, in);
					psF.executeUpdate();
				}
			}

// 5. Update Balances
			updateBalance(con, req.getEmpId(), req.getLeaveTypeId(), req.getDurationDays());

			con.commit();
			return true;
		} catch (Exception e) {
			if (con != null)
				con.rollback();
			throw e;
		} finally {
			if (con != null)
				con.close();
		}
	}

	/**
	 * Update an existing leave request.
	 */
	public boolean updateLeave(LeaveRequest req, int empId) throws Exception {
		Connection con = null;
		try {
			con = DatabaseConnection.getConnection();
			con.setAutoCommit(false);

// 1. Get old data for balance restoration
			double oldDays = 0;
			int oldTypeId = 0;
			String check = "SELECT DURATION_DAYS, LEAVE_TYPE_ID FROM LEAVE_REQUESTS WHERE LEAVE_ID = ? AND EMPID = ? AND STATUS_ID = (SELECT STATUS_ID FROM LEAVE_STATUSES WHERE UPPER(STATUS_CODE)='PENDING')";
			try (PreparedStatement ps = con.prepareStatement(check)) {
				ps.setInt(1, req.getLeaveId());
				ps.setInt(2, empId);
				try (ResultSet rs = ps.executeQuery()) {
					if (rs.next()) {
						oldDays = rs.getDouble("DURATION_DAYS");
						oldTypeId = rs.getInt("LEAVE_TYPE_ID");
					} else
						return false;
				}
			}

// 2. Update Parent
			String sqlP = "UPDATE LEAVE_REQUESTS SET LEAVE_TYPE_ID=?, START_DATE=?, END_DATE=?, DURATION=?, DURATION_DAYS=?, REASON=?, HALF_SESSION=? WHERE LEAVE_ID=? AND EMPID=?";
			try (PreparedStatement ps = con.prepareStatement(sqlP)) {
				ps.setInt(1, req.getLeaveTypeId());
				ps.setDate(2, java.sql.Date.valueOf(req.getStartDate()));
				ps.setDate(3, java.sql.Date.valueOf(req.getEndDate()));
				ps.setString(4, req.getDuration());
				ps.setDouble(5, req.getDurationDays());
				ps.setString(6, req.getReason());
				ps.setString(7, req.getHalfSession());
				ps.setInt(8, req.getLeaveId());
				ps.setInt(9, empId);
				ps.executeUpdate();
			}

// 3. Clear and Re-insert Child Data
			String[] childTables = { "LR_EMERGENCY", "LR_SICK", "LR_HOSPITALIZATION", "LR_MATERNITY", "LR_PATERNITY" };
			for (String table : childTables) {
				try (PreparedStatement ps = con.prepareStatement("DELETE FROM " + table + " WHERE LEAVE_ID=?")) {
					ps.setInt(1, req.getLeaveId());
					ps.executeUpdate();
				}
			}
			insertInheritedData(con, req.getLeaveId(), req);

// 4. Correct Balances
			updateBalance(con, empId, oldTypeId, -oldDays);
			updateBalance(con, empId, req.getLeaveTypeId(), req.getDurationDays());

			con.commit();
			return true;
		} catch (Exception e) {
			if (con != null)
				con.rollback();
			throw e;
		} finally {
			if (con != null)
				con.close();
		}
	}

	/**
	 * Delete pending leave and restore balance.
	 */
	public boolean deleteLeave(int leaveId, int empId) throws Exception {
		Connection con = null;
		try {
			con = DatabaseConnection.getConnection();
			con.setAutoCommit(false);

			double days = 0;
			int typeId = 0;
			String sql = "SELECT DURATION_DAYS, LEAVE_TYPE_ID FROM LEAVE_REQUESTS WHERE LEAVE_ID=? AND EMPID=? AND STATUS_ID=(SELECT STATUS_ID FROM LEAVE_STATUSES WHERE UPPER(STATUS_CODE)='PENDING')";
			try (PreparedStatement ps = con.prepareStatement(sql)) {
				ps.setInt(1, leaveId);
				ps.setInt(2, empId);
				try (ResultSet rs = ps.executeQuery()) {
					if (rs.next()) {
						days = rs.getDouble("DURATION_DAYS");
						typeId = rs.getInt("LEAVE_TYPE_ID");
					} else
						return false;
				}
			}

// Child table deletions are handled by DB Cascade if configured, otherwise
// manually:
			String[] childTables = { "LR_EMERGENCY", "LR_SICK", "LR_HOSPITALIZATION", "LR_MATERNITY", "LR_PATERNITY",
					"LEAVE_REQUEST_ATTACHMENTS" };
			for (String table : childTables) {
				try (PreparedStatement ps = con.prepareStatement("DELETE FROM " + table + " WHERE LEAVE_ID=?")) {
					ps.setInt(1, leaveId);
					ps.executeUpdate();
				}
			}

			try (PreparedStatement ps = con.prepareStatement("DELETE FROM LEAVE_REQUESTS WHERE LEAVE_ID=?")) {
				ps.setInt(1, leaveId);
				ps.executeUpdate();
			}

			updateBalance(con, empId, typeId, -days);

			con.commit();
			return true;
		} catch (Exception e) {
			if (con != null)
				con.rollback();
			throw e;
		} finally {
			if (con != null)
				con.close();
		}
	}

	/**
	 * Retrieves leave history using LEFT JOINs across all inheritance sub-tables.
	 */
	public List<Map<String, Object>> getLeaveHistory(int empId, String status, String year) throws Exception {
		List<Map<String, Object>> list = new ArrayList<>();
		StringBuilder sql = new StringBuilder(
				"SELECT lr.LEAVE_ID, lr.START_DATE, lr.END_DATE, lr.DURATION, lr.DURATION_DAYS, lr.REASON, lr.MANAGER_COMMENT, lr.APPLIED_ON, "
						+ "lt.TYPE_CODE, ls.STATUS_CODE, att.FILE_NAME, "
						+ "e.EMERGENCY_CATEGORY, e.EMERGENCY_CONTACT, "
						+ "s.MEDICAL_FACILITY as S_FAC, s.REF_SERIAL_NO as S_REF, "
						+ "h.HOSPITAL_NAME as H_NAME, h.ADMIT_DATE as H_ADMIT, h.DISCHARGE_DATE as H_DIS, "
						+ "m.CONSULTATION_CLINIC as M_CLINIC, m.EXPECTED_DUE_DATE as M_DUE, m.WEEK_PREGNANCY as M_WEEK, "
						+ "p.SPOUSE_NAME as P_SPOUSE, p.MEDICAL_FACILITY as P_FAC, p.DELIVERY_DATE as P_DEL "
						+ "FROM LEAVE_REQUESTS lr " + "JOIN LEAVE_TYPES lt ON lr.LEAVE_TYPE_ID = lt.LEAVE_TYPE_ID "
						+ "JOIN LEAVE_STATUSES ls ON lr.STATUS_ID = ls.STATUS_ID "
						+ "LEFT JOIN LEAVE_REQUEST_ATTACHMENTS att ON lr.LEAVE_ID = att.LEAVE_ID "
						+ "LEFT JOIN LR_EMERGENCY e ON lr.LEAVE_ID = e.LEAVE_ID "
						+ "LEFT JOIN LR_SICK s ON lr.LEAVE_ID = s.LEAVE_ID "
						+ "LEFT JOIN LR_HOSPITALIZATION h ON lr.LEAVE_ID = h.LEAVE_ID "
						+ "LEFT JOIN LR_MATERNITY m ON lr.LEAVE_ID = m.LEAVE_ID "
						+ "LEFT JOIN LR_PATERNITY p ON lr.LEAVE_ID = p.LEAVE_ID " + "WHERE lr.EMPID = ?");

		if (status != null && !status.equalsIgnoreCase("ALL"))
			sql.append(" AND ls.STATUS_CODE = ?");
		if (year != null && !year.isEmpty())
			sql.append(" AND TO_CHAR(lr.START_DATE, 'YYYY') = ?");
		sql.append(" ORDER BY lr.APPLIED_ON DESC");

		try (Connection con = DatabaseConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql.toString())) {
			int idx = 1;
			ps.setInt(idx++, empId);
			if (status != null && !status.equalsIgnoreCase("ALL"))
				ps.setString(idx++, status.toUpperCase());
			if (year != null && !year.isEmpty())
				ps.setString(idx++, year);

			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next()) {
					Map<String, Object> map = new HashMap<>();
					map.put("id", rs.getInt("LEAVE_ID"));
					map.put("type", rs.getString("TYPE_CODE"));
					map.put("start", rs.getDate("START_DATE").toString());
					map.put("end", rs.getDate("END_DATE").toString());
					map.put("status", rs.getString("STATUS_CODE"));
					map.put("reason", rs.getString("REASON"));
					map.put("totalDays", rs.getDouble("DURATION_DAYS"));
					map.put("duration", rs.getString("DURATION"));
					map.put("appliedOn", rs.getTimestamp("APPLIED_ON").toString());
					map.put("managerComment", rs.getString("MANAGER_COMMENT"));
					map.put("hasFile", rs.getString("FILE_NAME") != null);

// MAPPING TO LONG KEYS FOR JSP COMPATIBILITY
					String code = rs.getString("TYPE_CODE");
					if ("EMERGENCY".equals(code)) {
						map.put("emergencyCategory", rs.getString("EMERGENCY_CATEGORY"));
						map.put("emergencyContact", rs.getString("EMERGENCY_CONTACT"));
					} else if ("SICK".equals(code)) {
						map.put("medicalFacility", rs.getString("S_FAC"));
						map.put("refSerialNo", rs.getString("S_REF"));
					} else if ("HOSPITALIZATION".equals(code)) {
						map.put("medicalFacility", rs.getString("H_NAME"));
						map.put("eventDate", rs.getDate("H_ADMIT") != null ? rs.getDate("H_ADMIT").toString() : "");
						map.put("dischargeDate", rs.getDate("H_DIS") != null ? rs.getDate("H_DIS").toString() : "");
					} else if ("MATERNITY".equals(code)) {
						map.put("medicalFacility", rs.getString("M_CLINIC"));
						map.put("eventDate", rs.getDate("M_DUE") != null ? rs.getDate("M_DUE").toString() : "");
						map.put("weekPregnancy", rs.getInt("M_WEEK"));
					} else if ("PATERNITY".equals(code)) {
						map.put("spouseName", rs.getString("P_SPOUSE"));
						map.put("medicalFacility", rs.getString("P_FAC"));
						map.put("eventDate", rs.getDate("P_DEL") != null ? rs.getDate("P_DEL").toString() : "");
					}
					list.add(map);
				}
			}
		}
		return list;
	}

	/**
	 * Helper to insert child table records based on type.
	 */
	private void insertInheritedData(Connection con, int leaveId, LeaveRequest req) throws Exception {
		String sql = null;
// Cari TYPE_CODE berdasarkan LEAVE_TYPE_ID
		String typeCode = "";
		String findCode = "SELECT TYPE_CODE FROM LEAVE_TYPES WHERE LEAVE_TYPE_ID = ?";
		try (PreparedStatement psCode = con.prepareStatement(findCode)) {
			psCode.setInt(1, req.getLeaveTypeId());
			try (ResultSet rs = psCode.executeQuery()) {
				if (rs.next())
					typeCode = rs.getString("TYPE_CODE").toUpperCase();
			}
		}

		if (typeCode.contains("EMERGENCY")) {
			sql = "INSERT INTO LR_EMERGENCY (LEAVE_ID, EMERGENCY_CATEGORY, EMERGENCY_CONTACT) VALUES (?,?,?)";
		} else if (typeCode.contains("SICK")) {
			sql = "INSERT INTO LR_SICK (LEAVE_ID, MEDICAL_FACILITY, REF_SERIAL_NO) VALUES (?,?,?)";
		} else if (typeCode.contains("HOSPITALIZATION")) {
			sql = "INSERT INTO LR_HOSPITALIZATION (LEAVE_ID, HOSPITAL_NAME, ADMIT_DATE, DISCHARGE_DATE) VALUES (?,?,?,?)";
		} else if (typeCode.contains("MATERNITY")) {
			sql = "INSERT INTO LR_MATERNITY (LEAVE_ID, CONSULTATION_CLINIC, EXPECTED_DUE_DATE, WEEK_PREGNANCY) VALUES (?,?,?,?)";
		} else if (typeCode.contains("PATERNITY")) {
			sql = "INSERT INTO LR_PATERNITY (LEAVE_ID, SPOUSE_NAME, MEDICAL_FACILITY, DELIVERY_DATE) VALUES (?,?,?,?)";
		}

		if (sql != null) {
			try (PreparedStatement ps = con.prepareStatement(sql)) {
				ps.setInt(1, leaveId);
				if (typeCode.contains("EMERGENCY")) {
					ps.setString(2, req.getEmergencyCategory());
					ps.setString(3, req.getEmergencyContact());
				} else if (typeCode.contains("SICK")) {
					ps.setString(2, req.getMedicalFacility());
					ps.setString(3, req.getRefSerialNo());
				} else if (typeCode.contains("HOSPITALIZATION")) {
					ps.setString(2, req.getMedicalFacility());
					ps.setDate(3, java.sql.Date.valueOf(req.getEventDate()));
					ps.setDate(4, java.sql.Date.valueOf(req.getDischargeDate()));
				} else if (typeCode.contains("MATERNITY")) {
					ps.setString(2, req.getMedicalFacility());
					ps.setDate(3, java.sql.Date.valueOf(req.getEventDate()));
					ps.setInt(4, req.getWeekPregnancy());
				} else if (typeCode.contains("PATERNITY")) {
					ps.setString(2, req.getSpouseName());
					ps.setString(3, req.getMedicalFacility());
					ps.setDate(4, java.sql.Date.valueOf(req.getEventDate()));
				}
				ps.executeUpdate();
			}
		}
	}

	/**
	 * Helper to atomicly update leave balance.
	 */
	private void updateBalance(Connection con, int empId, int typeId, double dayDiff) throws Exception {
		String sql = "UPDATE LEAVE_BALANCES SET PENDING = PENDING + ?, TOTAL = TOTAL - ? WHERE EMPID = ? AND LEAVE_TYPE_ID = ?";
		try (PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setDouble(1, dayDiff);
			ps.setDouble(2, dayDiff);
			ps.setInt(3, empId);
			ps.setInt(4, typeId);
			ps.executeUpdate();
		}
	}

	public List<String> getHistoryYears(int empId) throws Exception {
		List<String> years = new ArrayList<>();
		String sql = "SELECT DISTINCT TO_CHAR(START_DATE, 'YYYY') as YR FROM LEAVE_REQUESTS WHERE EMPID = ? ORDER BY YR DESC";
		try (Connection con = DatabaseConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setInt(1, empId);
			try (ResultSet rs = ps.executeQuery()) {
				while (rs.next())
					years.add(rs.getString("YR"));
			}
		}
		return years;
	}

	public boolean requestCancellation(int leaveId, int empId) throws Exception {
		String sql = "UPDATE LEAVE_REQUESTS SET STATUS_ID = (SELECT STATUS_ID FROM LEAVE_STATUSES WHERE UPPER(STATUS_CODE) = 'CANCELLATION_REQUESTED') "
				+ "WHERE LEAVE_ID = ? AND EMPID = ? AND STATUS_ID = (SELECT STATUS_ID FROM LEAVE_STATUSES WHERE UPPER(STATUS_CODE) = 'APPROVED')";
		try (Connection conn = DatabaseConnection.getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
			ps.setInt(1, leaveId);
			ps.setInt(2, empId);
			return ps.executeUpdate() > 0;
		}
	}

	public Map<Integer, Map<Integer, LeaveBalance>> getLeaveBalanceIndex() throws Exception {
		Map<Integer, Map<Integer, LeaveBalance>> index = new HashMap<>();
		String sql = "SELECT b.*, t.TYPE_CODE, t.DESCRIPTION FROM LEAVE_BALANCES b JOIN LEAVE_TYPES t ON b.LEAVE_TYPE_ID = t.LEAVE_TYPE_ID";
		try (Connection conn = DatabaseConnection.getConnection();
				PreparedStatement ps = conn.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				int empId = rs.getInt("EMPID");
				LeaveBalance lb = new LeaveBalance();
				lb.setEmpId(empId);
				lb.setLeaveTypeId(rs.getInt("LEAVE_TYPE_ID"));
				lb.setTypeCode(rs.getString("TYPE_CODE"));
				lb.setDescription(rs.getString("DESCRIPTION"));
				lb.setEntitlement(rs.getInt("ENTITLEMENT"));
				lb.setUsed(rs.getDouble("USED"));
				lb.setPending(rs.getDouble("PENDING"));
				lb.setTotalAvailable(rs.getDouble("TOTAL"));
				index.computeIfAbsent(empId, k -> new HashMap<>()).put(lb.getLeaveTypeId(), lb);
			}
		}
		return index;
	}

}


