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

        try (Connection con = DatabaseConnection.getConnection()) {

            // 1️⃣ Employees
            List<User> employees = userDAO.getAllUsers();

            // 2️⃣ Leave types (KEY id & code)
            List<Map<String, Object>> leaveTypes = leaveDAO.getAllLeaveTypes();

            // 3️⃣ Balances
            LeaveBalanceDAO lbDAO = new LeaveBalanceDAO(con);
            Map<Integer, Map<Integer, LeaveBalance>> balanceIndex = new HashMap<>();

            for (User u : employees) {
                Map<Integer, LeaveBalance> map = new HashMap<>();
                for (LeaveBalance b : lbDAO.getEmployeeBalances(u.getEmpId())) {
                    map.put(b.getLeaveTypeId(), b);
                }
                balanceIndex.put(u.getEmpId(), map);
            }

            request.setAttribute("employees", employees);
            request.setAttribute("leaveTypes", leaveTypes);
            request.setAttribute("balanceIndex", balanceIndex);

            request.getRequestDispatcher("leaveEmpBalances.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "System Error: " + e.getMessage());
            request.getRequestDispatcher("leaveEmpBalances.jsp").forward(request, response);
        }
    }
}

