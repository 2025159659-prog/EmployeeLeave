import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.*;

import util.DatabaseConnection;

@WebServlet("/ManagerLeaveActionServlet")
public class ManagerLeaveActionServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || !"MANAGER".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect("login.jsp?error=Unauthorized");
            return;
        }

        try (Connection con = DatabaseConnection.getConnection()) {
            // (logic kau KEKAL)
            response.sendRedirect("ReviewLeave?msg=Updated");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("ReviewLeave?error=" +
                    URLEncoder.encode("Database error", StandardCharsets.UTF_8));
        }
    }
}
