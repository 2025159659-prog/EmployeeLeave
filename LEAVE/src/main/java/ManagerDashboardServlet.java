import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.sql.Date;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * ManagerDashboardServlet
 * Restricted to MANAGER role.
 * Fetches all PENDING and CANCELLATION_REQUESTED leave applications.
 * Formats all dates and timestamps to DD/MM/YYYY format.
 */
@WebServlet("/ManagerDashboardServlet")
public class ManagerDashboardServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        // Strict Security Guard
        if (session == null || session.getAttribute("empid") == null ||
            !"MANAGER".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect("login.jsp?error=Unauthorized+Access");
            return;
        }

        List<Map<String, Object>> leaves = new ArrayList<>();
        int pendingCount = 0;
        int cancelReqCount = 0;
        
        // Date Formatters for DD/MM/YYYY
        SimpleDateFormat sdfTime = new SimpleDateFormat("dd/MM/yyyy HH:mm");
        SimpleDateFormat sdfDate = new SimpleDateFormat("dd/MM/yyyy");

        try (Connection con = DatabaseConnection.getConnection()) {
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
                    int leaveId = rs.getInt("LEAVE_ID");
                    r.put("leaveId", leaveId);
                    r.put("empid", rs.getInt("EMPID"));
                    r.put("fullname", rs.getString("FULLNAME"));
                    r.put("leaveType", rs.getString("LEAVE_TYPE_NAME"));
                    
                    // Format Start and End Dates
                    Date start = rs.getDate("START_DATE");
                    Date end = rs.getDate("END_DATE");
                    r.put("startDate", (start != null) ? sdfDate.format(start) : "-");
                    r.put("endDate", (end != null) ? sdfDate.format(end) : "-");
                    
                    r.put("duration", rs.getString("DURATION")); 
                    r.put("days", rs.getDouble("DURATION_DAYS"));
                    r.put("reason", rs.getString("REASON"));
                    r.put("status", rs.getString("STATUS_CODE"));
                    
                    // Format Applied On Timestamp
                    Timestamp appliedTs = rs.getTimestamp("APPLIED_ON");
                    r.put("appliedOn", (appliedTs != null) ? sdfTime.format(appliedTs) : "-");
                    
                    // Dynamic Attributes
                    r.put("medicalFacility", rs.getString("MEDICAL_FACILITY"));
                    r.put("refSerialNo", rs.getString("REF_SERIAL_NO"));
                    
                    // Format Dynamic Dates
                    Date evt = rs.getDate("EVENT_DATE");
                    Date dis = rs.getDate("DISCHARGE_DATE");
                    r.put("eventDate", (evt != null) ? sdfDate.format(evt) : "");
                    r.put("dischargeDate", (dis != null) ? sdfDate.format(dis) : "");
                    
                    r.put("emergencyCategory", rs.getString("EMERGENCY_CATEGORY"));
                    r.put("emergencyContact", rs.getString("EMERGENCY_CONTACT"));
                    r.put("spouseName", rs.getString("SPOUSE_NAME"));

                    // Check for attachment
                    try (PreparedStatement psA = con.prepareStatement("SELECT FILE_NAME FROM LEAVE_REQUEST_ATTACHMENTS WHERE LEAVE_ID = ?")) {
                        psA.setInt(1, leaveId);
                        try (ResultSet rsA = psA.executeQuery()) {
                            if (rsA.next()) r.put("attachment", rsA.getString("FILE_NAME"));
                        }
                    }

                    leaves.add(r);
                    if ("PENDING".equals(rs.getString("STATUS_CODE"))) pendingCount++;
                    else cancelReqCount++;
                }
            }
        } catch (Exception e) {
            request.setAttribute("error", "Database Error: " + e.getMessage());
        }

        request.setAttribute("leaves", leaves);
        request.setAttribute("pendingCount", pendingCount);
        request.setAttribute("cancelReqCount", cancelReqCount);
        request.getRequestDispatcher("/managerDashboard.jsp").forward(request, response);
    }
}