import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.time.LocalDate;
import java.util.List;
import dao.HolidayDAO;
import bean.Holiday;

/**
 * Unified Controller for Holiday Management (View, Add, Update, Delete).
 * Restricts access to ADMIN role.
 */
@WebServlet("/ManageHolidays")
public class ManageHolidays extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final HolidayDAO holidayDAO = new HolidayDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect("login.jsp?error=Unauthorized+Access");
            return;
        }

        try {
            List<Holiday> list = holidayDAO.getAllHolidays();
            request.setAttribute("holidays", list);
            request.getRequestDispatcher("/holidays.jsp").forward(request, response);
        } catch (Exception e) {
            request.setAttribute("error", e.getMessage());
            request.getRequestDispatcher("/holidays.jsp").forward(request, response);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect("login.jsp");
            return;
        }

        String action = request.getParameter("action");
        try {
            if ("DELETE".equals(action)) {
                int id = Integer.parseInt(request.getParameter("holidayId"));
                holidayDAO.deleteHoliday(id);
                response.sendRedirect("ManageHolidays?msg=Holiday+deleted+successfully");
                return;
            }

            // Extract common parameters for ADD and UPDATE
            String name = request.getParameter("holidayName");
            String dateStr = request.getParameter("holidayDate");
            String type = request.getParameter("holidayType");

            Holiday h = new Holiday();
            h.setName(name);
            h.setType(type);
            h.setDate(LocalDate.parse(dateStr)); // Standard ISO format (YYYY-MM-DD) from HTML5 input

            if ("ADD".equals(action)) {
                holidayDAO.addHoliday(h);
                response.sendRedirect("ManageHolidays?msg=Holiday+added+successfully");
            } else if ("UPDATE".equals(action)) {
                h.setId(Integer.parseInt(request.getParameter("holidayId")));
                holidayDAO.updateHoliday(h);
                response.sendRedirect("ManageHolidays?msg=Holiday+updated+successfully");
            }

        } catch (Exception e) {
            response.sendRedirect("ManageHolidays?error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        }
    }
}