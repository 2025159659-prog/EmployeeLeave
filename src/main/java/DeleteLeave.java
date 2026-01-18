import dao.LeaveDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * Controller for handling leave deletion requests. Only PENDING requests are
 * allowed to be deleted.
 */
@WebServlet("/DeleteLeave")
public class DeleteLeave extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private final LeaveDAO leaveDAO = new LeaveDAO();

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		// 1. Session and Security Validation
		HttpSession session = request.getSession(false);
		if (session == null || session.getAttribute("empid") == null) {
			response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
			response.getWriter().print("Unauthorized: Please login again.");
			return;
		}

		try {
			// 2. Data Extraction
			int empId = Integer.parseInt(String.valueOf(session.getAttribute("empid")));
			String idParam = request.getParameter("id");

			if (idParam == null || idParam.isEmpty()) {
				response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
				response.getWriter().print("Error: Missing Leave ID.");
				return;
			}

			int leaveId = Integer.parseInt(idParam);

			// 3. Logic Execution via DAO
			// The DAO handles both deletion and balance restoration in one transaction
			if (leaveDAO.deleteLeave(leaveId, empId)) {
				response.setContentType("text/plain");
				response.getWriter().print("OK");
			} else {
				response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
				response.getWriter().print("Failed: Only PENDING requests can be deleted.");
			}

		} catch (NumberFormatException e) {
			response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
			response.getWriter().print("Error: Invalid ID format.");
		} catch (Exception e) {
			e.printStackTrace();
			response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
			response.getWriter().print("System Error: " + e.getMessage());
		}
	}
}