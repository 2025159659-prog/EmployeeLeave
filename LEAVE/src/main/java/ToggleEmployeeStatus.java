import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.*;

@WebServlet("/ToggleEmployeeStatus")
public class ToggleEmployeeStatus extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 1. Security Check: Ensure only Admins can toggle status
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("role") == null ||
                !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect("login.jsp?error=" + url("Unauthorized access."));
            return;
        }

        // 2. Retrieve Parameters
        String empIdStr = request.getParameter("empid");
        String targetStatus = request.getParameter("targetStatus"); // Expected: "ACTIVE" or "INACTIVE"

        if (empIdStr == null || targetStatus == null) {
            response.sendRedirect("EmployeeDirectory?error=" + url("Invalid request parameters."));
            return;
        }

        // 3. Update Database
        String sql = "UPDATE USERS SET STATUS = ? WHERE EMPID = ? AND ROLE != 'ADMIN'";

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setString(1, targetStatus.toUpperCase());
            ps.setInt(2, Integer.parseInt(empIdStr));

            int rowsUpdated = ps.executeUpdate();

            if (rowsUpdated > 0) {
                String action = "ACTIVE".equals(targetStatus) ? "reactivated" : "deactivated";
                response.sendRedirect("EmployeeDirectory?msg=" + url("Employee account " + action + " successfully."));
            } else {
                response.sendRedirect("EmployeeDirectory?error=" + url("Failed to update status. Root admin accounts cannot be modified."));
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("EmployeeDirectory?error=" + url("Database error: " + e.getMessage()));
        }
    }

    private String url(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }
}