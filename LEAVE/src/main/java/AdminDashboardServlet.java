import java.io.IOException;
import java.sql.*;
import java.util.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

@WebServlet("/AdminDashboardServlet")
public class AdminDashboardServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || !"ADMIN".equalsIgnoreCase((String) session.getAttribute("role"))) {
            response.sendRedirect("login.jsp");
            return;
        }

        Map<String, Integer> leaveStats = new LinkedHashMap<>();
        Map<String, Integer> monthlyTrends = new LinkedHashMap<>();
        int totalEmployees = 0, activeToday = 0, totalHolidays = 0;

        try (Connection con = DatabaseConnection.getConnection()) {
            
            // 1. Total Workforce
            String sql1 = "SELECT COUNT(*) FROM USERS WHERE UPPER(ROLE) != 'ADMIN'";
            try (PreparedStatement ps = con.prepareStatement(sql1); ResultSet rs = ps.executeQuery()) {
                if (rs.next()) totalEmployees = rs.getInt(1);
            }

            // 2. Currently On Leave (Approved & Date check)
            String sql2 = "SELECT COUNT(*) FROM LEAVE_REQUESTS r " +
                          "JOIN LEAVE_STATUSES s ON r.STATUS_ID = s.STATUS_ID " +
                          "WHERE s.STATUS_CODE = 'APPROVED' " +
                          "AND TRUNC(SYSDATE) BETWEEN TRUNC(r.START_DATE) AND TRUNC(r.END_DATE)";
            try (PreparedStatement ps = con.prepareStatement(sql2); ResultSet rs = ps.executeQuery()) {
                if (rs.next()) activeToday = rs.getInt(1);
            }

            // 3. Holidays Count (Current Year)
            String sql3 = "SELECT COUNT(*) FROM HOLIDAYS WHERE TO_CHAR(HOLIDAY_DATE, 'YYYY') = TO_CHAR(SYSDATE, 'YYYY')";
            try (PreparedStatement ps = con.prepareStatement(sql3); ResultSet rs = ps.executeQuery()) {
                if (rs.next()) totalHolidays = rs.getInt(1);
            }

            // 4. Leave Type Distribution (Pie Chart Data)
            String sql4 = "SELECT t.TYPE_CODE, COUNT(r.LEAVE_ID) as total " +
                          "FROM LEAVE_REQUESTS r " +
                          "JOIN LEAVE_TYPES t ON r.LEAVE_TYPE_ID = t.LEAVE_TYPE_ID " +
                          "GROUP BY t.TYPE_CODE";
            try (PreparedStatement ps = con.prepareStatement(sql4); ResultSet rs = ps.executeQuery()) {
                while (rs.next()) leaveStats.put(rs.getString("TYPE_CODE"), rs.getInt("total"));
            }

            // 5. Monthly Trends (Bar Chart Data - Dynamic sorting)
            String sql5 = "SELECT mname, mcount FROM (" +
                          "  SELECT TO_CHAR(START_DATE, 'Mon') as mname, TO_CHAR(START_DATE, 'MM') as mnum, COUNT(*) as mcount " +
                          "  FROM LEAVE_REQUESTS WHERE START_DATE >= ADD_MONTHS(SYSDATE, -12) " +
                          "  GROUP BY TO_CHAR(START_DATE, 'Mon'), TO_CHAR(START_DATE, 'MM') " +
                          "  ORDER BY mnum" +
                          ")";
            try (PreparedStatement ps = con.prepareStatement(sql5); ResultSet rs = ps.executeQuery()) {
                while (rs.next()) monthlyTrends.put(rs.getString("mname"), rs.getInt("mcount"));
            }

            request.setAttribute("totalEmployees", totalEmployees);
            request.setAttribute("activeToday", activeToday);
            request.setAttribute("totalHolidays", totalHolidays);
            request.setAttribute("leaveStats", leaveStats);
            request.setAttribute("monthlyTrends", monthlyTrends);
            
            request.getRequestDispatcher("adminDashboard.jsp").forward(request, response);

        } catch (SQLException | ClassNotFoundException e) {
            e.printStackTrace();
            response.sendRedirect("login.jsp?error=DatabaseError");
        }
    }
}