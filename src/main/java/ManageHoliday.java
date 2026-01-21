import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.time.LocalDate;
import java.util.List;
import dao.HolidayDAO;
import bean.Holiday;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Scanner;

/**
 * Unified Controller for Holiday Management (View, Add, Update, Delete).
 * Restricts access to ADMIN role.
 */
@WebServlet("/ManageHoliday")
public class ManageHoliday extends HttpServlet {
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

        try {
                // URL microservice anda di Heroku nanti
                // Untuk sekarang, kita guna placeholder atau URL Heroku holiday-service anda
                URL url = new URL("https://holiday-service-48048ca7054c.herokuapp.com/api/holidays");
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setRequestMethod("GET");
                conn.connect();
            
                int responseCode = conn.getResponseCode();
                if (responseCode != 200) {
                    throw new RuntimeException("HttpResponseCode: " + responseCode);
                } else {
                    StringBuilder informationString = new StringBuilder();
                    Scanner scanner = new Scanner(url.openStream());
            
                    while (scanner.hasNext()) {
                        informationString.append(scanner.next());
                    }
                    scanner.close();
            
                    // Tukar JSON ke List
                    Gson gson = new Gson();
                    java.lang.reflect.Type listType = new TypeToken<ArrayList<Holiday>>(){}.getType();
                    ArrayList<Holiday> holidayList = gson.fromJson(informationString.toString(), listType);
            
                    request.setAttribute("holidayList", holidayList);
                }
            } catch (Exception e) {
                e.printStackTrace();
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
            if (action == null) {
                response.sendRedirect("ManageHoliday?error=Invalid+Action");
                return;
            }

            // ================= DELETE =================
            if ("DELETE".equalsIgnoreCase(action)) {
                int id = Integer.parseInt(request.getParameter("holidayId"));
                holidayDAO.deleteHoliday(id);
                response.sendRedirect("ManageHoliday?msg=Holiday+deleted+successfully");
                return;
            }

            // ================= ADD / UPDATE =================
            String name = request.getParameter("holidayName");
            String dateStr = request.getParameter("holidayDate");
            String type = request.getParameter("holidayType");

            Holiday h = new Holiday();
            h.setName(name);
            h.setDate(LocalDate.parse(dateStr));
            h.setType(type.toUpperCase()); // ⭐ CRITICAL FIX ⭐

            if ("ADD".equalsIgnoreCase(action)) {
                holidayDAO.addHoliday(h);
                response.sendRedirect("ManageHoliday?msg=Holiday+added+successfully");

            } else if ("UPDATE".equalsIgnoreCase(action)) {
                h.setId(Integer.parseInt(request.getParameter("holidayId")));
                holidayDAO.updateHoliday(h);
                response.sendRedirect("ManageHoliday?msg=Holiday+updated+successfully");

            } else {
                response.sendRedirect("ManageHoliday?error=Unknown+Action");
            }

        } catch (Exception e) {
            response.sendRedirect(
                "ManageHoliday?error=" +
                java.net.URLEncoder.encode(e.getMessage(), "UTF-8")
            );
        }
    }
}


