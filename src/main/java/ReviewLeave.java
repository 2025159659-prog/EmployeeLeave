import dao.ManagerDAO;
import bean.LeaveRecord;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.stream.Collectors;

/**
 * ReviewLeave Servlet Manages the workflow for managers to view and process
 * leave requests.
 */
@WebServlet("/ReviewLeave")
public class ReviewLeave extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private final ManagerDAO managerDAO = new ManagerDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		HttpSession session = request.getSession(false);

		// 1. Strict Authorization Check
		if (session == null || session.getAttribute("empid") == null
				|| !"MANAGER".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
			response.sendRedirect(
					"login.jsp?error=" + URLEncoder.encode("Unauthorized access.", StandardCharsets.UTF_8));
			return;
		}

		try {
			// 2. Fetch all actionable requests (Pending or Cancellation Requested)
			List<LeaveRecord> allRequests = managerDAO.getRequestsForReview();

			// Optional: Filter by Manager ID if your DAO doesn't already restrict the query
			// String managerId = String.valueOf(session.getAttribute("empid"));

			// 3. Calculate statistics for the Manager UI badges
			long pendingCount = allRequests.stream().filter(r -> "PENDING".equalsIgnoreCase(r.getStatusCode())).count();

			long cancelReqCount = allRequests.stream()
					.filter(r -> "CANCELLATION_REQUESTED".equalsIgnoreCase(r.getStatusCode())).count();

			// 4. Set attributes for the JSP
			request.setAttribute("leaves", allRequests);
			request.setAttribute("pendingCount", (int) pendingCount);
			request.setAttribute("cancelReqCount", (int) cancelReqCount);

			// 5. Forward to UI
			request.getRequestDispatcher("/reviewLeave.jsp").forward(request, response);

		} catch (Exception e) {
			e.printStackTrace();
			response.sendRedirect("ReviewLeave?error="
					+ URLEncoder.encode("Error loading requests: " + e.getMessage(), StandardCharsets.UTF_8));
		}
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		HttpSession session = request.getSession(false);

		// 1. Authorization Check for POST
		if (session == null || !"MANAGER".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN, "You do not have permission to perform this action.");
			return;
		}

		try {
			// 2. Extract and validate parameters
			String leaveIdStr = request.getParameter("leaveId");
			String action = request.getParameter("action"); // EXPECTED: APPROVE, REJECT, APPROVE_CANCEL, REJECT_CANCEL
			String comment = request.getParameter("comment");

			if (leaveIdStr == null || action == null) {
				response.sendRedirect("ReviewLeave?error="
						+ URLEncoder.encode("Invalid request parameters.", StandardCharsets.UTF_8));
				return;
			}

			int leaveId = Integer.parseInt(leaveIdStr);

			// Handle empty comments to avoid NULL in DB if preferred
			if (comment == null)
				comment = "";

			// 3. Process the action via DAO (Transactionally handles Status + Balances)
			boolean success = managerDAO.processAction(leaveId, action, comment);

			if (success) {
				String successMsg = "Leave application successfully " + formatActionName(action) + ".";
				response.sendRedirect("ReviewLeave?msg=" + URLEncoder.encode(successMsg, StandardCharsets.UTF_8));
			} else {
				response.sendRedirect("ReviewLeave?error=" + URLEncoder
						.encode("Update failed. Request may have already been processed.", StandardCharsets.UTF_8));
			}

		} catch (NumberFormatException e) {
			response.sendRedirect("ReviewLeave?error=InvalidID");
		} catch (Exception e) {
			e.printStackTrace();
			String errorMsg = e.getMessage() != null ? e.getMessage() : "An internal error occurred.";
			response.sendRedirect("ReviewLeave?error=" + URLEncoder.encode(errorMsg, StandardCharsets.UTF_8));
		}
	}

	/**
	 * Helper to make success messages more readable.
	 */
	private String formatActionName(String action) {
		switch (action) {
		case "APPROVE":
			return "approved";
		case "REJECT":
			return "rejected";
		case "APPROVE_CANCEL":
			return "cancelled";
		case "REJECT_CANCEL":
			return "maintained (cancellation denied)";
		default:
			return "processed";
		}
	}

}
