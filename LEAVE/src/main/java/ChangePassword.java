import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.*;

@WebServlet("/ChangePassword")
public class ChangePassword extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Security Check
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("empid") == null) {
            response.sendRedirect("login.jsp?error=Please login.");
            return;
        }

        request.getRequestDispatcher("changePassword.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("empid") == null) {
            response.sendRedirect("login.jsp?error=Please login.");
            return;
        }

        int empid = (Integer) session.getAttribute("empid");
        String oldPass = request.getParameter("oldPassword");
        String newPass = request.getParameter("newPassword");
        String confirmPass = request.getParameter("confirmPassword");

        // 1. Validation: Match
        if (newPass == null || !newPass.equals(confirmPass)) {
            response.sendRedirect("ChangePassword?error=" + url("New passwords do not match."));
            return;
        }

        // 2. Database Logic
        try (Connection con = DatabaseConnection.getConnection()) {
            // Verify Old Password
            String checkSql = "SELECT PASSWORD FROM USERS WHERE EMPID = ?";
            try (PreparedStatement psCheck = con.prepareStatement(checkSql)) {
                psCheck.setInt(1, empid);
                try (ResultSet rs = psCheck.executeQuery()) {
                    if (rs.next()) {
                        String dbPass = rs.getString("PASSWORD");
                        if (!dbPass.equals(oldPass)) {
                            response.sendRedirect("ChangePassword?error=" + url("Incorrect current password."));
                            return;
                        }
                    }
                }
            }

            // Update to New Password
            String updateSql = "UPDATE USERS SET PASSWORD = ? WHERE EMPID = ?";
            try (PreparedStatement psUpdate = con.prepareStatement(updateSql)) {
                psUpdate.setString(1, newPass);
                psUpdate.setInt(2, empid);
                psUpdate.executeUpdate();
                response.sendRedirect("ChangePassword?msg=" + url("Password updated successfully."));
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("ChangePassword?error=" + url("Database error occurred."));
        }
    }

    private String url(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }
}