@WebServlet("/ChangePassword")
public class ChangePassword extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("empid") == null) {
            response.sendRedirect("login.jsp?error=Session expired");
            return;
        }

        int empId = Integer.parseInt(String.valueOf(session.getAttribute("empid")));

        // 🔥 FIXED: ikut JSP name
        String currentPassword = request.getParameter("oldPassword");
        String newPassword     = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        // 🔒 Validation
        if (currentPassword == null || newPassword == null || confirmPassword == null ||
            currentPassword.isBlank() || newPassword.isBlank() || confirmPassword.isBlank()) {

            response.sendRedirect("ChangePassword?error=" +
                    URLEncoder.encode("All fields are required", "UTF-8"));
            return;
        }

        if (!newPassword.equals(confirmPassword)) {
            response.sendRedirect("ChangePassword?error=" +
                    URLEncoder.encode("Passwords do not match", "UTF-8"));
            return;
        }

        try (Connection con = DatabaseConnection.getConnection()) {

            // 1️⃣ Verify current password
            String dbPassword = null;

            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT password FROM leave.users WHERE empid = ?")) {

                ps.setInt(1, empId);
                ResultSet rs = ps.executeQuery();

                if (rs.next()) {
                    dbPassword = rs.getString("password");
                } else {
                    response.sendRedirect("ChangePassword?error=" +
                            URLEncoder.encode("User not found", "UTF-8"));
                    return;
                }
            }

            if (!currentPassword.equals(dbPassword)) {
                response.sendRedirect("ChangePassword?error=" +
                        URLEncoder.encode("Current password is incorrect", "UTF-8"));
                return;
            }

            // 2️⃣ Update password
            try (PreparedStatement ps = con.prepareStatement(
                    "UPDATE leave.users SET password = ? WHERE empid = ?")) {

                ps.setString(1, newPassword);
                ps.setInt(2, empId);
                ps.executeUpdate();
            }

            response.sendRedirect("ChangePassword?msg=" +
                    URLEncoder.encode("Password updated successfully", "UTF-8"));

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("ChangePassword?error=" +
                    URLEncoder.encode("Database error", "UTF-8"));
        }
    }
}
