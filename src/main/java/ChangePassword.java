import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.*;

import util.DatabaseConnection;

@WebServlet("/ChangePassword")
public class ChangePassword extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

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

        if (!newPass.equals(confirmPass)) {
            response.sendRedirect("ChangePassword?error=" + url("Passwords do not match."));
            return;
        }

        try (Connection con = DatabaseConnection.getConnection()) {

            String checkSql = "SELECT PASSWORD FROM USERS WHERE EMPID=?";
            try (PreparedStatement ps = con.prepareStatement(checkSql)) {
                ps.setInt(1, empid);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next() && !rs.getString("PASSWORD").equals(oldPass)) {
                        response.sendRedirect("ChangePassword?error=" + url("Incorrect password."));
                        return;
                    }
                }
            }

            String updateSql = "UPDATE USERS SET PASSWORD=? WHERE EMPID=?";
            try (PreparedStatement ps = con.prepareStatement(updateSql)) {
                ps.setString(1, newPass);
                ps.setInt(2, empid);
                ps.executeUpdate();
            }

            response.sendRedirect("ChangePassword?msg=" + url("Password updated."));

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("ChangePassword?error=" + url("Database error."));
        }
    }

    private String url(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }
}
