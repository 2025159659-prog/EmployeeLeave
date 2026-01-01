import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.InputStream;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * ApplyLeaveServlet - Production Version
 * Handles dynamic leave attributes and consolidated database mapping.
 */
@WebServlet("/ApplyLeaveServlet")
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,      // 1MB
        maxFileSize = 5L * 1024 * 1024,       // 5MB
        maxRequestSize = 6L * 1024 * 1024
)
public class ApplyLeaveServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private static final Set<String> ALLOWED_MIME = Set.of(
            "application/pdf",
            "image/png",
            "image/jpeg"
    );

    // Helper for URL encoding
    private String url(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }

    // Helper to check if a form parameter has actual content
    private boolean hasVal(String s) {
        return s != null && !s.trim().isEmpty();
    }

    private int getStatusId(Connection con, String statusCode) throws SQLException {
        String sql = "SELECT STATUS_ID FROM LEAVE_STATUSES WHERE UPPER(STATUS_CODE)=UPPER(?)";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, statusCode);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt("STATUS_ID");
            }
        }
        throw new SQLException("STATUS_CODE not found: " + statusCode);
    }

    private void ensureBalanceRow(Connection con, int empId, int leaveTypeId) throws SQLException {
        String merge =
                "MERGE INTO LEAVE_BALANCES b " +
                "USING (SELECT ? AS EMPID, ? AS LEAVE_TYPE_ID FROM dual) x " +
                "ON (b.EMPID = x.EMPID AND b.LEAVE_TYPE_ID = x.LEAVE_TYPE_ID) " +
                "WHEN NOT MATCHED THEN " +
                "  INSERT (EMPID, LEAVE_TYPE_ID, ENTITLEMENT, CARRIED_FWD, USED, PENDING, TOTAL) " +
                "  VALUES (?, ?, 0, 0, 0, 0, 0)";

        try (PreparedStatement ps = con.prepareStatement(merge)) {
            ps.setInt(1, empId);
            ps.setInt(2, leaveTypeId);
            ps.setInt(3, empId);
            ps.setInt(4, leaveTypeId);
            ps.executeUpdate();
        }
    }

    private void addPendingAndRecalcTotal(Connection con, int empId, int leaveTypeId, double pendingDays) throws SQLException {
        String upd =
                "UPDATE LEAVE_BALANCES " +
                "SET PENDING = NVL(PENDING,0) + ?, " +
                "    TOTAL   = (NVL(ENTITLEMENT,0) + NVL(CARRIED_FWD,0)) - (NVL(USED,0) + (NVL(PENDING,0) + ?)) " +
                "WHERE EMPID = ? AND LEAVE_TYPE_ID = ?";

        try (PreparedStatement ps = con.prepareStatement(upd)) {
            ps.setDouble(1, pendingDays);
            ps.setDouble(2, pendingDays);
            ps.setInt(3, empId);
            ps.setInt(4, leaveTypeId);

            int rows = ps.executeUpdate();
            if (rows == 0) throw new SQLException("LEAVE_BALANCES row missing.");
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("empid") == null) {
            response.sendRedirect("login.jsp?error=" + url("Please login."));
            return;
        }

        int empId = Integer.parseInt(String.valueOf(session.getAttribute("empid")));
        List<Map<String, Object>> leaveTypes = new ArrayList<>();
        String typeError = "";

        try (Connection con = DatabaseConnection.getConnection()) {
            
            // 1. Fetch Gender from Database and store in Session to ensure UI filtering is correct
            String empSql = "SELECT GENDER FROM USERS WHERE EMPID = ?";
            try (PreparedStatement ps = con.prepareStatement(empSql)) {
                ps.setInt(1, empId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String gender = rs.getString("GENDER"); 
                        session.setAttribute("gender", gender);
                    }
                }
            }

            // 2. Fetch all Leave Types
            String sqlTypes = "SELECT LEAVE_TYPE_ID, TYPE_CODE, DESCRIPTION FROM LEAVE_TYPES ORDER BY TYPE_CODE";
            try (PreparedStatement ps = con.prepareStatement(sqlTypes);
                 ResultSet rs = ps.executeQuery()) {

                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("id", rs.getInt("LEAVE_TYPE_ID"));
                    m.put("code", rs.getString("TYPE_CODE"));
                    m.put("desc", rs.getString("DESCRIPTION"));
                    leaveTypes.add(m);
                }
            }

        } catch (Exception e) {
            typeError = e.getMessage();
        }

        request.setAttribute("leaveTypes", leaveTypes);
        request.setAttribute("typeError", typeError);
        request.getRequestDispatcher("/applyLeave.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("empid") == null) {
            response.sendRedirect("login.jsp?error=" + url("Please login."));
            return;
        }

        int empId = Integer.parseInt(String.valueOf(session.getAttribute("empid")));
        Connection con = null;

        try {
            con = DatabaseConnection.getConnection();
            con.setAutoCommit(false);

            // 1. Refresh Gender in session from Database
            String empSql = "SELECT GENDER FROM USERS WHERE EMPID = ?";
            try (PreparedStatement ps = con.prepareStatement(empSql)) {
                ps.setInt(1, empId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String gender = rs.getString("GENDER");
                        session.setAttribute("gender", gender);
                    }
                }
            }

            // 2. Capture Basic Attributes
            String leaveTypeIdStr = request.getParameter("leaveTypeId");
            String durationUi = request.getParameter("duration"); 
            String startStr = request.getParameter("startDate");
            String endStr = request.getParameter("endDate");
            String reason = request.getParameter("reason");

            // 3. Capture Dynamic Attributes (Nullable from JSP)
            String clinicName = request.getParameter("clinicName");
            String hospitalName = request.getParameter("hospitalName");
            String maternityClinic = request.getParameter("maternityClinic");
            String hospitalLoc = request.getParameter("hospitalLocation");

            String mcSerial = request.getParameter("mcSerialNumber");
            String spouseIC = request.getParameter("spouseIC");
            String spouseName = request.getParameter("spouseName");

            String admissionDateStr = request.getParameter("admissionDate");
            String dischargeDateStr = request.getParameter("dischargeDate");
            String eddStr = request.getParameter("expectedDueDate");
            String delDateStr = request.getParameter("deliveryDate");

            String emgCat = request.getParameter("emergencyCategory");
            String emgContact = request.getParameter("emergencyContact");

            // 4. Consolidated Mapping Logic
            String medicalFacility = hasVal(clinicName) ? clinicName : 
                                    (hasVal(hospitalName) ? hospitalName : 
                                    (hasVal(maternityClinic) ? maternityClinic : 
                                    (hasVal(hospitalLoc) ? hospitalLoc : null)));
            
            String refSerialNo = hasVal(mcSerial) ? mcSerial : 
                                (hasVal(spouseIC) ? spouseIC : null);
            
            String eventDateStr = hasVal(admissionDateStr) ? admissionDateStr : 
                                 (hasVal(delDateStr) ? delDateStr : 
                                 (hasVal(eddStr) ? eddStr : null));

            // Validation
            if (!hasVal(leaveTypeIdStr) || !hasVal(startStr) || !hasVal(reason)) {
                response.sendRedirect("ApplyLeaveServlet?error=" + url("Fill in all mandatory fields."));
                return;
            }

            int leaveTypeId = Integer.parseInt(leaveTypeIdStr);
            boolean isHalf = "HALF_DAY_AM".equalsIgnoreCase(durationUi) || "HALF_DAY_PM".equalsIgnoreCase(durationUi);
            String halfSession = ("HALF_DAY_AM".equalsIgnoreCase(durationUi)) ? "AM" : (("HALF_DAY_PM".equalsIgnoreCase(durationUi)) ? "PM" : null);

            LocalDate startDate = LocalDate.parse(startStr);
            LocalDate endDate = isHalf ? startDate : LocalDate.parse(endStr);
            String durationDb = isHalf ? "HALF_DAY" : "FULL_DAY";
            double durationDays = isHalf ? 0.5 : (ChronoUnit.DAYS.between(startDate, endDate) + 1);

            // File handling
            Part filePart = request.getPart("attachment");
            boolean hasFile = (filePart != null && filePart.getSize() > 0);

            if (hasFile) {
                String mimeType = filePart.getContentType();
                if (mimeType == null || !ALLOWED_MIME.contains(mimeType)) {
                    response.sendRedirect("ApplyLeaveServlet?error=" + url("Invalid file type. Only PDF, PNG, JPG allowed."));
                    return;
                }
            }

            int pendingStatusId = getStatusId(con, "PENDING");

            // 5. INSERT INTO LEAVE_REQUESTS
            String insertLeave =
                    "INSERT INTO LEAVE_REQUESTS " +
                    "(EMPID, LEAVE_TYPE_ID, STATUS_ID, START_DATE, END_DATE, DURATION, DURATION_DAYS, APPLIED_ON, REASON, HALF_SESSION, " +
                    "MEDICAL_FACILITY, REF_SERIAL_NO, EVENT_DATE, DISCHARGE_DATE, EMERGENCY_CATEGORY, EMERGENCY_CONTACT, SPOUSE_NAME) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, SYSDATE, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

            int leaveId;
            try (PreparedStatement ps = con.prepareStatement(insertLeave, new String[]{"LEAVE_ID"})) {
                ps.setInt(1, empId);
                ps.setInt(2, leaveTypeId);
                ps.setInt(3, pendingStatusId);
                ps.setDate(4, java.sql.Date.valueOf(startDate));
                ps.setDate(5, java.sql.Date.valueOf(endDate));
                ps.setString(6, durationDb);
                ps.setDouble(7, durationDays);
                ps.setString(8, reason.trim());
                ps.setString(9, halfSession);
                
                ps.setString(10, medicalFacility);
                ps.setString(11, refSerialNo);
                ps.setDate(12, hasVal(eventDateStr) ? java.sql.Date.valueOf(eventDateStr) : null);
                ps.setDate(13, hasVal(dischargeDateStr) ? java.sql.Date.valueOf(dischargeDateStr) : null);
                ps.setString(14, emgCat);
                ps.setString(15, emgContact);
                ps.setString(16, spouseName);

                ps.executeUpdate();

                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (keys.next()) leaveId = keys.getInt(1);
                    else throw new SQLException("Generated ID failed.");
                }
            }

            // 6. ATTACHMENT
            if (hasFile) {
                String insertFile = "INSERT INTO LEAVE_REQUEST_ATTACHMENTS (LEAVE_ID, FILE_NAME, MIME_TYPE, FILE_SIZE, FILE_DATA, UPLOADED_ON) VALUES (?, ?, ?, ?, ?, SYSDATE)";
                try (PreparedStatement psFile = con.prepareStatement(insertFile);
                     InputStream in = filePart.getInputStream()) {
                    psFile.setInt(1, leaveId);
                    psFile.setString(2, filePart.getSubmittedFileName());
                    psFile.setString(3, filePart.getContentType());
                    psFile.setLong(4, filePart.getSize());
                    psFile.setBinaryStream(5, in);
                    psFile.executeUpdate();
                }
            }

            // 7. BALANCE UPDATES
            ensureBalanceRow(con, empId, leaveTypeId);
            addPendingAndRecalcTotal(con, empId, leaveTypeId, durationDays);

            con.commit();
            response.sendRedirect("ApplyLeaveServlet?msg=" + url("Request submitted successfully."));

        } catch (Exception e) {
            if (con != null) try { con.rollback(); } catch (SQLException ignore) {}
            response.sendRedirect("ApplyLeaveServlet?error=" + url("System Error: " + e.getMessage()));
        } finally {
            if (con != null) {
                try { con.setAutoCommit(true); con.close(); } catch (Exception ignore) {}
            }
        }
    }
}