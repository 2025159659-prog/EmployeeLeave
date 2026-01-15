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
    private static final long serialVersionUID = 1L;
    private final UserDAO userDAO = new UserDAO();
    private final LeaveDAO leaveDAO = new LeaveDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect("login.jsp?error=Admin+access+required");
            return;
        }

        try (Connection con = DatabaseConnection.getConnection()) {
            // 1. Get all users
            List<User> allUsers = userDAO.getAllUsers();
            
            // 2. Filter list to include ONLY those with the role 'EMPLOYEE'
            // This excludes 'MANAGER' and 'ADMIN' roles from the display
            List<User> employeesOnly = allUsers.stream()
                .filter(u -> "EMPLOYEE".equalsIgnoreCase(u.getRole()))
                .collect(Collectors.toList());
            
            // 3. Get all leave types for the table column headers
            List<Map<String, Object>> leaveTypes = leaveDAO.getAllLeaveTypes();
            
            // 4. Map to store balances indexed by EmpID then LeaveTypeID
            // Structure: Map<UserId, Map<LeaveTypeId, LeaveBalanceBean>>
            Map<Integer, Map<Integer, LeaveBalance>> balanceIndex = new HashMap<>();
            LeaveBalanceDAO lbDAO = new LeaveBalanceDAO(con);

            for (User u : employeesOnly) {
                List<LeaveBalance> bals = lbDAO.getEmployeeBalances(u.getEmpId());
                Map<Integer, LeaveBalance> typeMap = new HashMap<>();
                for (LeaveBalance b : bals) {
                    typeMap.put(b.getLeaveTypeId(), b);
                }
                balanceIndex.put(u.getEmpId(), typeMap);
            }

            // 5. Set attributes matching the JSP requirements
            request.setAttribute("employees", employeesOnly);
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