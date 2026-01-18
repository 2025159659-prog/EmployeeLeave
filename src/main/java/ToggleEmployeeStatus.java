import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;

import util.DatabaseConnection;

@WebServlet("/ToggleEmployeeStatus")
public class ToggleEmployeeStatus extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect("login.jsp?error=Unauthorized");
            return;
        }

        int adminEmpId = Integer.parseInt(String.valueOf(session.getAttribute("empid")));
        int targetEmpId = Integer.parseInt(request.getParameter("empid"));
        String targetStatus = request.getParameter("targetStatus");

        // ❌ Safety: admin tak boleh deactivate diri sendiri
        if (adminEmpId == targetEmpId) {
            response.sendRedirect("EmployeeDirectory?error=" +
                    url("You cannot change your own status"));
            return;
        }

        String sql = """
            UPDATE leave.users
            SET status = ?
            WHERE empid = ?
              AND role <> 'ADMIN'
        """;

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, targetStatus);
            ps.setInt(2, targetEmpId);

            int updated = ps.executeUpdate();

            if (updated == 0) {
                response.sendRedirect("EmployeeDirectory?error=" +
                        url("Unable to update employee status"));
                return;
            }

            response.sendRedirect("EmployeeDirectory?msg=" +
                    url("Status updated successfully"));

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("EmployeeDirectory?error=" +
                    url("Database error"));
        }
    }

    private String url(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }
}
