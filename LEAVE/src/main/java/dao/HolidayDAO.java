package dao;

import bean.Holiday;
import util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class HolidayDAO {

    /**
     * Fetch all holidays from the database.
     * Maps the result set directly to the Holiday bean using LocalDate.
     */
    public List<Holiday> getAllHolidays() throws Exception {
        List<Holiday> list = new ArrayList<>();
        String sql = "SELECT HOLIDAY_ID, HOLIDAY_NAME, HOLIDAY_TYPE, HOLIDAY_DATE " +
                     "FROM HOLIDAYS ORDER BY HOLIDAY_DATE";
        
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Holiday h = new Holiday();
                h.setId(rs.getInt("HOLIDAY_ID"));
                h.setName(rs.getString("HOLIDAY_NAME"));
                h.setType(rs.getString("HOLIDAY_TYPE"));
                
                // Convert SQL Date to java.time.LocalDate for the Bean
                Date dbDate = rs.getDate("HOLIDAY_DATE");
                if (dbDate != null) {
                    h.setDate(dbDate.toLocalDate());
                }
                
                list.add(h);
            }
        }
        return list;
    }

    /**
     * Add a new holiday using the Holiday bean data.
     */
    public void addHoliday(Holiday h) throws Exception {
        String sql = "INSERT INTO HOLIDAYS (HOLIDAY_DATE, HOLIDAY_NAME, HOLIDAY_TYPE) VALUES (?, ?, ?)";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setDate(1, java.sql.Date.valueOf(h.getDate()));
            ps.setString(2, h.getName());
            ps.setString(3, h.getType());
            ps.executeUpdate();
        }
    }

    /**
     * Update an existing holiday record.
     */
    public void updateHoliday(Holiday h) throws Exception {
        String sql = "UPDATE HOLIDAYS SET HOLIDAY_NAME = ?, HOLIDAY_DATE = ?, HOLIDAY_TYPE = ? WHERE HOLIDAY_ID = ?";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, h.getName());
            ps.setDate(2, java.sql.Date.valueOf(h.getDate()));
            ps.setString(3, h.getType());
            ps.setInt(4, h.getId());
            ps.executeUpdate();
        }
    }

    /**
     * Remove a holiday record by ID.
     */
    public void deleteHoliday(int id) throws Exception {
        String sql = "DELETE FROM HOLIDAYS WHERE HOLIDAY_ID = ?";
        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }
}