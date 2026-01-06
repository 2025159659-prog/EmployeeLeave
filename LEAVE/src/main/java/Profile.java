

import bean.User;
import dao.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.File;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Paths;

@WebServlet("/Profile")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,      // 1MB
    maxFileSize = 5 * 1024 * 1024,        // 5MB
    maxRequestSize = 10 * 1024 * 1024     // 10MB
)
public class Profile extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final UserDAO userDAO = new UserDAO();

    private String getUploadDir(HttpServletRequest request) {
        String appPath = request.getServletContext().getRealPath("");
        return appPath + File.separator + "uploads";
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("empid") == null) {
            response.sendRedirect("login.jsp?error=Please login.");
            return;
        }

        try {
            int empid = Integer.parseInt(String.valueOf(session.getAttribute("empid")));
            User user = userDAO.getUserById(empid);

            if (user == null) {
                response.sendRedirect("login.jsp?error=User not found.");
                return;
            }

            request.setAttribute("user", user);
            request.getRequestDispatcher("profile.jsp").forward(request, response);

        } catch (Exception e) {
            throw new ServletException("Error loading profile", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("empid") == null) {
            response.sendRedirect("login.jsp?error=Please login.");
            return;
        }

        int empid = Integer.parseInt(String.valueOf(session.getAttribute("empid")));
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String address = request.getParameter("address");

        if (email == null || email.isBlank()) {
            response.sendRedirect("Profile?edit=1&error=Email is required.");
            return;
        }

        try {
            User user = new User();
            user.setEmpId(empid);
            user.setEmail(email);
            user.setPhone(phone);
            user.setAddress(address);

            // Handle Profile Picture Upload
            Part profilePicPart = request.getPart("profilePic");
            if (profilePicPart != null && profilePicPart.getSize() > 0) {
                String contentType = profilePicPart.getContentType();
                if (contentType == null || !contentType.startsWith("image/")) {
                    response.sendRedirect("Profile?edit=1&error=Profile picture must be an image.");
                    return;
                }

                String uploadsDir = getUploadDir(request);
                File dir = new File(uploadsDir);
                if (!dir.exists()) dir.mkdirs();

                String submitted = Paths.get(profilePicPart.getSubmittedFileName()).getFileName().toString();
                String ext = submitted.substring(submitted.lastIndexOf('.'));
                String fileName = "emp_" + empid + "_" + System.currentTimeMillis() + ext;
                
                profilePicPart.write(uploadsDir + File.separator + fileName);
                String relativePath = "uploads/" + fileName;
                
                user.setProfilePic(relativePath);
                session.setAttribute("profilePic", relativePath); // Update topbar
            }

            if (userDAO.updateProfile(user)) {
                response.sendRedirect("Profile?msg=" + URLEncoder.encode("Profile updated successfully.", StandardCharsets.UTF_8));
            } else {
                response.sendRedirect("Profile?error=Update failed.");
            }

        } catch (java.sql.SQLIntegrityConstraintViolationException e) {
            response.sendRedirect("Profile?edit=1&error=Email already exists.");
        } catch (Exception e) {
            throw new ServletException("Error updating profile", e);
        }
    }
}