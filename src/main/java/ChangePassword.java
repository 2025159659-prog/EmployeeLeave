import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import util.DatabaseConnection;

@WebServlet("/ChangePassword")
public class ChangePassword extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("empid") == null) {
            response.sendRedirect("login.jsp?error=Session expired");
            return;
        }

        int empId = Integer.parseInt(String.valueOf(session.getAttribute("empid")));
        String currentPassword = request.getParameter("currentPassword");
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        // 🔒 Basic validation
        if (currentPassword == null || newPassword == null || confirmPassword == null ||
            currentPassword.isEmpty() || newPassword.isEmpty() || confirmPassword.isEmpty()) {

            response.sendRedirect("ChangePassword?error=" + url("All fields are required"));
            return;
        }

        if (!newPassword.equals(confirmPassword)) {
            response.sendRedirect("ChangePassword?error=" + url("Passwords do not match"));
            return;
        }

        try (Connection con = DatabaseConnection.getConnection()) {

            // 1️⃣ Verify current password
            String checkSql = """
                SELECT password
                FROM leave.users
                WHERE empid = ?
            """;

            String dbPassword = null;

            try (PreparedStatement ps = con.prepareStatement(checkSql)) {
                ps.setInt(1, empId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        dbPassword = rs.getString("password");
                    } else {
                        response.sendRedirect("ChangePassword?error=" +
                                url("User not found"));
                        return;
                    }
                }
            }

            if (!currentPassword.equals(dbPassword)) {
                response.sendRedirect("ChangePassword?error=" +
                        url("Current password is incorrect"));
                return;
            }

            // 2️⃣ Update password
            String updateSql = """
                UPDATE leave.users
                SET password = ?
                WHERE empid = ?
            """;

            try (PreparedStatement ps = con.prepareStatement(updateSql)) {
                ps.setString(1, newPassword);
                ps.setInt(2, empId);

                int updated = ps.executeUpdate();

                if (updated == 0) {
                    response.sendRedirect("ChangePassword?error=" +
                            url("Unable to update password"));
                    return;
                }
            }

            response.sendRedirect("ChangePassword?msg=" +
                    url("Password updated successfully"));

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("ChangePassword?error=" +
                    url("Database error"));
        }
    }

    private String url(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }
}
