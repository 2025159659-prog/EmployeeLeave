package dao;

import bean.User;
import util.DatabaseConnection;
import java.sql.*;

public class UserDAO {

    /**
     * Retrieves a full user profile by their Employee ID.
     * Updated to include granular address fields and account status.
     */
    public User getUserById(int empid) throws Exception {
        String sql = "SELECT EMPID, FULLNAME, EMAIL, ROLE, PHONENO, " +
                     "STREET, CITY, POSTAL_CODE, STATE, " + // Detailed address fields
                     "HIREDATE, IC_NUMBER, GENDER, PROFILE_PICTURE, STATUS " +
                     "FROM USERS WHERE EMPID = ?";
        
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
                    
                    // Mapping new address fields
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

    /**
     * Updates the user's editable profile information.
     * Note: Email is intentionally excluded from updates to maintain identity integrity.
     */
    public boolean updateProfile(User user) throws Exception {
        boolean hasPic = user.getProfilePic() != null && !user.getProfilePic().isEmpty();
        
        // SQL query updated to replace ADDRESS with granular fields and remove EMAIL
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
}