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
import java.util.*;

@WebServlet("/ApplyLeave")
@MultipartConfig(fileSizeThreshold = 1024 * 1024, maxFileSize = 5L * 1024 * 1024, maxRequestSize = 6L * 1024 * 1024)
public class ApplyLeave extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private LeaveDAO leaveDAO = new LeaveDAO();

	private String url(String s) {
		return URLEncoder.encode(s, StandardCharsets.UTF_8);
	}

	private boolean hasVal(String s) {
		return s != null && !s.trim().isEmpty();
	}

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

		try (Connection con = DatabaseConnection.getConnection()) {
			int empId = Integer.parseInt(String.valueOf(session.getAttribute("empid")));

			// 1. Refresh Gender
			String sql = "SELECT GENDER FROM USERS WHERE EMPID = ?";
			try (PreparedStatement ps = con.prepareStatement(sql)) {
				ps.setInt(1, empId);
				try (ResultSet rs = ps.executeQuery()) {
					if (rs.next()) {
						session.setAttribute("gender", rs.getString("GENDER"));
					}
				}
			}

			// 2. Fetch Latest Balances for validation
			LeaveBalanceDAO lbDAO = new LeaveBalanceDAO(con);
			List<LeaveBalance> balances = lbDAO.getEmployeeBalances(empId);

			request.setAttribute("balances", balances);
			request.setAttribute("leaveTypes", leaveDAO.getAllLeaveTypes());

		} catch (Exception e) {
			e.printStackTrace();
			request.setAttribute("typeError", "System Error: " + e.getMessage());
		}
		request.getRequestDispatcher("/applyLeave.jsp").forward(request, response);
	}

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
			boolean isHalf = "HALF_DAY_AM".equalsIgnoreCase(durationUi) || "HALF_DAY_PM".equalsIgnoreCase(durationUi);

			lr.setStartDate(LocalDate.parse(request.getParameter("startDate")));
			lr.setEndDate(isHalf ? lr.getStartDate() : LocalDate.parse(request.getParameter("endDate")));
			lr.setDuration(isHalf ? "HALF_DAY" : "FULL_DAY");
			lr.setHalfSession(isHalf ? (durationUi.contains("AM") ? "AM" : "PM") : null);

			// Double check working days logic
			double days = isHalf ? 0.5 : leaveDAO.calculateWorkingDays(lr.getStartDate(), lr.getEndDate());
			if (days <= 0) {
				response.sendRedirect(
						"ApplyLeave?error=" + url("Invalid dates selected. End date must be after start date."));
				return;
			}
			lr.setDurationDays(days);

			// Mapping Metadata
			String facility = request.getParameter("clinicName");
			if (!hasVal(facility))
				facility = request.getParameter("hospitalName");
			if (!hasVal(facility))
				facility = request.getParameter("maternityClinic");
			if (!hasVal(facility))
				facility = request.getParameter("hospitalLocation");
			lr.setMedicalFacility(facility);
			lr.setRefSerialNo(request.getParameter("mcSerialNumber"));

			String eventDateStr = request.getParameter("admissionDate");
			if (!hasVal(eventDateStr))
				eventDateStr = request.getParameter("expectedDueDate");
			if (!hasVal(eventDateStr))
				eventDateStr = request.getParameter("deliveryDate");
			if (hasVal(eventDateStr))
				lr.setEventDate(LocalDate.parse(eventDateStr));

			if (hasVal(request.getParameter("dischargeDate")))
				lr.setDischargeDate(LocalDate.parse(request.getParameter("dischargeDate")));
			if (hasVal(request.getParameter("weekPregnancy")))
				lr.setWeekPregnancy(Integer.parseInt(request.getParameter("weekPregnancy")));

			lr.setEmergencyCategory(request.getParameter("emergencyCategory"));
			lr.setEmergencyContact(request.getParameter("emergencyContact"));
			lr.setSpouseName(request.getParameter("spouseName"));

			Part filePart = request.getPart("attachment");

			if (leaveDAO.submitRequest(lr, filePart)) {
				response.sendRedirect("ApplyLeave?msg=" + url("success"));
			} else {
				response.sendRedirect("ApplyLeave?error="
						+ url("Submission failed. You may have insufficient leave balance or a overlapping request."));
			}
		} catch (Exception e) {
			e.printStackTrace();
			response.sendRedirect("ApplyLeave?error=" + url("Error: " + e.getMessage()));
		}
	}
}
