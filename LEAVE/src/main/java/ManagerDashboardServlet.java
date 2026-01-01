import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * ManagerDashboardServlet
 * Fetches data for the manager's approval console.
 * Strictly restricted to users with the 'MANAGER' role.
 */
@WebServlet("/ManagerDashboardServlet")
public class ManagerDashboardServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        
        // 1. Role Security Check
        if (session == null || session.getAttribute("empid") == null ||
            !"MANAGER".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect("login.jsp?error=Unauthorized+Access");
            return;
        }

        List<Map<String, Object>> leaves = new ArrayList<>();
        int pendingCount = 0;
        int cancelReqCount = 0;

        SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy, HH:mm");
        
        try (Connection con = DatabaseConnection.getConnection()) {
            
            // 2. Fetch Detailed Leave Requests for Review
            // We join with USERS, LEAVE_TYPES, and LEAVE_STATUSES
            String sql = 
                "SELECT lr.*, u.FULLNAME, lt.TYPE_CODE as LEAVE_TYPE_NAME, ls.STATUS_CODE " +
                "FROM LEAVE_REQUESTS lr " +
                "JOIN USERS u ON lr.EMPID = u.EMPID " +
                "JOIN LEAVE_TYPES lt ON lr.LEAVE_TYPE_ID = lt.LEAVE_TYPE_ID " +
                "JOIN LEAVE_STATUSES ls ON lr.STATUS_ID = ls.STATUS_ID " +
                "WHERE ls.STATUS_CODE IN ('PENDING', 'CANCELLATION_REQUESTED') " +
                "ORDER BY lr.APPLIED_ON DESC";

            try (PreparedStatement ps = con.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {
                
                while (rs.next()) {
                    Map<String, Object> r = new HashMap<>();
                    r.put("leaveId", rs.getInt("LEAVE_ID"));
                    r.put("empid", rs.getInt("EMPID"));
                    r.put("fullname", rs.getString("FULLNAME"));
                    r.put("leaveType", rs.getString("LEAVE_TYPE_NAME"));
                    r.put("startDate", rs.getDate("START_DATE"));
                    r.put("endDate", rs.getDate("END_DATE"));
                 // Separate Days and Session Type for the split columns
                    r.put("duration", rs.getString("DURATION")); // e.g. FULL_DAY
                    r.put("days", rs.getDouble("DURATION_DAYS")); // e.g. 1.5
                    
                    r.put("reason", rs.getString("REASON"));
                    r.put("status", rs.getString("STATUS_CODE"));
                    
                    // Format the Applied On timestamp
                    Timestamp appliedTs = rs.getTimestamp("APPLIED_ON");
                    r.put("appliedOn", (appliedTs != null) ? sdf.format(appliedTs) : "-");
                    
                    
                    // Attachment check (Returns filename if exists)
                    String attachSql = "SELECT FILE_NAME FROM LEAVE_REQUEST_ATTACHMENTS WHERE LEAVE_ID = ?";
                    try (PreparedStatement psA = con.prepareStatement(attachSql)) {
                        psA.setInt(1, rs.getInt("LEAVE_ID"));
                        try (ResultSet rsA = psA.executeQuery()) {
                            if (rsA.next()) r.put("attachment", rsA.getString("FILE_NAME"));
                        }
                    }

                    // Consolidated Dynamic Attributes for the Modal
                    r.put("medicalFacility", rs.getString("MEDICAL_FACILITY"));
                    r.put("refSerialNo", rs.getString("REF_SERIAL_NO"));
                    r.put("eventDate", rs.getDate("EVENT_DATE"));
                    r.put("dischargeDate", rs.getDate("DISCHARGE_DATE"));
                    r.put("emergencyCategory", rs.getString("EMERGENCY_CATEGORY"));
                    r.put("emergencyContact", rs.getString("EMERGENCY_CONTACT"));
                    r.put("spouseName", rs.getString("SPOUSE_NAME"));

                    leaves.add(r);

                    // Increment counters
                    if ("PENDING".equals(rs.getString("STATUS_CODE"))) pendingCount++;
                    if ("CANCELLATION_REQUESTED".equals(rs.getString("STATUS_CODE"))) cancelReqCount++;
                }
            }

        } catch (Exception e) {
            request.setAttribute("error", "Data retrieval error: " + e.getMessage());
        }

        // 3. Set attributes and forward to Manager Dashboard
        request.setAttribute("leaves", leaves);
        request.setAttribute("pendingCount", pendingCount);
        request.setAttribute("cancelReqCount", cancelReqCount);
        
        request.getRequestDispatcher("/managerDashboard.jsp").forward(request, response);
    }
}