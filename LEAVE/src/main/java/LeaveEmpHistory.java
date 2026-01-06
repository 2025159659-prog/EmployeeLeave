import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.sql.Date;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * LeaveEmpHistoryServlet
 * Restricted to ADMIN role.
 * Fetches all leave records with full dynamic attributes for administrative viewing.
 */
@WebServlet("/leaveEmpHistory")
public class LeaveEmpHistory extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("empid") == null ||
            !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect("login.jsp?error=Unauthorized+Access");
            return;
        }

        String statusFilter = request.getParameter("status");
        String yearFilter = request.getParameter("year");

        List<Map<String, Object>> history = new ArrayList<>();
        List<String> years = new ArrayList<>();
        
        SimpleDateFormat sdfDate = new SimpleDateFormat("dd/MM/yyyy");
        SimpleDateFormat sdfTime = new SimpleDateFormat("dd/MM/yyyy HH:mm");

        try (Connection con = DatabaseConnection.getConnection()) {
            
            // 1. Fetch years for the filter
            String yearSql = "SELECT DISTINCT EXTRACT(YEAR FROM START_DATE) AS YR FROM LEAVE_REQUESTS ORDER BY YR DESC";
            try (PreparedStatement psYear = con.prepareStatement(yearSql);
                 ResultSet rsYear = psYear.executeQuery()) {
                while (rsYear.next()) years.add(rsYear.getString("YR"));
            }

            // 2. Query including ALL metadata columns
            StringBuilder sql = new StringBuilder();
            sql.append("SELECT lr.*, u.FULLNAME, u.EMPID as EMP_CODE, lt.TYPE_CODE, ls.STATUS_CODE ")
               .append("FROM LEAVE_REQUESTS lr ")
               .append("JOIN USERS u ON lr.EMPID = u.EMPID ")
               .append("JOIN LEAVE_TYPES lt ON lr.LEAVE_TYPE_ID = lt.LEAVE_TYPE_ID ")
               .append("JOIN LEAVE_STATUSES ls ON lr.STATUS_ID = ls.STATUS_ID ")
               .append("WHERE 1=1 ");

            if (statusFilter != null && !statusFilter.isBlank() && !"ALL".equalsIgnoreCase(statusFilter)) {
                sql.append(" AND UPPER(ls.STATUS_CODE) = ? ");
            }
            if (yearFilter != null && !yearFilter.isBlank()) {
                sql.append(" AND EXTRACT(YEAR FROM lr.START_DATE) = ? ");
            }
            sql.append(" ORDER BY lr.APPLIED_ON DESC");

            try (PreparedStatement ps = con.prepareStatement(sql.toString())) {
                int idx = 1;
                if (statusFilter != null && !statusFilter.isBlank() && !"ALL".equalsIgnoreCase(statusFilter)) {
                    ps.setString(idx++, statusFilter.trim().toUpperCase());
                }
                if (yearFilter != null && !yearFilter.isBlank()) {
                    ps.setInt(idx++, Integer.parseInt(yearFilter));
                }

                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String, Object> r = new HashMap<>();
                        r.put("id", rs.getInt("LEAVE_ID"));
                        r.put("fullname", rs.getString("FULLNAME"));
                        r.put("empCode", rs.getString("EMP_CODE"));
                        r.put("type", rs.getString("TYPE_CODE"));
                        r.put("status", rs.getString("STATUS_CODE"));
                        r.put("days", rs.getDouble("DURATION_DAYS"));
                        r.put("duration", rs.getString("DURATION")); 
                        
                        // Main Dates
                        r.put("start", sdfDate.format(rs.getDate("START_DATE")));
                        r.put("end", sdfDate.format(rs.getDate("END_DATE")));
                        r.put("appliedOn", sdfTime.format(rs.getTimestamp("APPLIED_ON")));
                        
                        r.put("reason", rs.getString("REASON"));
                        r.put("adminComment", rs.getString("ADMIN_COMMENT"));
                        
                        // Dynamic Meta Attributes
                        r.put("medicalFacility", rs.getString("MEDICAL_FACILITY"));
                        r.put("refSerialNo", rs.getString("REF_SERIAL_NO"));
                        
                        Date evtDate = rs.getDate("EVENT_DATE");
                        r.put("eventDate", (evtDate != null) ? sdfDate.format(evtDate) : "");
                        
                        Date disDate = rs.getDate("DISCHARGE_DATE");
                        r.put("dischargeDate", (disDate != null) ? sdfDate.format(disDate) : "");
                        
                        r.put("emergencyCategory", rs.getString("EMERGENCY_CATEGORY"));
                        r.put("emergencyContact", rs.getString("EMERGENCY_CONTACT"));
                        r.put("spouseName", rs.getString("SPOUSE_NAME"));

                        // Attachment check
                        try (PreparedStatement psA = con.prepareStatement("SELECT FILE_NAME FROM LEAVE_REQUEST_ATTACHMENTS WHERE LEAVE_ID = ?")) {
                            psA.setInt(1, rs.getInt("LEAVE_ID"));
                            try (ResultSet rsA = psA.executeQuery()) {
                                if (rsA.next()) r.put("attachment", rsA.getString("FILE_NAME"));
                            }
                        }
                        history.add(r);
                    }
                }
            }
        } catch (Exception e) {
            request.setAttribute("error", e.getMessage());
        }

        request.setAttribute("history", history);
        request.setAttribute("years", years);
        request.getRequestDispatcher("/leaveEmpHistory.jsp").forward(request, response);
    }
}

