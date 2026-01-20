import bean.LeaveRequest;
import bean.User;
import dao.LeaveDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.time.LocalDate;
import java.net.URLEncoder;

@WebServlet("/EditLeave")
public class EditLeave extends HttpServlet {
    private final LeaveDAO leaveDAO = new LeaveDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        try {
            int leaveId = Integer.parseInt(request.getParameter("id"));
            // Membetulkan getEmpid() kepada getEmpId()
            LeaveRequest lr = leaveDAO.getLeaveById(leaveId, user.getEmpId());

            if (lr != null && "PENDING".equalsIgnoreCase(lr.getStatusCode())) {
                request.setAttribute("leave", lr);
                request.setAttribute("leaveTypes", leaveDAO.getAllLeaveTypes());
                request.getRequestDispatcher("editLeave.jsp").forward(request, response);
            } else {
                response.sendRedirect("LeaveHistory?error=" + URLEncoder.encode("Cuti tidak boleh diedit atau tidak dijumpai.", "UTF-8"));
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("LeaveHistory?error=SystemError");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        if (user == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        try {
            // 1. Ambil data asas
            int leaveId = Integer.parseInt(request.getParameter("leaveId"));
            int leaveTypeId = Integer.parseInt(request.getParameter("leaveTypeId"));
            LocalDate startDate = LocalDate.parse(request.getParameter("startDate"));
            LocalDate endDate = LocalDate.parse(request.getParameter("endDate"));
            String duration = request.getParameter("duration");
            String halfSession = request.getParameter("halfSession");
            String reason = request.getParameter("reason");

            // 2. Kira semula hari bekerja
            double durationDays;
            if ("FULL_DAY".equals(duration)) {
                durationDays = leaveDAO.calculateWorkingDays(startDate, endDate);
            } else {
                durationDays = 0.5;
            }

            // 3. Bina objek LeaveRequest
            LeaveRequest req = new LeaveRequest();
            req.setLeaveId(leaveId);
            // Membetulkan getEmpid() kepada getEmpId()
            req.setEmpId(user.getEmpId());
            req.setLeaveTypeId(leaveTypeId);
            req.setStartDate(startDate);
            req.setEndDate(endDate);
            req.setDuration(duration);
            req.setDurationDays(durationDays);
            req.setReason(reason);
            req.setHalfSession(halfSession);

            // 4. Ambil Metadata berdasarkan Jenis Cuti
            String typeCode = request.getParameter("leaveTypeCode");
            if (typeCode != null) {
                typeCode = typeCode.toUpperCase();
                if (typeCode.contains("EMERGENCY")) {
                    req.setEmergencyCategory(request.getParameter("emergencyCategory"));
                    req.setEmergencyContact(request.getParameter("emergencyContact"));
                } else if (typeCode.contains("SICK") || typeCode.contains("HOSPITAL") || typeCode.contains("MATERNITY") || typeCode.contains("PATERNITY")) {
                    req.setMedicalFacility(request.getParameter("medicalFacility"));
                    req.setRefSerialNo(request.getParameter("refSerialNo"));
                    
                    String eventDateStr = request.getParameter("eventDate");
                    if (eventDateStr != null && !eventDateStr.isEmpty()) {
                        req.setEventDate(LocalDate.parse(eventDateStr));
                    }
                    
                    String dischargeDateStr = request.getParameter("dischargeDate");
                    if (dischargeDateStr != null && !dischargeDateStr.isEmpty()) {
                        req.setDischargeDate(LocalDate.parse(dischargeDateStr));
                    }
                    
                    String weekPregStr = request.getParameter("weekPregnancy");
                    if (weekPregStr != null && !weekPregStr.isEmpty()) {
                        // Membetulkan typo weekPregPregnancy kepada weekPregStr
                        req.setWeekPregnancy(Integer.parseInt(weekPregStr));
                    }
                    
                    req.setSpouseName(request.getParameter("spouseName"));
                }
            }

            // 5. Panggil DAO Update
            // Membetulkan getEmpid() kepada getEmpId()
            boolean success = leaveDAO.updateLeave(req, user.getEmpId());

            if (success) {
                response.sendRedirect("LeaveHistory?success=" + URLEncoder.encode("Permohonan berjaya dikemas kini.", "UTF-8"));
            } else {
                response.sendRedirect("EditLeave?id=" + leaveId + "&error=UpdateFailed");
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("LeaveHistory?error=InternalError");
        }
    }
}
