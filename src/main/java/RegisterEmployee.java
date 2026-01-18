import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

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
import java.time.LocalDate;


@WebServlet("/RegisterEmployee")
public class RegisterEmployee extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("adminRegisterEmployee.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        try {
            User newUser = new User();
            newUser.setFullName(request.getParameter("fullname"));
            newUser.setEmail(request.getParameter("email"));
            newUser.setPassword(request.getParameter("password"));

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

            String dateStr = request.getParameter("hireDate");
            if (dateStr != null && !dateStr.isEmpty()) {
                newUser.setHireDate(
                        java.sql.Date.valueOf(LocalDate.parse(dateStr))
                );
            }

            UserDAO dao = new UserDAO();
            boolean success = dao.registerUser(newUser);

            if (success) {
                initializeBalancesForNewUser(newUser.getEmail());
                response.sendRedirect("RegisterEmployee?msg=Employee+registered+successfully");
            } else {
                response.sendRedirect("RegisterEmployee?error=Failed+to+register");
            }

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("RegisterEmployee?error=" +
                    java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        }
    }

    private void initializeBalancesForNewUser(String email) throws Exception {
        try (Connection con = DatabaseConnection.getConnection()) {

            int empId = 0;
            String gender = "";
            Date hireDate = null;

            String sql = "SELECT empid, gender, hiredate FROM leave.users WHERE email = ?";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, email);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        empId = rs.getInt("empid");
                        gender = rs.getString("gender");
                        hireDate = rs.getDate("hiredate");
                    }
                }
            }

            if (empId > 0 && hireDate != null) {
                LeaveBalanceDAO lbDAO = new LeaveBalanceDAO(con);
                lbDAO.initializeNewEmployeeBalances(
                        empId,
                        hireDate.toLocalDate(),
                        gender
                );
            }
        }
    }
}

