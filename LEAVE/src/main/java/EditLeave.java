import bean.LeaveRecord;
import dao.LeaveDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@WebServlet("/EditLeave")
public class EditLeave extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final LeaveDAO leaveDAO = new LeaveDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || !"EMPLOYEE".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendError(401); return;
        }

        try {
            int leaveId = Integer.parseInt(request.getParameter("id"));
            int empId = (Integer) session.getAttribute("empid");

            LeaveRecord lr = leaveDAO.getLeaveById(leaveId, empId);
            if (lr == null) { response.sendError(404); return; }
            if (!"PENDING".equalsIgnoreCase(lr.getStatusCode())) { response.sendError(403, "Only PENDING can be edited"); return; }

            // Construct JSON for the Modal
            String durationUi = "FULL_DAY";
            if ("HALF_DAY".equalsIgnoreCase(lr.getDbDuration())) {
                durationUi = "PM".equalsIgnoreCase(lr.getHalfSession()) ? "HALF_DAY_PM" : "HALF_DAY_AM";
            }

            response.setContentType("application/json");
            StringBuilder json = new StringBuilder();
            json.append("{")
                .append("\"leaveId\":").append(lr.getId()).append(",")
                .append("\"leaveTypeId\":").append(lr.getLeaveTypeId()).append(",")
                .append("\"startDate\":\"").append(lr.getStartDate()).append("\",")
                .append("\"endDate\":\"").append(lr.getEndDate()).append("\",")
                .append("\"duration\":\"").append(durationUi).append("\",")
                .append("\"reason\":\"").append(esc(lr.getReason())).append("\",")
                .append("\"leaveTypes\":[");
            
            List<Map<String, Object>> types = leaveDAO.getAllLeaveTypes();
            for (int i = 0; i < types.size(); i++) {
                Map<String, Object> t = types.get(i);
                json.append("{\"value\":").append(t.get("id")).append(",\"label\":\"").append(esc(t.get("code").toString())).append("\"}");
                if (i < types.size() - 1) json.append(",");
            }
            json.append("]}");
            response.getWriter().print(json.toString());

        } catch (Exception e) {
            response.sendError(500, e.getMessage());
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || !"EMPLOYEE".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendError(401); return;
        }

        try {
            int empId = (Integer) session.getAttribute("empid");
            LeaveRecord lr = new LeaveRecord();
            lr.setId(Integer.parseInt(request.getParameter("leaveId")));
            lr.setLeaveTypeId(Integer.parseInt(request.getParameter("leaveType")));
            lr.setReason(request.getParameter("reason"));
            
            String durationUi = request.getParameter("duration");
            boolean isHalf = durationUi.startsWith("HALF");
            LocalDate start = LocalDate.parse(request.getParameter("startDate"));
            LocalDate end = isHalf ? start : LocalDate.parse(request.getParameter("endDate"));

            lr.setStartDate(java.sql.Date.valueOf(start));
            lr.setEndDate(java.sql.Date.valueOf(end));
            lr.setDbDuration(isHalf ? "HALF_DAY" : "FULL_DAY");
            lr.setHalfSession(isHalf ? (durationUi.contains("PM") ? "PM" : "AM") : null);

            // Calculate new working days
            double days = isHalf ? 0.5 : leaveDAO.calculateWorkingDays(start, end);
            if (days <= 0) { response.getWriter().print("Error: Selection is on holidays/weekends"); return; }
            lr.setTotalDays(days);

            if (leaveDAO.updateLeave(lr, empId)) {
                response.getWriter().print("OK");
            } else {
                response.getWriter().print("Update failed");
            }
        } catch (Exception e) {
            response.getWriter().print("System Error: " + e.getMessage());
        }
    }

    private String esc(String s) {
        return s == null ? "" : s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", " ");
    }
}