
import bean.LeaveRequest;
import dao.LeaveDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.*;

@WebServlet("/ApplyLeave")
@MultipartConfig(fileSizeThreshold = 1024 * 1024, maxFileSize = 5L * 1024 * 1024, maxRequestSize = 6L * 1024 * 1024)
public class ApplyLeave extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private LeaveDAO leaveDAO = new LeaveDAO();

    private String url(String s) { return URLEncoder.encode(s, StandardCharsets.UTF_8); }
    private boolean hasVal(String s) { return s != null && !s.trim().isEmpty(); }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("empid") == null) {
            response.sendRedirect("login.jsp?error=" + url("Please login."));
            return;
        }
        try {
            request.setAttribute("leaveTypes", leaveDAO.getAllLeaveTypes());
        } catch (Exception e) {
            request.setAttribute("typeError", e.getMessage());
        }
        request.getRequestDispatcher("/applyLeave.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("empid") == null) {
            response.sendRedirect("login.jsp?error=" + url("Please login."));
            return;
        }

        try {
            int empId = Integer.parseInt(String.valueOf(session.getAttribute("empid")));
            LeaveRequest lr = new LeaveRequest();
            lr.setEmpId(empId);
            lr.setLeaveTypeId(Integer.parseInt(request.getParameter("leaveTypeId")));
            lr.setReason(request.getParameter("reason"));

            String durationUi = request.getParameter("duration");
            boolean isHalf = "HALF_DAY_AM".equalsIgnoreCase(durationUi) || "HALF_DAY_PM".equalsIgnoreCase(durationUi);
            lr.setStartDate(LocalDate.parse(request.getParameter("startDate")));
            lr.setEndDate(isHalf ? lr.getStartDate() : LocalDate.parse(request.getParameter("endDate")));
            lr.setDuration(isHalf ? "HALF_DAY" : "FULL_DAY");
            lr.setHalfSession(isHalf ? (durationUi.contains("AM") ? "AM" : "PM") : null);

            // Calculate working days
            double days = isHalf ? 0.5 : leaveDAO.calculateWorkingDays(lr.getStartDate(), lr.getEndDate());
            if (days <= 0) {
                response.sendRedirect("ApplyLeave?error=" + url("Selection falls on holidays/weekends."));
                return;
            }
            lr.setDurationDays(days);

            // Map Dynamic Fields
            lr.setMedicalFacility(hasVal(request.getParameter("clinicName")) ? request.getParameter("clinicName") : request.getParameter("hospitalName"));
            lr.setRefSerialNo(hasVal(request.getParameter("mcSerialNumber")) ? request.getParameter("mcSerialNumber") : request.getParameter("spouseIC"));
            lr.setEventDate(hasVal(request.getParameter("admissionDate")) ? LocalDate.parse(request.getParameter("admissionDate")) : null);
            lr.setEmergencyCategory(request.getParameter("emergencyCategory"));
            lr.setEmergencyContact(request.getParameter("emergencyContact"));
            lr.setSpouseName(request.getParameter("spouseName"));

            Part filePart = request.getPart("attachment");
            leaveDAO.submitRequest(lr, filePart);

            response.sendRedirect("ApplyLeave?msg=" + url("Request submitted for " + days + " days."));
        } catch (Exception e) {
            response.sendRedirect("ApplyLeave?error=" + url("Error: " + e.getMessage()));
        }
    }
}