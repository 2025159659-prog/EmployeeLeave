import bean.LeaveRequest;
import bean.LeaveBalance;
import dao.LeaveDAO;
import dao.LeaveBalanceDAO;
import util.DatabaseConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.Connection;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

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

        try (Connection con = DatabaseConnection.getConnection()) {
            int empId = (Integer) session.getAttribute("empid");
            String idParam = request.getParameter("id");
            if (idParam == null) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }

            LeaveRequest lr = leaveDAO.getLeaveById(Integer.parseInt(idParam), empId);
            if (lr == null || !"PENDING".equalsIgnoreCase(lr.getStatusCode())) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.getWriter().print("{\"error\":\"Only PENDING requests can be edited.\"}");
                return;
            }

            LeaveBalanceDAO lbDAO = new LeaveBalanceDAO(con);
            List<LeaveBalance> balances = lbDAO.getEmployeeBalances(empId);
            double currentBalance = 0;
            for (LeaveBalance b : balances) {
                if (b.getLeaveTypeId() == lr.getLeaveTypeId()) {
                    currentBalance = b.getTotalAvailable();
                    break;
                }
            }

            Object genderObj = session.getAttribute("gender");
            String gen = (genderObj != null) ? String.valueOf(genderObj).trim().toUpperCase() : ""; 
            boolean isFemale = gen.startsWith("F") || gen.startsWith("P") || gen.contains("FEMALE");
            boolean isMale = !isFemale;

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
                .append("\"balance\":").append(currentBalance).append(",")
                .append("\"leaveTypes\":[");
            
            List<Map<String, Object>> types = leaveDAO.getAllLeaveTypes();
            boolean first = true;
            for (Map<String, Object> t : types) {
                String code = t.get("code").toString().toUpperCase();
                if ((code.contains("MATERNITY") && !isFemale) || (code.contains("PATERNITY") && !isMale)) continue;

                if (!first) json.append(",");
                json.append("{\"id\":").append(t.get("id"))
                    .append(",\"code\":\"").append(esc(t.get("code").toString()))
                    .append("\",\"desc\":\"").append(esc(t.get("desc") != null ? t.get("desc").toString() : "")).append("\"}");
                first = false;
            }
            json.append("]}");
            response.getWriter().print(json.toString());

        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().print("{\"error\":\"" + esc(e.getMessage()) + "\"}");
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
            int leaveId = Integer.parseInt(request.getParameter("leaveId"));

            LeaveRequest existing = leaveDAO.getLeaveById(leaveId, empId);
            if (existing == null || !"PENDING".equalsIgnoreCase(existing.getStatusCode())) {
                response.getWriter().print("Error: Record is no longer editable.");
                return;
            }

            existing.setReason(request.getParameter("reason"));
            String durationUi = request.getParameter("duration");
            boolean isHalf = durationUi.startsWith("HALF_DAY");
            
            LocalDate start = LocalDate.parse(request.getParameter("startDate"));
            LocalDate end = isHalf ? start : LocalDate.parse(request.getParameter("endDate"));
            
            existing.setStartDate(start);
            existing.setEndDate(end);
            existing.setDuration(isHalf ? "HALF_DAY" : "FULL_DAY");
            existing.setHalfSession(isHalf ? (durationUi.contains("AM") ? "AM" : "PM") : null);

            // Corrected working days logic (Excluding weekends and holidays via DAO)
            double days = isHalf ? 0.5 : leaveDAO.calculateWorkingDays(existing.getStartDate(), existing.getEndDate());
            
            if (days <= 0) {
                response.getWriter().print("Error: Invalid dates selected. Ensure dates are working days and end date is after start date.");
                return;
            }
            existing.setDurationDays(days);

            if (leaveDAO.updateLeave(existing, empId)) {
                response.getWriter().print("OK");
            } else {
                response.getWriter().print("Update failed. Insufficient balance.");
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.getWriter().print("System Error: " + e.getMessage());
        }
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "");
    }
}