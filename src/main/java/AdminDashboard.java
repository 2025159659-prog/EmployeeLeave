import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.*;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import util.DatabaseConnection;

@WebServlet("/AdminDashboard")
public class AdminDashboard extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect("login.jsp");
            return;
        }

        String selectedYear = request.getParameter("year");
        if (selectedYear == null || selectedYear.isEmpty()) {
            selectedYear = String.valueOf(java.time.LocalDate.now().getYear());
        }

        Map<String, Integer> leaveStats = new LinkedHashMap<>();
        Map<String, Integer> monthlyTrends = new LinkedHashMap<>();
        List<String> years = new ArrayList<>();

        int totalEmployees = 0;
        int activeToday = 0;
        int totalHolidays = 0;

        try (Connection con = DatabaseConnection.getConnection()) {

            /* ===============================
               AVAILABLE YEARS
            =============================== */
            String sqlYears = """
                SELECT DISTINCT EXTRACT(YEAR FROM start_date)::text AS yr
                FROM leave.leave_requests
                ORDER BY yr DESC
            """;
            try (PreparedStatement ps = con.prepareStatement(sqlYears);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    years.add(rs.getString("yr"));
                }
            }

            if (!years.contains(selectedYear)) {
                years.add(selectedYear);
                Collections.sort(years, Collections.reverseOrder());
            }

            /* ===============================
               TOTAL EMPLOYEES
            =============================== */
            String sql1 = """
                SELECT COUNT(*)
                FROM leave.users
                WHERE status = 'ACTIVE'
                AND UPPER(role) = 'EMPLOYEE'
            """;
            try (PreparedStatement ps = con.prepareStatement(sql1);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) totalEmployees = rs.getInt(1);
            }

            /* ===============================
               ACTIVE TODAY
            =============================== */
            String sql2 = """
                SELECT COUNT(*)
                FROM leave.leave_requests r
                JOIN leave.leave_statuses s ON r.status_id = s.status_id
                WHERE s.status_code = 'APPROVED'
                AND CURRENT_DATE BETWEEN r.start_date AND r.end_date
            """;
            try (PreparedStatement ps = con.prepareStatement(sql2);
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) activeToday = rs.getInt(1);
            }

            /* ===============================
               TOTAL HOLIDAYS
            =============================== */
            String sql3 = """
                SELECT COUNT(*)
                FROM leave.holidays
                WHERE EXTRACT(YEAR FROM holiday_date)::text = ?
            """;
            try (PreparedStatement ps = con.prepareStatement(sql3)) {
                ps.setString(1, selectedYear);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) totalHolidays = rs.getInt(1);
                }
            }

            /* ===============================
               LEAVE BY TYPE
            =============================== */
            String sql4 = """
                SELECT t.type_code, COUNT(r.leave_id) AS total
                FROM leave.leave_requests r
                JOIN leave.leave_types t ON r.leave_type_id = t.leave_type_id
                WHERE EXTRACT(YEAR FROM r.start_date)::text = ?
                GROUP BY t.type_code
            """;
            try (PreparedStatement ps = con.prepareStatement(sql4)) {
                ps.setString(1, selectedYear);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        leaveStats.put(rs.getString("type_code"), rs.getInt("total"));
                    }
                }
            }

            /* ===============================
               MONTHLY TREND
            =============================== */
            String sql5 = """
                SELECT TO_CHAR(start_date, 'Mon') AS mname,
                       EXTRACT(MONTH FROM start_date) AS mnum,
                       COUNT(*) AS mcount
                FROM leave.leave_requests
                WHERE EXTRACT(YEAR FROM start_date)::text = ?
                GROUP BY mname, mnum
                ORDER BY mnum
            """;
            try (PreparedStatement ps = con.prepareStatement(sql5)) {
                ps.setString(1, selectedYear);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        monthlyTrends.put(rs.getString("mname"), rs.getInt("mcount"));
                    }
                }
            }

            request.setAttribute("totalEmployees", totalEmployees);
            request.setAttribute("activeToday", activeToday);
            request.setAttribute("totalHolidays", totalHolidays);
            request.setAttribute("leaveStats", leaveStats);
            request.setAttribute("monthlyTrends", monthlyTrends);
            request.setAttribute("years", years);

            request.getRequestDispatcher("adminDashboard.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("login.jsp?error=DatabaseError");
        }
    }
}
