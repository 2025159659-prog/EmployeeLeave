import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.OutputStream;
import java.lang.reflect.Type;
import java.net.HttpURLConnection;
import java.net.URL;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

// Import tambahan untuk GSON TypeAdapter
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonDeserializationContext;
import com.google.gson.JsonDeserializer;
import com.google.gson.JsonElement;
import com.google.gson.JsonParseException;
import com.google.gson.JsonPrimitive;
import com.google.gson.JsonSerializationContext;
import com.google.gson.JsonSerializer;
import com.google.gson.reflect.TypeToken;
import bean.Holiday;

@WebServlet("/ManageHoliday")
public class ManageHoliday extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final String API_URL = "https://holiday-service-48048ca7054c.herokuapp.com/api/holidays";
    
    // ⭐ KONFIGURASI GSON UNTUK JAVA 21 (LOCALDATE FIX) ⭐
    private final Gson gson = new GsonBuilder()
        .registerTypeAdapter(LocalDate.class, new JsonSerializer<LocalDate>() {
            @Override
            public JsonElement serialize(LocalDate src, Type typeOfSrc, JsonSerializationContext context) {
                return new JsonPrimitive(src.toString()); // Simpan sebagai "yyyy-MM-dd"
            }
        })
        .registerTypeAdapter(LocalDate.class, new JsonDeserializer<LocalDate>() {
            @Override
            public LocalDate deserialize(JsonElement json, Type typeOfT, JsonDeserializationContext context) throws JsonParseException {
                return LocalDate.parse(json.getAsString()); // Baca dari "yyyy-MM-dd"
            }
        })
        .create();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
            response.sendRedirect("login.jsp?error=Unauthorized+Access");
            return;
        }

        try {
            URL url = new URL(API_URL);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            conn.setRequestProperty("Accept", "application/json");

            if (conn.getResponseCode() == 200) {
                Scanner scanner = new Scanner(conn.getInputStream());
                StringBuilder sb = new StringBuilder();
                while (scanner.hasNextLine()) {
                    sb.append(scanner.nextLine());
                }
                scanner.close();

                List<Holiday> holidayList = gson.fromJson(sb.toString(), new TypeToken<ArrayList<Holiday>>(){}.getType());
                request.setAttribute("holidays", holidayList);
            } else {
                request.setAttribute("error", "API Error: HTTP " + conn.getResponseCode());
            }

            request.getRequestDispatcher("/holidays.jsp").forward(request, response);
        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Ralat: " + e.getMessage());
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
            if ("DELETE".equalsIgnoreCase(action)) {
                String id = request.getParameter("holidayId");
                sendApiRequest(API_URL + "/" + id, "DELETE", null);
                response.sendRedirect("ManageHoliday?msg=Holiday+deleted+successfully");
                return;
            }

            String name = request.getParameter("holidayName");
            String dateStr = request.getParameter("holidayDate");
            
            Holiday h = new Holiday();
            h.setName(name); 
            h.setDate(LocalDate.parse(dateStr));

            if ("ADD".equalsIgnoreCase(action)) {
                sendApiRequest(API_URL, "POST", h);
                response.sendRedirect("ManageHoliday?msg=Holiday+added+successfully");

            } else if ("UPDATE".equalsIgnoreCase(action)) {
                String id = request.getParameter("holidayId");
                h.setId(Integer.parseInt(id));
                sendApiRequest(API_URL + "/" + id, "PUT", h);
                response.sendRedirect("ManageHoliday?msg=Holiday+updated+successfully");
            }

        } catch (Exception e) {
            response.sendRedirect("ManageHoliday?error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        }
    }

    private void sendApiRequest(String urlStr, String method, Object data) throws Exception {
        URL url = new URL(urlStr);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod(method);
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setDoOutput(true);

        if (data != null) {
            String jsonInputString = gson.toJson(data);
            try (OutputStream os = conn.getOutputStream()) {
                byte[] input = jsonInputString.getBytes("utf-8");
                os.write(input, 0, input.length);
            }
        }

        int code = conn.getResponseCode();
        if (code < 200 || code >= 300) {
            throw new RuntimeException("API Error: HTTP " + code);
        }
        conn.disconnect();
    }
}
