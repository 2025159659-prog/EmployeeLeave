import bean.LeaveRequest;
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
        if (session == null || session.getAttribute("empid") == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        try {
            int empId = (Integer) session.getAttribute("empid");
            String idParam = request.getParameter("id");
            if (idParam == null) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                return;
            }

            LeaveRequest lr = leaveDAO.getLeaveById(Integer.parseInt(idParam), empId);
            if (lr == null || !"PENDING".equalsIgnoreCase(lr.getStatusCode())) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.getWriter().print("Error: Only PENDING requests can be edited.");
                return;
            }

            // GENDER LOGIC
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
                // Metadata for pre-filling
                .append("\"med\":\"").append(esc(lr.getMedicalFacility())).append("\",")
                .append("\"ref\":\"").append(esc(lr.getRefSerialNo())).append("\",")
                .append("\"cat\":\"").append(esc(lr.getEmergencyCategory())).append("\",")
                .append("\"cnt\":\"").append(esc(lr.getEmergencyContact())).append("\",")
                .append("\"spo\":\"").append(esc(lr.getSpouseName())).append("\",")
                .append("\"leaveTypes\":[");
            
            List<Map<String, Object>> types = leaveDAO.getAllLeaveTypes();
            boolean first = true;
            for (Map<String, Object> t : types) {
                String code = t.get("code").toString().toUpperCase();
                String desc = (t.get("desc") != null) ? t.get("desc").toString().toUpperCase() : "";
                
                boolean isMat = code.contains("MATERNITY") || code.equals("ML") || desc.contains("MATERNITY");
                boolean isPat = code.contains("PATERNITY") || code.equals("PL") || desc.contains("PATERNITY");

                if ((isMat && !isFemale) || (isPat && !isMale)) continue;

                if (!first) json.append(",");
                json.append("{\"id\":").append(t.get("id"))
                    .append(",\"code\":\"").append(esc(t.get("code").toString()))
                    .append("\",\"desc\":\"").append(esc(t.get("desc").toString())).append("\"}");
                first = false;
            }
            json.append("]}");
            response.getWriter().print(json.toString());

        } catch (Exception e) {
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
            LeaveRequest lr = new LeaveRequest();
            lr.setLeaveId(Integer.parseInt(request.getParameter("leaveId")));
            lr.setLeaveTypeId(Integer.parseInt(request.getParameter("leaveType")));
            lr.setReason(request.getParameter("reason"));
            
            String durationType = request.getParameter("duration"); 
            LocalDate start = LocalDate.parse(request.getParameter("startDate"));
            LocalDate end = "HALF_DAY".equalsIgnoreCase(durationType) ? start : LocalDate.parse(request.getParameter("endDate"));

            lr.setStartDate(start);
            lr.setEndDate(end);
            lr.setDuration(durationType);
            lr.setHalfSession(request.getParameter("halfSession"));
            
            // Capture Dynamic Metadata
            lr.setMedicalFacility(request.getParameter("medicalFacility"));
            lr.setRefSerialNo(request.getParameter("refSerialNo"));
            lr.setEmergencyCategory(request.getParameter("emergencyCategory"));
            lr.setEmergencyContact(request.getParameter("emergencyContact"));
            lr.setSpouseName(request.getParameter("spouseName"));

            double days = "HALF_DAY".equalsIgnoreCase(durationType) ? 0.5 : leaveDAO.calculateWorkingDays(start, end);
            if (days <= 0) {
                response.getWriter().print("Error: Invalid working days.");
                return;
            }
            lr.setDurationDays(days);

            if (leaveDAO.updateLeave(lr, empId)) response.getWriter().print("OK");
            else response.getWriter().print("Update failed.");

        } catch (Exception e) {
            response.getWriter().print("System Error: " + e.getMessage());
        }
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "");
    }
}