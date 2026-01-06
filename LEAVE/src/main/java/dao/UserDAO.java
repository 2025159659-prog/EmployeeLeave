package dao;

import bean.User;
import util.DatabaseConnection;
import java.sql.*;

public class UserDAO {

    public User getUserById(int empid) throws Exception {
        String sql = "SELECT EMPID, FULLNAME, EMAIL, ROLE, PHONENO, ADDRESS, HIREDATE, IC_NUMBER, GENDER, PROFILE_PICTURE " +
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
                    user.setAddress(rs.getString("ADDRESS"));
                    user.setHireDate(rs.getDate("HIREDATE"));
                    user.setIcNumber(rs.getString("IC_NUMBER"));
                    user.setGender(rs.getString("GENDER"));
                    user.setProfilePic(rs.getString("PROFILE_PICTURE"));
                    return user;
                }
            }
        }
        return null;
    }

    public boolean updateProfile(User user) throws Exception {
        boolean hasPic = user.getProfilePic() != null;
        String sql = hasPic ? 
            "UPDATE USERS SET EMAIL=?, PHONENO=?, ADDRESS=?, PROFILE_PICTURE=? WHERE EMPID=?" :
            "UPDATE USERS SET EMAIL=?, PHONENO=?, ADDRESS=? WHERE EMPID=?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, user.getEmail());
            ps.setString(2, user.getPhone());
            ps.setString(3, user.getAddress());
            
            if (hasPic) {
                ps.setString(4, user.getProfilePic());
                ps.setInt(5, user.getEmpId());
            } else {
                ps.setInt(4, user.getEmpId());
            }
            
            return ps.executeUpdate() > 0;
        }
    }
}