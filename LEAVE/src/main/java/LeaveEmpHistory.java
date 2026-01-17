import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;
import dao.AdminLeaveHistoryDAO;
import bean.LeaveRecord;

@WebServlet("/leaveEmpHistory")
public class LeaveEmpHistory extends HttpServlet {
	private final AdminLeaveHistoryDAO AdminLeaveHistoryDAO = new AdminLeaveHistoryDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		HttpSession session = request.getSession(false);
		if (session == null || !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
			response.sendRedirect("login.jsp?error=Unauthorized");
			return;
		}

		try {
			String status = request.getParameter("status");
			String month = request.getParameter("month");
			String year = request.getParameter("year");

			// Delegate to DAO
			List<LeaveRecord> history = AdminLeaveHistoryDAO.getAllHistory(status, month, year);
			List<String> years = AdminLeaveHistoryDAO.getFilterYears();

			request.setAttribute("history", history);
			request.setAttribute("years", years);

			request.getRequestDispatcher("/leaveEmpHistory.jsp").forward(request, response);
		} catch (Exception e) {
			request.setAttribute("error", e.getMessage());
			request.getRequestDispatcher("/leaveEmpHistory.jsp").forward(request, response);
		}
	}
}