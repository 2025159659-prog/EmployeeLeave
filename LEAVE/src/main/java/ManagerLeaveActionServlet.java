import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.*;

/**
 * ManagerLeaveActionServlet
 * Processes leave approval, rejection, and cancellation decisions.
 * Strictly enforced for MANAGER role only.
 */
@WebServlet("/ManagerLeaveActionServlet")
public class ManagerLeaveActionServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        
        // STRICT ROLE CHECK - Only Managers allowed
        if (session == null || session.getAttribute("empid") == null ||
            !"MANAGER".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect("login.jsp?error=Unauthorized+Access");
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
        Connection con = null;

        try {
            con = DatabaseConnection.getConnection();
            con.setAutoCommit(false);

            // 1. Fetch Leave Request Details for Balance Update
            int empId = 0;
            int leaveTypeId = 0;
            double durationDays = 0;
            String fetchSql = "SELECT EMPID, LEAVE_TYPE_ID, DURATION_DAYS FROM LEAVE_REQUESTS WHERE LEAVE_ID = ?";
            try (PreparedStatement ps = con.prepareStatement(fetchSql)) {
                ps.setInt(1, leaveId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        empId = rs.getInt("EMPID");
                        leaveTypeId = rs.getInt("LEAVE_TYPE_ID");
                        durationDays = rs.getDouble("DURATION_DAYS");
                    } else {
                        throw new SQLException("Leave record not found.");
                    }
                }
            }

            String finalStatus = "";
            String balanceUpdateSql = "";

            // Decision Logic
            switch (action) {
                case "APPROVE":
                    finalStatus = "APPROVED";
                    // Transition: Move from PENDING to USED
                    balanceUpdateSql = "UPDATE LEAVE_BALANCES SET PENDING = PENDING - ?, USED = USED + ? WHERE EMPID = ? AND LEAVE_TYPE_ID = ?";
                    break;

                case "REJECT":
                    finalStatus = "REJECTED";
                    // Transition: Remove from PENDING, restore balance to TOTAL
                    balanceUpdateSql = "UPDATE LEAVE_BALANCES SET PENDING = PENDING - ?, TOTAL = TOTAL + ? WHERE EMPID = ? AND LEAVE_TYPE_ID = ?";
                    break;

                case "APPROVE_CANCEL":
                    finalStatus = "CANCELLED";
                    // Transition: Remove from USED, restore balance to TOTAL
                    balanceUpdateSql = "UPDATE LEAVE_BALANCES SET USED = USED - ?, TOTAL = TOTAL + ? WHERE EMPID = ? AND LEAVE_TYPE_ID = ?";
                    break;

                case "REJECT_CANCEL":
                    finalStatus = "APPROVED"; 
                    // No balance change needed, the request stays approved.
                    break;

                default:
                    throw new SQLException("Invalid Action Type Received");
            }

            // 2. Update Leave Request Status and Manager's Comment
            String updateLeaveSql = "UPDATE LEAVE_REQUESTS SET STATUS_ID = (SELECT STATUS_ID FROM LEAVE_STATUSES WHERE STATUS_CODE = ?), ADMIN_COMMENT = ? WHERE LEAVE_ID = ?";
            try (PreparedStatement ps = con.prepareStatement(updateLeaveSql)) {
                ps.setString(1, finalStatus);
                ps.setString(2, (comment != null ? comment.trim() : ""));
                ps.setInt(3, leaveId);
                ps.executeUpdate();
            }

            // 3. Apply Balance Updates (Except for Rejected Cancellations)
            if (!action.equals("REJECT_CANCEL") && !balanceUpdateSql.isEmpty()) {
                try (PreparedStatement psUpd = con.prepareStatement(balanceUpdateSql)) {
                    psUpd.setDouble(1, durationDays);
                    psUpd.setDouble(2, durationDays);
                    psUpd.setInt(3, empId);
                    psUpd.setInt(4, leaveTypeId);
                    psUpd.executeUpdate();
                }
            }

            con.commit();
            response.sendRedirect("ManagerDashboardServlet?msg=" + URLEncoder.encode("Leave " + finalStatus.toLowerCase() + " updated successfully.", StandardCharsets.UTF_8));

        } catch (Exception e) {
            if (con != null) try { con.rollback(); } catch (SQLException ignore) {}
            response.sendRedirect("ManagerDashboardServlet?error=" + URLEncoder.encode("Processing error: " + e.getMessage(), StandardCharsets.UTF_8));
        } finally {
            if (con != null) try { con.setAutoCommit(true); con.close(); } catch (SQLException ignore) {}
        }
    }
}