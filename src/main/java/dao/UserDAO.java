
package dao;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import bean.User;
import util.DatabaseConnection;

public class UserDAO {

	/**
	 * Registers a new employee. Role is automatically set to 'EMPLOYEE'. ManagerID
	 * is automatically assigned by looking up the system's active Manager.
	 */
	public boolean registerUser(User user) throws Exception {
		// Updated SQL to include MANAGERID
		String sql = "INSERT INTO USERS " + "(FULLNAME, EMAIL, PASSWORD, GENDER, HIREDATE, PHONENO, "
				+ "STREET, CITY, POSTAL_CODE, STATE, IC_NUMBER, ROLE, STATUS, PROFILE_PICTURE, MANAGERID) "
				+ "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'EMPLOYEE', 'ACTIVE', NULL, ?)";

		try (Connection con = DatabaseConnection.getConnection()) {
			// 1. Check duplicate email first
			if (isEmailExists(user.getEmail(), con)) {
				throw new Exception("Email address is already registered.");
			}

			// 2. Retrieve the ID of the system manager
			Integer managerId = getSystemManagerId(con);

			try (PreparedStatement ps = con.prepareStatement(sql)) {
				ps.setString(1, user.getFullName());
				ps.setString(2, user.getEmail());
				ps.setString(3, user.getPassword());
				ps.setString(4, user.getGender());
				ps.setDate(5, new java.sql.Date(user.getHireDate().getTime()));
				ps.setString(6, user.getPhone());
				ps.setString(7, user.getStreet());
				ps.setString(8, user.getCity());
				ps.setString(9, user.getPostalCode());
				ps.setString(10, user.getState());
				ps.setString(11, user.getIcNumber());

				// 3. Bind Manager ID (can be null if no manager found, but column allows it)
				if (managerId != null) {
					ps.setInt(12, managerId);
				} else {
					ps.setNull(12, java.sql.Types.INTEGER);
				}

				return ps.executeUpdate() > 0;
			}
		}
	}

	/**
	 * Helper method to find the EMPID of the user with ROLE 'MANAGER'. Since there
	 * is only one manager, we fetch the first active one found.
	 */
	private Integer getSystemManagerId(Connection con) throws SQLException {
		String sql = "SELECT EMPID FROM USERS WHERE ROLE = 'MANAGER' AND STATUS = 'ACTIVE' FETCH FIRST 1 ROWS ONLY";
		try (PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
			if (rs.next()) {
				return rs.getInt("EMPID");
			}
		}
		return null;
	}

	private boolean isEmailExists(String email, Connection con) throws SQLException {
		String sql = "SELECT COUNT(*) FROM USERS WHERE EMAIL = ?";
		try (PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, email.trim());
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next())
					return rs.getInt(1) > 0;
			}
		}
		return false;
	}

	public User getUserById(int empid) throws Exception {
		String sql = "SELECT * FROM USERS WHERE EMPID = ?";
		try (Connection con = DatabaseConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setInt(1, empid);
			try (ResultSet rs = ps.executeQuery()) {
				if (rs.next()) {
					User user = new User();
					user.setEmpId(rs.getInt("EMPID"));
					user.setFullName(rs.getString("FULLNAME"));
					user.setEmail(rs.getString("EMAIL"));
					user.setRole(rs.getString("ROLE"));
					user.setPhone(rs.getString("PHONENO"));
					user.setStreet(rs.getString("STREET"));
					user.setCity(rs.getString("CITY"));
					user.setPostalCode(rs.getString("POSTAL_CODE"));
					user.setState(rs.getString("STATE"));
					user.setHireDate(rs.getDate("HIREDATE"));
					user.setIcNumber(rs.getString("IC_NUMBER"));
					user.setGender(rs.getString("GENDER"));
					user.setProfilePic(rs.getString("PROFILE_PICTURE"));
					user.setStatus(rs.getString("STATUS"));
					return user;
				}
			}
		}
		return null;
	}

	public boolean updateProfile(User user) throws Exception {
		boolean hasPic = user.getProfilePic() != null && !user.getProfilePic().isEmpty();
		String sql = hasPic
				? "UPDATE USERS SET PHONENO=?, STREET=?, CITY=?, POSTAL_CODE=?, STATE=?, PROFILE_PICTURE=? WHERE EMPID=?"
				: "UPDATE USERS SET PHONENO=?, STREET=?, CITY=?, POSTAL_CODE=?, STATE=? WHERE EMPID=?";

		try (Connection con = DatabaseConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
			ps.setString(1, user.getPhone());
			ps.setString(2, user.getStreet());
			ps.setString(3, user.getCity());
			ps.setString(4, user.getPostalCode());
			ps.setString(5, user.getState());
			if (hasPic) {
				ps.setString(6, user.getProfilePic());
				ps.setInt(7, user.getEmpId());
			} else {
				ps.setInt(6, user.getEmpId());
			}
			return ps.executeUpdate() > 0;
		}
	}

	public List<User> getAllUsers() throws Exception {
		List<User> userList = new ArrayList<>();
		String sql = "SELECT EMPID, FULLNAME, EMAIL, ROLE, PHONENO, HIREDATE, STATUS, GENDER, PROFILE_PICTURE "
				+ "FROM USERS ORDER BY STATUS ASC, FULLNAME ASC";

		try (Connection con = DatabaseConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {

			while (rs.next()) {
				User user = new User();
				user.setEmpId(rs.getInt("EMPID"));
				user.setFullName(rs.getString("FULLNAME"));
				user.setEmail(rs.getString("EMAIL"));
				user.setRole(rs.getString("ROLE"));
				user.setPhone(rs.getString("PHONENO"));
				user.setHireDate(rs.getDate("HIREDATE"));
				user.setGender(rs.getString("GENDER"));
				user.setProfilePic(rs.getString("PROFILE_PICTURE"));
				String status = rs.getString("STATUS");
				user.setStatus(status != null ? status : "ACTIVE");
				userList.add(user);
			}
		}
		return userList;
	}
}