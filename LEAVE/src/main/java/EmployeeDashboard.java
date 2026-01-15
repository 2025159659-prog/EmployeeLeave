import bean.Holiday;
import bean.LeaveBalance;
import dao.EmployeeDAO;
import dao.LeaveBalanceDAO;
import util.DatabaseConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.Connection;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;

@WebServlet("/EmployeeDashboard")
public class EmployeeDashboard extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private EmployeeDAO employeeDAO = new EmployeeDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // 1. SECURITY CHECK
        HttpSession session = request.getSession(false);
        String role = (session != null) ? String.valueOf(session.getAttribute("role")) : "";
        
        if (session == null || session.getAttribute("empid") == null ||
            (!"EMPLOYEE".equalsIgnoreCase(role) && !"MANAGER".equalsIgnoreCase(role))) {
            
            response.sendRedirect("login.jsp?error=Please login as an employee or manager.");
            return;
        }

        // 2. GET PARAMETERS
        int empId = Integer.parseInt(String.valueOf(session.getAttribute("empid")));
        LocalDate today = LocalDate.now();
        int calYear = parseInt(request.getParameter("year"), today.getYear());
        int calMonth = parseInt(request.getParameter("month"), today.getMonthValue());

        // Use try-with-resources to manage the database connection
        try (Connection conn = DatabaseConnection.getConnection()) {
            YearMonth ym = YearMonth.of(calYear, calMonth);
            
            // 3. FETCH DATA
            // Holidays still come from EmployeeDAO
            List<Holiday> monthHolidays = employeeDAO.getHolidays(ym.atDay(1), ym.atEndOfMonth());
            List<Holiday> upcomingHolidays = employeeDAO.getHolidays(ym.atDay(1), ym.plusMonths(6).atDay(1));

            // NEW: Fetch leave balances using the dedicated LeaveBalanceDAO
            LeaveBalanceDAO lbDAO = new LeaveBalanceDAO(conn);
            List<LeaveBalance> balances = lbDAO.getEmployeeBalances(empId);

            // 4. SET ATTRIBUTES FOR JSP
            request.setAttribute("calYear", calYear);
            request.setAttribute("calMonth", calMonth);
            request.setAttribute("monthHolidays", monthHolidays);
            request.setAttribute("holidayUpcoming", upcomingHolidays);
            request.setAttribute("balances", balances);

            // 5. FORWARD TO JSP
            request.getRequestDispatcher("/employeeDashboard.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("dbError", "System Error: " + e.getMessage());
            request.getRequestDispatcher("/employeeDashboard.jsp").forward(request, response);
        }
    }

    private int parseInt(String s, int def) {
        try { return Integer.parseInt(s); } catch (Exception e) { return def; }
    }
}