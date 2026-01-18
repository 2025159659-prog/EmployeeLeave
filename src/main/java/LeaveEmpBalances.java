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

@WebServlet("/LeaveEmpBalances")
public class LeaveEmpBalances extends HttpServlet {

    private final UserDAO userDAO = new UserDAO();
    private final LeaveDAO leaveDAO = new LeaveDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null ||
            session.getAttribute("role") == null ||
            !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {

            response.sendRedirect("login.jsp?error=Admin+access+required");
            return;
        }

        try (Connection con = DatabaseConnection.getConnection()) {

            /* =====================================================
             * 1️⃣ EMPLOYEES (EMPLOYEE ONLY)
             * ===================================================== */
            List<User> employees = userDAO.getAllUsers()
                    .stream()
                    .filter(u -> "EMPLOYEE".equalsIgnoreCase(u.getRole()))
                    .toList();

            /* =====================================================
             * 2️⃣ LEAVE TYPES
             * id  -> Integer
             * code-> String
             * (MATCH JSP: t.get("id"), t.get("code"))
             * ===================================================== */
            List<Map<String, Object>> leaveTypes = leaveDAO.getAllLeaveTypes();

            /* =====================================================
             * 3️⃣ LEAVE BALANCE INDEX
             * Map<empId, Map<leaveTypeId, LeaveBalance>>
             * ===================================================== */
            LeaveBalanceDAO lbDAO = new LeaveBalanceDAO(con);
            Map<Integer, Map<Integer, LeaveBalance>> balanceIndex = new HashMap<>();

            for (User emp : employees) {
                Map<Integer, LeaveBalance> perEmp = new HashMap<>();

                List<LeaveBalance> balances = lbDAO.getEmployeeBalances(emp.getEmpId());
                for (LeaveBalance b : balances) {
                    perEmp.put(b.getLeaveTypeId(), b);
                }

                balanceIndex.put(emp.getEmpId(), perEmp);
            }

            /* =====================================================
             * 4️⃣ SEND TO JSP
             * ===================================================== */
            request.setAttribute("employees", employees);
            request.setAttribute("leaveTypes", leaveTypes);
            request.setAttribute("balanceIndex", balanceIndex);

            request.getRequestDispatcher("leaveEmpBalances.jsp")
                   .forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "System Error: " + e.getMessage());
            request.getRequestDispatcher("leaveEmpBalances.jsp")
                   .forward(request, response);
        }
    }
}
