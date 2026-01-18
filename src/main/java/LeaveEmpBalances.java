import bean.LeaveBalance;
import bean.User;
import dao.LeaveDAO;
import dao.LeaveBalanceDAO;
import dao.UserDAO;
import util.DatabaseConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.Connection;
import java.util.*;
import java.util.stream.Collectors;

@WebServlet("/LeaveEmpBalances")
public class LeaveEmpBalances extends HttpServlet {

    private final UserDAO userDAO = new UserDAO();
    private final LeaveDAO leaveDAO = new LeaveDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect("login.jsp?error=Admin+access+required");
            return;
        }

        List<User> employees = new ArrayList<>();
        List<Map<String, Object>> leaveTypes = new ArrayList<>();
        Map<Integer, Map<Integer, LeaveBalance>> balanceIndex = new HashMap<>();

        try (Connection con = DatabaseConnection.getConnection()) {

            // 1. Employees (EMPLOYEE sahaja)
            employees = userDAO.getAllUsers().stream()
                    .filter(u -> "EMPLOYEE".equalsIgnoreCase(u.getRole()))
                    .toList();

            // 2. Leave Types
            leaveTypes = leaveDAO.getAllLeaveTypes(); // mesti return id + code

            // 3. Leave Balances
            LeaveBalanceDAO lbDAO = new LeaveBalanceDAO(con);

            for (User u : employees) {
                Map<Integer, LeaveBalance> map = new HashMap<>();
                for (LeaveBalance b : lbDAO.getEmployeeBalances(u.getEmpId())) {
                    map.put(b.getLeaveTypeId(), b);
                }
                balanceIndex.put(u.getEmpId(), map);
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "System Error: " + e.getMessage());
        }

        // 🔐 WAJIB ADA (ELAK JSP MATI)
        request.setAttribute("employees", employees);
        request.setAttribute("leaveTypes", leaveTypes);
        request.setAttribute("balanceIndex", balanceIndex);

        request.getRequestDispatcher("leaveEmpBalances.jsp").forward(request, response);
    }
}
