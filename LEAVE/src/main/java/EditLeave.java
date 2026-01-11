
import bean.LeaveRequest;
import dao.LeaveDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * Controller for editing an existing pending leave request.
 * Handles fetching data (GET) for the modal and updating data (POST).
 */
@WebServlet("/EditLeave")
public class EditLeave extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final LeaveDAO leaveDAO = new LeaveDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("empid") == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        try {
            String idParam = request.getParameter("id");
            if (idParam == null) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }

            int leaveId = Integer.parseInt(idParam);
            int empId = (Integer) session.getAttribute("empid");

            // 1. Fetch the specific leave request from DAO
            LeaveRequest lr = leaveDAO.getLeaveById(leaveId, empId);
            if (lr == null) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                return;
            }

            // 2. Security Check: Only PENDING leaves can be edited
            if (!"PENDING".equalsIgnoreCase(lr.getStatusCode())) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.getWriter().print("Error: Only PENDING requests can be edited.");
                return;
            }

            // 3. Construct JSON response for the frontend Modal
            response.setContentType("application/json");
            StringBuilder json = new StringBuilder();
            json.append("{")
                .append("\"leaveId\":").append(lr.getLeaveId()).append(",")
                .append("\"leaveTypeId\":").append(lr.getLeaveTypeId()).append(",")
                .append("\"startDate\":\"").append(lr.getStartDate()).append("\",")
                .append("\"endDate\":\"").append(lr.getEndDate()).append("\",")
                .append("\"duration\":\"").append(lr.getDuration()).append("\",")
                .append("\"halfSession\":\"").append(lr.getHalfSession() == null ? "" : lr.getHalfSession()).append("\",")
                .append("\"reason\":\"").append(esc(lr.getReason())).append("\",")
                .append("\"leaveTypes\":[");
            
            // Include available leave types for the dropdown
            List<Map<String, Object>> types = leaveDAO.getAllLeaveTypes();
            for (int i = 0; i < types.size(); i++) {
                Map<String, Object> t = types.get(i);
                json.append("{\"id\":").append(t.get("id"))
                    .append(",\"code\":\"").append(esc(t.get("code").toString()))
                    .append("\",\"desc\":\"").append(esc(t.get("desc").toString())).append("\"}");
                if (i < types.size() - 1) json.append(",");
            }
            json.append("]}");

            response.getWriter().print(json.toString());

        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().print("System Error: " + e.getMessage());
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("empid") == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        try {
            int empId = (Integer) session.getAttribute("empid");
            
            // 1. Extract data into LeaveRequest Bean
            LeaveRequest lr = new LeaveRequest();
            lr.setLeaveId(Integer.parseInt(request.getParameter("leaveId")));
            lr.setLeaveTypeId(Integer.parseInt(request.getParameter("leaveType")));
            lr.setReason(request.getParameter("reason"));
            
            String durationType = request.getParameter("duration"); // FULL_DAY or HALF_DAY
            LocalDate start = LocalDate.parse(request.getParameter("startDate"));
            
            // Logic: For half days, start and end date are the same
            LocalDate end = "HALF_DAY".equalsIgnoreCase(durationType) ? start : LocalDate.parse(request.getParameter("endDate"));

            lr.setStartDate(start);
            lr.setEndDate(end);
            lr.setDuration(durationType);
            lr.setHalfSession(request.getParameter("halfSession")); // AM or PM
            
            // Additional fields often required for updates in your DAO structure
            lr.setMedicalFacility(request.getParameter("medicalFacility"));
            lr.setRefSerialNo(request.getParameter("refSerialNo"));
            lr.setEmergencyCategory(request.getParameter("emergencyCategory"));
            lr.setEmergencyContact(request.getParameter("emergencyContact"));
            lr.setSpouseName(request.getParameter("spouseName"));

            // 2. Re-calculate Duration Days
            double days = "HALF_DAY".equalsIgnoreCase(durationType) ? 0.5 : leaveDAO.calculateWorkingDays(start, end);
            
            if (days <= 0) {
                response.getWriter().print("Error: Selected dates consist only of weekends or holidays.");
                return;
            }
            lr.setDurationDays(days);

            // 3. Execute Update via DAO (Passing empId separately for security)
            if (leaveDAO.updateLeave(lr, empId)) {
                response.getWriter().print("OK");
            } else {
                response.getWriter().print("Failed to update: Request might no longer be in PENDING status.");
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.getWriter().print("System Error: " + e.getMessage());
        }
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\b", "\\b")
                .replace("\f", "\\f")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}