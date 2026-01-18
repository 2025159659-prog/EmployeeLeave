import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import util.DatabaseConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email = request.getParameter("email");
        String password = request.getParameter("password");

        if (email == null || password == null || email.isBlank() || password.isBlank()) {
            response.sendRedirect("login.jsp?error=" + url("Please enter email and password."));
            return;
        }

        String sql = """
                    SELECT empid, fullname, role, status
                    FROM leave.users
                    WHERE email = ? AND password = ?
                """;



        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, email.trim());
            ps.setString(2, password);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {

                    String status = rs.getString("STATUS");
                    if ("INACTIVE".equalsIgnoreCase(status)) {
                        response.sendRedirect("login.jsp?error=" +
                                url("Your account is deactivated. Please contact admin."));
                        return;
                    }

                    HttpSession session = request.getSession(true);
                    session.setAttribute("empid", rs.getInt("EMPID"));
                    session.setAttribute("fullname", rs.getString("FULLNAME"));
                    session.setAttribute("role", rs.getString("ROLE"));

                    String role = rs.getString("ROLE");
                    if ("ADMIN".equalsIgnoreCase(role)) {
                        response.sendRedirect("AdminDashboard");
                    } else if ("MANAGER".equalsIgnoreCase(role)) {
                        response.sendRedirect("ReviewLeave");
                    } else {
                        response.sendRedirect("EmployeeDashboard");
                    }
                } else {
                    response.sendRedirect("login.jsp?error=" + url("Invalid email or password."));
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("login.jsp?error=" + url("Login error. Please try again."));
        }
    }

    private String url(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }
}


