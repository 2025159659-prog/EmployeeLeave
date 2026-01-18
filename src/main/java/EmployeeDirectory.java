import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.*;
import java.util.*;

import util.DatabaseConnection;

@WebServlet("/EmployeeDirectory")
public class EmployeeDirectory extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect("login.jsp?error=Admin+only");
            return;
        }

        List<Map<String, Object>> users = new ArrayList<>();

        // ✅ FIX: ambil SEMUA role (ADMIN, MANAGER, EMPLOYEE)
        String sql = """
            SELECT empid, fullname, email, role, phoneno, hiredate, status
            FROM leave.users
            WHERE status = 'ACTIVE'
            ORDER BY 
                CASE role
                    WHEN 'ADMIN' THEN 1
                    WHEN 'MANAGER' THEN 2
                    WHEN 'EMPLOYEE' THEN 3
                    ELSE 4
                END,
                fullname
        """;

        try (Connection con = DatabaseConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> u = new HashMap<>();
                u.put("empid", rs.getInt("empid"));
                u.put("fullname", rs.getString("fullname"));
                u.put("email", rs.getString("email"));
                u.put("role", rs.getString("role"));
                u.put("phone", rs.getString("phoneno"));
                u.put("hiredate", rs.getDate("hiredate"));
                u.put("status", rs.getString("status"));
                users.add(u);
            }

        } catch (Exception e) {
            throw new ServletException(e);
        }

        request.setAttribute("users", users);
        request.getRequestDispatcher("employeeDirectory.jsp").forward(request, response);
    }
}
