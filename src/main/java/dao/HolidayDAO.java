package dao;

import bean.Holiday;
import util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class HolidayDAO {

    // ==============================
    // GET ALL HOLIDAYS
    // ==============================
    public List<Holiday> getAllHolidays() throws Exception {
        List<Holiday> list = new ArrayList<>();

        String sql = """
            SELECT holiday_id, holiday_name, holiday_type, holiday_date
            FROM leave.holidays
            ORDER BY holiday_date
        """;

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Holiday h = new Holiday();
                h.setId(rs.getInt("holiday_id"));
                h.setName(rs.getString("holiday_name"));
                h.setType(rs.getString("holiday_type"));

                Date dbDate = rs.getDate("holiday_date");
                if (dbDate != null) {
                    h.setDate(dbDate.toLocalDate());
                }

                list.add(h);
            }
        }
        return list;
    }

    // ==============================
    // ADD HOLIDAY
    // ==============================
    public void addHoliday(Holiday h) throws Exception {
        String sql = """
            INSERT INTO leave.holidays (holiday_date, holiday_name, holiday_type)
            VALUES (?, ?, ?)
        """;

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setDate(1, Date.valueOf(h.getDate()));
            ps.setString(2, h.getName());
            ps.setString(3, h.getType().toUpperCase()); // IMPORTANT
            ps.executeUpdate();
        }
    }

    // ==============================
    // UPDATE HOLIDAY
    // ==============================
    public void updateHoliday(Holiday h) throws Exception {
        String sql = """
            UPDATE leave.holidays
            SET holiday_name = ?, holiday_date = ?, holiday_type = ?
            WHERE holiday_id = ?
        """;

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, h.getName());
            ps.setDate(2, Date.valueOf(h.getDate()));
            ps.setString(3, h.getType().toUpperCase());
            ps.setInt(4, h.getId());
            ps.executeUpdate();
        }
    }

    // ==============================
    // DELETE HOLIDAY
    // ==============================
    public void deleteHoliday(int id) throws Exception {
        String sql = "DELETE FROM leave.holidays WHERE holiday_id = ?";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }
}
