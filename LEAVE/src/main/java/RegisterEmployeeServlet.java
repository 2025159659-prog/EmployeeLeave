import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.*;

@WebServlet("/RegisterEmployeeServlet")
public class RegisterEmployeeServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("role") == null ||
                !"ADMIN".equalsIgnoreCase(session.getAttribute("role").toString())) {
            response.sendRedirect("login.jsp?error=" + url("Please login as admin."));
            return;
        }

        request.getRequestDispatcher("adminRegisterEmployee.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("role") == null ||
                !"ADMIN".equalsIgnoreCase(session.getAttribute("role").toString())) {
            response.sendRedirect("login.jsp?error=" + url("Please login as admin."));
            return;
        }

        // 1. Retrieve Basic Parameters
        String fullname = request.getParameter("fullname");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String icNumber = request.getParameter("icNumber");
        String gender = request.getParameter("gender");
        String phoneNo = request.getParameter("phoneNo");
        String hireDate = request.getParameter("hireDate");
        String role = request.getParameter("role");

        // 2. Retrieve New Address Parameters
        String street = request.getParameter("street");
        String city = request.getParameter("city");
        String postalCode = request.getParameter("postalCode");
        String state = request.getParameter("state");

        // 3. Validation (Included new address fields)
        if (fullname == null || email == null || password == null || icNumber == null ||
            street == null || city == null || postalCode == null || state == null ||
            fullname.isBlank() || email.isBlank() || password.isBlank() || icNumber.isBlank() ||
            street.isBlank() || city.isBlank() || postalCode.isBlank() || state.isBlank()) {
            
            response.sendRedirect("RegisterEmployeeServlet?error=" + url("Please fill all required fields including full address."));
            return;
        }

        // 4. Updated SQL to match new table structure
        String sql =
            "INSERT INTO USERS " +
            "(FULLNAME, EMAIL, PASSWORD, GENDER, HIREDATE, PHONENO, " +
            "STREET, CITY, POSTAL_CODE, STATE, IC_NUMBER, ROLE, STATUS, PROFILE_PICTURE) " +
            "VALUES (?, ?, ?, ?, TO_DATE(?, 'YYYY-MM-DD'), ?, ?, ?, ?, ?, ?, ?, 'ACTIVE', NULL)";

        try (Connection con = DatabaseConnection.getConnection()) {

            // Check duplicate email
            try (PreparedStatement chk = con.prepareStatement(
                    "SELECT COUNT(*) FROM USERS WHERE EMAIL = ?")) {
                chk.setString(1, email.trim());
                try (ResultSet rs = chk.executeQuery()) {
                    rs.next();
                    if (rs.getInt(1) > 0) {
                        response.sendRedirect("RegisterEmployeeServlet?error=" + url("Email already exists."));
                        return;
                    }
                }
            }

            // Execute Insert
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setString(1, fullname.trim());
                ps.setString(2, email.trim());
                ps.setString(3, password); 
                ps.setString(4, gender);
                ps.setString(5, hireDate);
                ps.setString(6, phoneNo == null ? "" : phoneNo.trim());
                
                // Address Mapping
                ps.setString(7, street.trim());
                ps.setString(8, city.trim());
                ps.setString(9, postalCode.trim());
                ps.setString(10, state.trim());
                
                ps.setString(11, icNumber.trim());
                ps.setString(12, role);

                ps.executeUpdate();
            }

            response.sendRedirect("RegisterEmployeeServlet?msg=" + url("Employee registered successfully."));

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("RegisterEmployeeServlet?error=" + url("Registration failed: " + e.getMessage()));
        }
    }

    private String url(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }
}