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

    // ✅ HANDLE GET (OPEN PAGE)
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("empid") == null) {
            response.sendRedirect("login.jsp?error=Session expired");
            return;
        }

        request.getRequestDispatcher("changePassword.jsp")
               .forward(request, response);
    }

    // ✅ HANDLE POST (UPDATE PASSWORD)
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

        if (currentPassword == null || newPassword == null || confirmPassword == null ||
            currentPassword.isEmpty() || newPassword.isEmpty() || confirmPassword.isEmpty()) {

            response.sendRedirect("ChangePassword?error=" +
                    url("All fields are required"));
            return;
        }

        if (!newPassword.equals(confirmPassword)) {
            response.sendRedirect("ChangePassword?error=" +
                    url("Passwords do not match"));
            return;
        }

        try (Connection con = DatabaseConnection.getConnection()) {

            String dbPassword = null;

            try (PreparedStatement ps = con.prepareStatement("""
                SELECT password FROM leave.users WHERE empid = ?
            """)) {
                ps.setInt(1, empId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        dbPassword = rs.getString("password");
                    }
                }
            }

            if (dbPassword == null || !dbPassword.equals(currentPassword)) {
                response.sendRedirect("ChangePassword?error=" +
                        url("Current password is incorrect"));
                return;
            }

            try (PreparedStatement ps = con.prepareStatement("""
                UPDATE leave.users SET password = ? WHERE empid = ?
            """)) {
                ps.setString(1, newPassword);
                ps.setInt(2, empId);
                ps.executeUpdate();
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
