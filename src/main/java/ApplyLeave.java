import bean.LeaveRequest;
import bean.LeaveBalance;
import dao.LeaveDAO;
import dao.LeaveBalanceDAO;
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
import java.util.List;
import java.util.Map;

@WebServlet("/ApplyLeave")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize = 5L * 1024 * 1024,
    maxRequestSize = 6L * 1024 * 1024
)
public class ApplyLeave extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private final LeaveDAO leaveDAO = new LeaveDAO();

    /* =======================
       UTIL
       ======================= */
    private String url(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }

    private boolean hasVal(String s) {
        return s != null && !s.trim().isEmpty();
    }

    /* =======================
       CENTRAL DATA LOADER
       + FULL DEBUG
       ======================= */
    private void loadApplyLeaveData(HttpServletRequest request, HttpSession session) throws Exception {

        int empId = Integer.parseInt(String.valueOf(session.getAttribute("empid")));

        try (Connection con = DatabaseConnection.getConnection()) {

            /* =======================
               DB DEBUG
               ======================= */
            System.out.println("\n===== APPLY LEAVE DEBUG START =====");
            System.out.println("DB URL     : " + con.getMetaData().getURL());
            System.out.println("DB USER    : " + con.getMetaData().getUserName());
            System.out.println("DB SCHEMA  : " + con.getSchema());

            /* =======================
               GENDER REFRESH
               ======================= */
            String gSql = "SELECT gender FROM leave.users WHERE empid = ?";
            try (PreparedStatement ps = con.prepareStatement(gSql)) {
                ps.setInt(1, empId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        session.setAttribute("gender", rs.getString("GENDER"));
                        System.out.println("Gender loaded : " + rs.getString("GENDER"));
                    }
                }
            }

            /* =======================
               BALANCES
               ======================= */
            LeaveBalanceDAO lbDAO = new LeaveBalanceDAO(con);
            List<LeaveBalance> balances = lbDAO.getEmployeeBalances(empId);
            System.out.println("Balances loaded : " + balances.size());
            request.setAttribute("balances", balances);

            /* =======================
               LEAVE TYPES (CRITICAL)
               ======================= */
            List<Map<String, Object>> types = leaveDAO.getAllLeaveTypes();

            System.out.println("Leave types class : " + types.getClass().getName());
            System.out.println("Leave types size  : " + types.size());

            for (Map<String, Object> t : types) {
                System.out.println("LeaveType -> " + t);
            }

            /* =======================
               DIRECT SQL COUNT (BYPASS DAO)
               ======================= */
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COUNT(*) FROM leave.leave_types");
                 ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    System.out.println("COUNT leave.leave_types = " + rs.getInt(1));
                }
            }

            request.setAttribute("leaveTypes", types);
            System.out.println("===== APPLY LEAVE DEBUG END =====\n");
        }
    }

    /* =======================
       GET
       ======================= */
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        String role = (session != null) ? String.valueOf(session.getAttribute("role")) : "";

        if (session == null || session.getAttribute("empid") == null
                || (!"EMPLOYEE".equalsIgnoreCase(role) && !"MANAGER".equalsIgnoreCase(role))) {
            response.sendRedirect("login.jsp?error=" + url("Please login."));
            return;
        }

        try {
            loadApplyLeaveData(request, session);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("typeError", "System Error: " + e.getMessage());
        }

        request.getRequestDispatcher("/applyLeave.jsp").forward(request, response);
    }

    /* =======================
       POST
       ======================= */
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

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

            String durationUi = request.getParameter("duration");
            boolean isHalf = "HALF_DAY_AM".equalsIgnoreCase(durationUi)
                          || "HALF_DAY_PM".equalsIgnoreCase(durationUi);

            lr.setStartDate(LocalDate.parse(request.getParameter("startDate")));
            lr.setEndDate(isHalf
                    ? lr.getStartDate()
                    : LocalDate.parse(request.getParameter("endDate")));

            lr.setDuration(isHalf ? "HALF_DAY" : "FULL_DAY");
            lr.setHalfSession(isHalf ? (durationUi.contains("AM") ? "AM" : "PM") : null);

            double days = isHalf
                    ? 0.5
                    : leaveDAO.calculateWorkingDays(lr.getStartDate(), lr.getEndDate());

            if (days <= 0) {
                throw new Exception("Invalid date selection.");
            }
            lr.setDurationDays(days);

            // ===== dynamic metadata =====
            String facility = request.getParameter("clinicName");
            if (!hasVal(facility)) facility = request.getParameter("hospitalName");
            if (!hasVal(facility)) facility = request.getParameter("maternityClinic");
            if (!hasVal(facility)) facility = request.getParameter("hospitalLocation");
            lr.setMedicalFacility(facility);

            lr.setRefSerialNo(request.getParameter("mcSerialNumber"));

            String eventDate = request.getParameter("admissionDate");
            if (!hasVal(eventDate)) eventDate = request.getParameter("expectedDueDate");
            if (!hasVal(eventDate)) eventDate = request.getParameter("deliveryDate");
            if (hasVal(eventDate)) lr.setEventDate(LocalDate.parse(eventDate));

            if (hasVal(request.getParameter("dischargeDate")))
                lr.setDischargeDate(LocalDate.parse(request.getParameter("dischargeDate")));

            if (hasVal(request.getParameter("weekPregnancy")))
                lr.setWeekPregnancy(Integer.parseInt(request.getParameter("weekPregnancy")));

            lr.setEmergencyCategory(request.getParameter("emergencyCategory"));
            lr.setEmergencyContact(request.getParameter("emergencyContact"));
            lr.setSpouseName(request.getParameter("spouseName"));

            Part filePart = request.getPart("attachment");

            leaveDAO.submitRequest(lr, filePart);

            response.sendRedirect("ApplyLeave?msg=" + url("success"));

        } catch (Exception e) {
            e.printStackTrace();
            try {
                loadApplyLeaveData(request, session);
            } catch (Exception ex) {
                ex.printStackTrace();
            }
            request.setAttribute("typeError", e.getMessage());
            request.getRequestDispatcher("/applyLeave.jsp").forward(request, response);
        }
    }
}



