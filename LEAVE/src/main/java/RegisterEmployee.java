import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import bean.User;
import dao.UserDAO;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;

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
            newUser.setIcNumber(request.getParameter("icNumber"));
            newUser.setGender(request.getParameter("gender"));
            newUser.setPhone(request.getParameter("phoneNo"));
            newUser.setStreet(request.getParameter("street"));
            newUser.setCity(request.getParameter("city"));
            newUser.setPostalCode(request.getParameter("postalCode"));
            newUser.setState(request.getParameter("state"));

            // Parse Date
            String dateStr = request.getParameter("hireDate");
            if (dateStr != null && !dateStr.isEmpty()) {
                newUser.setHireDate(new SimpleDateFormat("yyyy-MM-dd").parse(dateStr));
            }

            // 2. Use DAO to register
            UserDAO dao = new UserDAO();
            boolean success = dao.registerUser(newUser);

            if (success) {
                response.sendRedirect("RegisterEmployee?msg=" + url("Employee registered successfully."));
            } else {
                response.sendRedirect("RegisterEmployee?error=" + url("Failed to create account."));
            }

        } catch (Exception e) {
            response.sendRedirect("RegisterEmployee?error=" + url(e.getMessage()));
        }
    }

    private String url(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }
}