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
@MultipartConfig(fileSizeThreshold = 1024 * 1024, // 1MB
		maxFileSize = 5 * 1024 * 1024, // 5MB
		maxRequestSize = 10 * 1024 * 1024 // 10MB
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
			response.sendRedirect("login.jsp?error=" + url("Please login."));
			return;
		}

		try {
			int empid = Integer.parseInt(String.valueOf(session.getAttribute("empid")));
			User user = userDAO.getUserById(empid);

			if (user == null) {
				response.sendRedirect("login.jsp?error=" + url("User not found."));
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
			response.sendRedirect("login.jsp?error=" + url("Please login."));
			return;
		}

		int empid = Integer.parseInt(String.valueOf(session.getAttribute("empid")));

		// Retrieve and sanitize fields
		String phone = request.getParameter("phone");
		String street = request.getParameter("street");
		String city = request.getParameter("city");
		String postalCode = request.getParameter("postalCode");
		String state = request.getParameter("state");

		if (city != null && city.matches(".*\\d.*")) {
			response.sendRedirect("Profile?edit=1&error=" + url("City name cannot contain numbers."));
			return;
		}

		try {
			User user = new User();
			user.setEmpId(empid);

			user.setPhone(phone != null ? phone.trim() : "");
			user.setStreet(street != null ? street.trim().toUpperCase() : "");
			user.setCity(city != null ? city.trim().toUpperCase() : "");
			user.setPostalCode(postalCode != null ? postalCode.trim() : "");
			user.setState(state != null ? state.trim().toUpperCase() : "");

			Part profilePicPart = request.getPart("profilePic");
			if (profilePicPart != null && profilePicPart.getSize() > 0) {
				String contentType = profilePicPart.getContentType();
				if (contentType == null || !contentType.startsWith("image/")) {
					response.sendRedirect("Profile?edit=1&error=" + url("Profile picture must be an image."));
					return;
				}

				String uploadsDir = getUploadDir(request);
				File dir = new File(uploadsDir);
				if (!dir.exists())
					dir.mkdirs();

				String submitted = Paths.get(profilePicPart.getSubmittedFileName()).getFileName().toString();
				String ext = submitted.substring(submitted.lastIndexOf('.'));
				String fileName = "emp_" + empid + "_" + System.currentTimeMillis() + ext;

				profilePicPart.write(uploadsDir + File.separator + fileName);
				String relativePath = "uploads/" + fileName;

				user.setProfilePic(relativePath);
				session.setAttribute("profilePic", relativePath);
			}

			// Execute Update
			if (userDAO.updateProfile(user)) {
				response.sendRedirect("Profile?message=success");
			} else {
				response.sendRedirect("Profile?edit=1&error=" + url("Update failed. Please check your data."));
			}

		} catch (Exception e) {
			e.printStackTrace();
			response.sendRedirect("Profile?edit=1&error=" + url("Error: " + e.getMessage()));
		}
	}

	private String url(String s) {
		return URLEncoder.encode(s, StandardCharsets.UTF_8);
	}
}