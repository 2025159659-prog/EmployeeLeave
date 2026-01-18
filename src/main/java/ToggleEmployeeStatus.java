import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.*;

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

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "UPDATE USERS SET STATUS=? WHERE EMPID=? AND ROLE!='ADMIN'")) {

            ps.setString(1, request.getParameter("targetStatus"));
            ps.setInt(2, Integer.parseInt(request.getParameter("empid")));
            ps.executeUpdate();

            response.sendRedirect("EmployeeDirectory?msg=" +
                    url("Status updated"));

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("EmployeeDirectory?error=" + url("Database error"));
        }
    }

    private String url(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }
}
