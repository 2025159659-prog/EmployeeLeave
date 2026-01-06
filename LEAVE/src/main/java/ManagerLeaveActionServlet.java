import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.*;

@WebServlet("/ManagerLeaveActionServlet")
public class ManagerLeaveActionServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("empid") == null ||
            !"MANAGER".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect("login.jsp?error=Unauthorized");
            return;
        }

        String leaveIdStr = request.getParameter("leaveId");
        String action = request.getParameter("action"); 
        String comment = request.getParameter("comment");

        if (leaveIdStr == null || action == null) {
            response.sendRedirect("ManagerDashboardServlet?error=Invalid+Request");
            return;
        }

        int leaveId = Integer.parseInt(leaveIdStr);
        try (Connection con = DatabaseConnection.getConnection()) {
            con.setAutoCommit(false);

            // Fetch basic details for balance restoration logic
            int empId = 0; int typeId = 0; double days = 0;
            try (PreparedStatement ps = con.prepareStatement("SELECT EMPID, LEAVE_TYPE_ID, DURATION_DAYS FROM LEAVE_REQUESTS WHERE LEAVE_ID=?")) {
                ps.setInt(1, leaveId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) { empId = rs.getInt(1); typeId = rs.getInt(2); days = rs.getDouble(3); }
                }
            }

            String finalStatus = "";
            String balSql = "";

            // Mapping Decision logic
            if ("APPROVE".equals(action)) {
                finalStatus = "APPROVED";
                balSql = "UPDATE LEAVE_BALANCES SET PENDING = PENDING - ?, USED = USED + ? WHERE EMPID = ? AND LEAVE_TYPE_ID = ?";
            } else if ("REJECT".equals(action)) {
                finalStatus = "REJECTED";
                balSql = "UPDATE LEAVE_BALANCES SET PENDING = PENDING - ?, TOTAL = TOTAL + ? WHERE EMPID = ? AND LEAVE_TYPE_ID = ?";
            } else if ("APPROVE_CANCEL".equals(action)) {
                finalStatus = "CANCELLED";
                balSql = "UPDATE LEAVE_BALANCES SET USED = USED - ?, TOTAL = TOTAL + ? WHERE EMPID = ? AND LEAVE_TYPE_ID = ?";
            } else if ("REJECT_CANCEL".equals(action)) {
                finalStatus = "APPROVED"; // No balance change, just maintain approval
            }

            // Update Request Status
            String updSql = "UPDATE LEAVE_REQUESTS SET STATUS_ID = (SELECT STATUS_ID FROM LEAVE_STATUSES WHERE STATUS_CODE=?), ADMIN_COMMENT=? WHERE LEAVE_ID=?";
            try (PreparedStatement ps = con.prepareStatement(updSql)) {
                ps.setString(1, finalStatus); ps.setString(2, comment); ps.setInt(3, leaveId);
                ps.executeUpdate();
            }

            // Update Balance logic
            if (!balSql.isEmpty()) {
                try (PreparedStatement ps = con.prepareStatement(balSql)) {
                    ps.setDouble(1, days); ps.setDouble(2, days); ps.setInt(3, empId); ps.setInt(4, typeId);
                    ps.executeUpdate();
                }
            }

            con.commit();
            String msg = URLEncoder.encode("Leave " + finalStatus.toLowerCase() + " successfully.", StandardCharsets.UTF_8);
            response.sendRedirect("ManagerDashboardServlet?msg=" + msg);
        } catch (Exception e) {
            response.sendRedirect("ManagerDashboardServlet?error=" + URLEncoder.encode(e.getMessage(), StandardCharsets.UTF_8));
        }
    }
}