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

@WebServlet("/EditLeave")
public class EditLeave extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final LeaveDAO leaveDAO = new LeaveDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
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
                response.getWriter().print("{\"error\":\"Hanya permohonan PENDING yang boleh diedit.\"}");
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
                .append("\"medicalFacility\":\"").append(esc(lr.getMedicalFacility())).append("\",")
                .append("\"ref\":\"").append(esc(lr.getRefSerialNo())).append("\",")
                .append("\"cat\":\"").append(esc(lr.getEmergencyCategory())).append("\",")
                .append("\"cnt\":\"").append(esc(lr.getEmergencyContact())).append("\",")
                .append("\"spo\":\"").append(esc(lr.getSpouseName())).append("\",")
                .append("\"eventDate\":\"").append(lr.getEventDate() != null ? lr.getEventDate() : "").append("\",")
                .append("\"dischargeDate\":\"").append(lr.getDischargeDate() != null ? lr.getDischargeDate() : "").append("\",")
                .append("\"weekPregnancy\":\"").append(lr.getWeekPregnancy()).append("\",")
                .append("\"balance\":").append(currentBalance).append(",")
                .append("\"leaveTypes\":[");

            List<Map<String, Object>> types = leaveDAO.getAllLeaveTypes();
            boolean first = true;
            for (Map<String, Object> t : types) {
                String code = t.get("code").toString().toUpperCase();
                if ((code.contains("MATERNITY") && !isFemale) || (code.contains("PATERNITY") && !isMale)) continue;
                if (!first) json.append(",");
                json.append("{\"id\":").append(t.get("id")).append(",\"code\":\"").append(esc(t.get("code").toString()))
                    .append("\",\"desc\":\"").append(esc(t.get("desc") != null ? t.get("desc").toString() : ""))
                    .append("\"}");
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
            
            // Ambil parameter dengan selamat
            String leaveIdStr = request.getParameter("leaveId");
            String leaveTypeIdStr = request.getParameter("leaveTypeId");

            // Debug log ke Heroku console
            System.out.println("DEBUG EditLeave: leaveId=" + leaveIdStr + ", leaveTypeId=" + leaveTypeIdStr);

            if (leaveIdStr == null || leaveIdStr.isEmpty() || leaveTypeIdStr == null || leaveTypeIdStr.isEmpty()) {
                response.getWriter().print("Error: Parameter leaveId atau leaveTypeId hilang.");
                return;
            }

            int leaveId = Integer.parseInt(leaveIdStr);
            int leaveTypeId = Integer.parseInt(leaveTypeIdStr);

            LeaveRequest existing = leaveDAO.getLeaveById(leaveId, empId);
            if (existing == null) {
                response.getWriter().print("Error: Rekod tidak dijumpai.");
                return;
            }

            // 1. Map Data Asas
            existing.setLeaveTypeId(leaveTypeId);
            existing.setReason(request.getParameter("reason"));
            String durationUi = request.getParameter("duration");
            boolean isHalf = durationUi != null && (durationUi.startsWith("HALF_DAY") || durationUi.contains("AM") || durationUi.contains("PM"));

            existing.setStartDate(LocalDate.parse(request.getParameter("startDate")));
            existing.setEndDate(isHalf ? existing.getStartDate() : LocalDate.parse(request.getParameter("endDate")));
            existing.setDuration(isHalf ? "HALF_DAY" : "FULL_DAY");
            existing.setHalfSession(isHalf ? (durationUi.contains("AM") ? "AM" : "PM") : null);

            // 2. Map Metadata
            existing.setMedicalFacility(request.getParameter("medicalFacility"));
            existing.setRefSerialNo(request.getParameter("refSerialNo"));
            existing.setEmergencyCategory(request.getParameter("emergencyCategory"));
            existing.setEmergencyContact(request.getParameter("emergencyContact"));
            existing.setSpouseName(request.getParameter("spouseName"));

            String eventDate = request.getParameter("eventDate");
            if (eventDate != null && !eventDate.isBlank() && !"null".equals(eventDate)) existing.setEventDate(LocalDate.parse(eventDate));
            
            String dischargeDate = request.getParameter("dischargeDate");
            if (dischargeDate != null && !dischargeDate.isBlank() && !"null".equals(dischargeDate)) existing.setDischargeDate(LocalDate.parse(dischargeDate));

            String week = request.getParameter("weekPregnancy");
            if (week != null && !week.isBlank() && !"null".equals(week)) existing.setWeekPregnancy(Integer.parseInt(week));

            // Support field names alternatif dari modal
            if (request.getParameter("consultationClinic") != null) existing.setMedicalFacility(request.getParameter("consultationClinic"));
            String edd = request.getParameter("expectedDueDate");
            if (edd != null && !edd.isBlank() && !"null".equals(edd)) existing.setEventDate(LocalDate.parse(edd));

            // 3. Kira semula hari
            double days = isHalf ? 0.5 : leaveDAO.calculateWorkingDays(existing.getStartDate(), existing.getEndDate());
            existing.setDurationDays(days);

            // 4. Update
            if (leaveDAO.updateLeave(existing, empId)) {
                response.getWriter().print("OK");
            } else {
                response.getWriter().print("Gagal mengemaskini maklumat.");
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
