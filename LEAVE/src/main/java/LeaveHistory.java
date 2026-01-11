import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.*;

import dao.LeaveDAO;

/**
 * Controller for viewing leave application history.
 * Updated to allow access for both EMPLOYEE and MANAGER roles.
 */
@WebServlet("/LeaveHistory")
public class LeaveHistory extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private final LeaveDAO leaveDAO = new LeaveDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 1. Session and Security Validation
        HttpSession session = request.getSession(false);
        String role = (session != null) ? String.valueOf(session.getAttribute("role")) : "";
        
        if (session == null || session.getAttribute("empid") == null ||
            (!"EMPLOYEE".equalsIgnoreCase(role) && !"MANAGER".equalsIgnoreCase(role))) {
            
            response.sendRedirect("login.jsp?error=" + url("Please login to access your leave history."));
            return;
        }

        int empId = Integer.parseInt(String.valueOf(session.getAttribute("empid")));
        String statusFilter = request.getParameter("status");
        String yearFilter = request.getParameter("year");

        try {
            // 2. Data Retrieval via DAO
            // Get years for the dropdown filter
            List<String> years = leaveDAO.getHistoryYears(empId);
            
            // Get filtered leave history list
            List<Map<String, Object>> leaves = leaveDAO.getLeaveHistory(empId, statusFilter, yearFilter);

            // 3. Set Attributes for JSP
            request.setAttribute("leaves", leaves);
            request.setAttribute("years", years);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Failed to load leave history: " + e.getMessage());
        }

        // 4. Forward to View (JSP)
        request.getRequestDispatcher("leaveHistory.jsp").forward(request, response);
    }

    /**
     * Helper to encode URL parameters safely.
     */
    private String url(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }
}