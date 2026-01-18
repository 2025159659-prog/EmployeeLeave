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
     * Register new employee user
     */
    public boolean registerUser(User user) throws Exception {

        String sql = """
            INSERT INTO leave.users
            (fullname, email, password, gender, hiredate, phoneno,
             street, city, postal_code, state, ic_number,
             role, status, profile_picture, managerid)
            VALUES
            (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'EMPLOYEE', 'ACTIVE', NULL, ?)
        """;

        try (Connection con = DatabaseConnection.getConnection()) {

            if (isEmailExists(user.getEmail(), con)) {
                throw new Exception("Email already registered");
            }

            Integer managerEmpId = getSystemManagerEmpId(con);

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

                if (managerEmpId != null) {
                    ps.setInt(12, managerEmpId);
                } else {
                    ps.setNull(12, java.sql.Types.INTEGER);
                }

                return ps.executeUpdate() > 0;
            }
        }
    }

    /**
     * Get manager EMPID (SINGLE TABLE DESIGN)
     */
    private Integer getSystemManagerEmpId(Connection con) throws SQLException {

        String sql = """
            SELECT empid
            FROM leave.users
            WHERE role = 'MANAGER'
              AND status = 'ACTIVE'
            ORDER BY empid
            LIMIT 1
        """;

        try (PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            if (rs.next()) {
                return rs.getInt("empid");
            }
        }
        return null;
    }

    private boolean isEmailExists(String email, Connection con) throws SQLException {

        String sql = "SELECT 1 FROM leave.users WHERE email = ? LIMIT 1";

        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, email.trim());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /**
     * Get user by EMPID
     */
    public User getUserById(int empid) throws Exception {

        String sql = """
            SELECT *
            FROM leave.users
            WHERE empid = ?
        """;

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, empid);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    User user = new User();
                    user.setEmpId(rs.getInt("empid"));
                    user.setFullName(rs.getString("fullname"));
                    user.setEmail(rs.getString("email"));
                    user.setRole(rs.getString("role"));
                    user.setPhone(rs.getString("phoneno"));
                    user.setStreet(rs.getString("street"));
                    user.setCity(rs.getString("city"));
                    user.setPostalCode(rs.getString("postal_code"));
                    user.setState(rs.getString("state"));
                    user.setHireDate(rs.getDate("hiredate"));
                    user.setIcNumber(rs.getString("ic_number"));
                    user.setGender(rs.getString("gender"));
                    user.setProfilePic(rs.getString("profile_picture"));
                    user.setStatus(rs.getString("status"));
                    return user;
                }
            }
        }
        return null;
    }

    /**
     * Update profile (NO employees table)
     */
    public boolean updateProfile(User user) throws Exception {

        boolean hasPic = user.getProfilePic() != null && !user.getProfilePic().isEmpty();

        String sql = hasPic
            ? """
              UPDATE leave.users
              SET phoneno=?, street=?, city=?, postal_code=?, state=?, profile_picture=?
              WHERE empid=?
              """
            : """
              UPDATE leave.users
              SET phoneno=?, street=?, city=?, postal_code=?, state=?
              WHERE empid=?
              """;

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

    /**
     * Get all users
     */
    public List<User> getAllUsers() throws Exception {

        List<User> list = new ArrayList<>();

        String sql = """
            SELECT empid, fullname, email, role,
                   phoneno, hiredate, status,
                   gender, profile_picture
            FROM leave.users
            ORDER BY status, fullname
        """;

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                User u = new User();
                u.setEmpId(rs.getInt("empid"));
                u.setFullName(rs.getString("fullname"));
                u.setEmail(rs.getString("email"));
                u.setRole(rs.getString("role"));
                u.setPhone(rs.getString("phoneno"));
                u.setHireDate(rs.getDate("hiredate"));
                u.setGender(rs.getString("gender"));
                u.setProfilePic(rs.getString("profile_picture"));
                u.setStatus(rs.getString("status"));
                list.add(u);
            }
        }
        return list;
    }
}
