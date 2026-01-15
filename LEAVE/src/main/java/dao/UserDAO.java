package dao;

import bean.User;
import util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class UserDAO {

    /**
     * Registers a new employee. 
     * Role is automatically set to 'EMPLOYEE' for security.
     */
    public boolean registerUser(User user) throws Exception {
        String sql = "INSERT INTO USERS " +
                     "(FULLNAME, EMAIL, PASSWORD, GENDER, HIREDATE, PHONENO, " +
                     "STREET, CITY, POSTAL_CODE, STATE, IC_NUMBER, ROLE, STATUS, PROFILE_PICTURE) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'EMPLOYEE', 'ACTIVE', NULL)";

        try (Connection con = DatabaseConnection.getConnection()) {
            // Check duplicate email first
            if (isEmailExists(user.getEmail(), con)) {
                throw new Exception("Email address is already registered.");
            }

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
                
                return ps.executeUpdate() > 0;
            }
        }
    }

    private boolean isEmailExists(String email, Connection con) throws SQLException {
        String sql = "SELECT COUNT(*) FROM USERS WHERE EMAIL = ?";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, email.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1) > 0;
            }
        }
        return false;
    }

    public User getUserById(int empid) throws Exception {
        String sql = "SELECT * FROM USERS WHERE EMPID = ?";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
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
        String sql = hasPic ? 
            "UPDATE USERS SET PHONENO=?, STREET=?, CITY=?, POSTAL_CODE=?, STATE=?, PROFILE_PICTURE=? WHERE EMPID=?" :
            "UPDATE USERS SET PHONENO=?, STREET=?, CITY=?, POSTAL_CODE=?, STATE=? WHERE EMPID=?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
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
        // Added GENDER and PROFILE_PICTURE to the SELECT
        String sql = "SELECT EMPID, FULLNAME, EMAIL, ROLE, PHONENO, HIREDATE, STATUS, GENDER, PROFILE_PICTURE " +
                     "FROM USERS ORDER BY STATUS ASC, FULLNAME ASC";

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
