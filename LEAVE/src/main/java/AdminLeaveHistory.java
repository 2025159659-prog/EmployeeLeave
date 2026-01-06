
import bean.LeaveRecord;
import dao.AdminLeaveHistoryDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

@WebServlet("/AdminLeaveHistory")
public class AdminLeaveHistory extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final AdminLeaveHistoryDAO adminDAO = new AdminLeaveHistoryDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect("login.jsp?error=Unauthorized");
            return;
        }

        String status = request.getParameter("status");
        String year = request.getParameter("year");
        String search = request.getParameter("search");

        try {
            List<String> years = adminDAO.getAvailableYears();
            List<LeaveRecord> leaves = adminDAO.getAllLeaveHistory(status, year, search);

            request.setAttribute("leaves", leaves);
            request.setAttribute("years", years);
            request.setAttribute("selStatus", status != null ? status : "ALL");
            request.setAttribute("selYear", year != null ? year : "");
            request.setAttribute("selSearch", search != null ? search : "");
            
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Error: " + e.getMessage());
        }

        request.getRequestDispatcher("adminLeaveHistory.jsp").forward(request, response);
    }
}