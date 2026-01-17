import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import dao.LeaveDAO;

@WebServlet("/CancelLeave") // Cleaned URL: removed "Servlet"
public class CancelLeave extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private LeaveDAO leaveDAO;

	@Override
	public void init() {
		leaveDAO = new LeaveDAO();
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		// 1. Session Validation
		HttpSession session = request.getSession(false);
		if (session == null || session.getAttribute("empid") == null) {
			response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized");
			return;
		}

		try {
			// 2. Data Extraction
			int empId = (Integer) session.getAttribute("empid");
			String idParam = request.getParameter("id");

			if (idParam == null) {
				response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing ID");
				return;
			}
			int leaveId = Integer.parseInt(idParam);

			// 3. Business Logic Execution
			boolean success = leaveDAO.requestCancellation(leaveId, empId);

			// 4. Response
			if (success) {
				response.getWriter().print("OK");
			} else {
				response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
				response.getWriter().print("Request failed. Only approved leaves can be cancelled.");
			}

		} catch (NumberFormatException e) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid ID format");
		} catch (Exception e) {
			e.printStackTrace();
			response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
			response.getWriter().print("Database Error: " + e.getMessage());
		}
	}
}