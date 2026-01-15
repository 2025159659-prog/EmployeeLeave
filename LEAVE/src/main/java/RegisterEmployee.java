import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import bean.User;
import dao.UserDAO;
import dao.LeaveBalanceDAO;
import util.DatabaseConnection;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.time.ZoneId;

@WebServlet("/RegisterEmployee")
public class RegisterEmployee extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        request.getRequestDispatcher("adminRegisterEmployee.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            // 1. Setup User Bean
            User newUser = new User();
            newUser.setFullName(request.getParameter("fullname"));
            newUser.setEmail(request.getParameter("email"));
            newUser.setPassword(request.getParameter("password"));
            
            // FIX ORA-12899: Strip dashes from IC Number for DB constraint (max 12)
            String rawIc = request.getParameter("icNumber");
            if (rawIc != null) {
                newUser.setIcNumber(rawIc.replace("-", ""));
            }
            
            newUser.setGender(request.getParameter("gender"));
            newUser.setPhone(request.getParameter("phoneNo"));
            newUser.setStreet(request.getParameter("street"));
            newUser.setCity(request.getParameter("city"));
            newUser.setPostalCode(request.getParameter("postalCode"));
            newUser.setState(request.getParameter("state"));

            // Parse Hire Date
            String dateStr = request.getParameter("hireDate");
            if (dateStr != null && !dateStr.isEmpty()) {
                newUser.setHireDate(new SimpleDateFormat("yyyy-MM-dd").parse(dateStr));
            }

            // 2. Use DAO to register
            UserDAO dao = new UserDAO();
            boolean success = dao.registerUser(newUser);

            if (success) {
                // 3. Initialize Leave Balances Immediately
                initializeBalancesForNewUser(newUser.getEmail());
                
                response.sendRedirect("RegisterEmployee?msg=" + url("Employee registered and leave balances initialized."));
            } else {
                response.sendRedirect("RegisterEmployee?error=" + url("Failed to create account."));
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("RegisterEmployee?error=" + url(e.getMessage()));
        }
    }

    /**
     * Helper method to fetch the new EMPID and trigger Balance initialization
     */
    private void initializeBalancesForNewUser(String email) throws Exception {
        // Use a single connection for the lookup and the DAO initialization
        try (Connection con = DatabaseConnection.getConnection()) {
            int empId = 0;
            String gender = "";
            java.sql.Date hireDateSql = null;

            // Fetch newly created user info
            String idSql = "SELECT EMPID, GENDER, HIREDATE FROM USERS WHERE EMAIL = ?";
            try (PreparedStatement ps = con.prepareStatement(idSql)) {
                ps.setString(1, email);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        empId = rs.getInt("EMPID");
                        gender = rs.getString("GENDER");
                        hireDateSql = rs.getDate("HIREDATE");
                    }
                }
            }

            if (empId > 0 && hireDateSql != null) {
                LocalDate localHireDate = hireDateSql.toLocalDate();
                LeaveBalanceDAO lbDAO = new LeaveBalanceDAO(con);
                // This now inserts into LEAVE_BALANCES with correct column names
                lbDAO.initializeNewEmployeeBalances(empId, localHireDate, gender);
            }
        }
    }

    private String url(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }
}