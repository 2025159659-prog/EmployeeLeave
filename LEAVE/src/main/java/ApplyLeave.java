import bean.LeaveRequest;
import dao.LeaveDAO;
import dao.EmployeeDAO;
import util.DatabaseConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDate;
import java.util.*;

@WebServlet("/ApplyLeave")
@MultipartConfig(fileSizeThreshold = 1024 * 1024, maxFileSize = 5L * 1024 * 1024, maxRequestSize = 6L * 1024 * 1024)
public class ApplyLeave extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private LeaveDAO leaveDAO = new LeaveDAO();
    private EmployeeDAO employeeDAO = new EmployeeDAO(); 

    private String url(String s) { return URLEncoder.encode(s, StandardCharsets.UTF_8); }
    private boolean hasVal(String s) { return s != null && !s.trim().isEmpty(); }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        String role = (session != null) ? String.valueOf(session.getAttribute("role")) : "";
        
        if (session == null || session.getAttribute("empid") == null || 
            (!"EMPLOYEE".equalsIgnoreCase(role) && !"MANAGER".equalsIgnoreCase(role))) {
            response.sendRedirect("login.jsp?error=" + url("Please login."));
            return;
        }

        try {
            int empId = Integer.parseInt(String.valueOf(session.getAttribute("empid")));
            
            // Refresh Gender from DB to handle gender-specific leave restrictions dynamically
            try (Connection con = DatabaseConnection.getConnection()) {
                String sql = "SELECT GENDER FROM USERS WHERE EMPID = ?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setInt(1, empId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            String dbGender = rs.getString("GENDER");
                            session.setAttribute("gender", (dbGender != null) ? dbGender.trim().toUpperCase() : "");
                        }
                    }
                }
            }

            request.setAttribute("leaveTypes", leaveDAO.getAllLeaveTypes());
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("typeError", "System Error: " + e.getMessage());
        }
        request.getRequestDispatcher("/applyLeave.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("empid") == null) {
            response.sendRedirect("login.jsp?error=" + url("Session expired."));
            return;
        }

        try {
            int empId = Integer.parseInt(String.valueOf(session.getAttribute("empid")));
            LeaveRequest lr = new LeaveRequest();
            lr.setEmpId(empId);
            lr.setLeaveTypeId(Integer.parseInt(request.getParameter("leaveTypeId")));
            lr.setReason(request.getParameter("reason"));

            // Handle Duration UI values (FULL_DAY, HALF_DAY_AM, HALF_DAY_PM)
            String durationUi = request.getParameter("duration");
            boolean isHalf = "HALF_DAY_AM".equalsIgnoreCase(durationUi) || "HALF_DAY_PM".equalsIgnoreCase(durationUi);
            
            lr.setStartDate(LocalDate.parse(request.getParameter("startDate")));
            lr.setEndDate(isHalf ? lr.getStartDate() : LocalDate.parse(request.getParameter("endDate")));
            lr.setDuration(isHalf ? "HALF_DAY" : "FULL_DAY");
            lr.setHalfSession(isHalf ? (durationUi.contains("AM") ? "AM" : "PM") : null);

            double days = isHalf ? 0.5 : leaveDAO.calculateWorkingDays(lr.getStartDate(), lr.getEndDate());
            if (days <= 0) {
                response.sendRedirect("ApplyLeave?error=" + url("Invalid dates selected."));
                return;
            }
            lr.setDurationDays(days);

            // ========================================================
            // ROBUST METADATA MAPPING (Capturing shared field inputs)
            // ========================================================
            
            // 1. Mapping MEDICAL_FACILITY (Clinic / Hospital / Location)
            String facility = request.getParameter("clinicName");
            if (!hasVal(facility)) facility = request.getParameter("hospitalName");
            if (!hasVal(facility)) facility = request.getParameter("maternityClinic");
            if (!hasVal(facility)) facility = request.getParameter("hospitalLocation");
            lr.setMedicalFacility(facility);

            // 2. Mapping REF_SERIAL_NO (MC Number / Reference Serial)
            lr.setRefSerialNo(request.getParameter("mcSerialNumber"));

            // 3. Mapping EVENT_DATE (Admission Date / Due Date / Delivery Date)
            String eventDateStr = request.getParameter("admissionDate");
            if (!hasVal(eventDateStr)) eventDateStr = request.getParameter("expectedDueDate");
            if (!hasVal(eventDateStr)) eventDateStr = request.getParameter("deliveryDate");
            
            if (hasVal(eventDateStr)) {
                lr.setEventDate(LocalDate.parse(eventDateStr));
            }

            // 4. Mapping DISCHARGE_DATE
            if (hasVal(request.getParameter("dischargeDate"))) {
                lr.setDischargeDate(LocalDate.parse(request.getParameter("dischargeDate")));
            }

            // 5. Mapping Emergency & Spouse Data
            lr.setEmergencyCategory(request.getParameter("emergencyCategory"));
            lr.setEmergencyContact(request.getParameter("emergencyContact"));
            lr.setSpouseName(request.getParameter("spouseName"));

            // Handle File Attachment
            Part filePart = request.getPart("attachment");
            
            // Execute Database Submission
            if (leaveDAO.submitRequest(lr, filePart)) {
                response.sendRedirect("ApplyLeave?msg=" + url("success"));
            } else {
                response.sendRedirect("ApplyLeave?error=" + url("Submit failed. Please check your leave balance."));
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("ApplyLeave?error=" + url("Error: " + e.getMessage()));
        }
    }
}