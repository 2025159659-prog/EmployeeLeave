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
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Scanner;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonDeserializer;
import com.google.gson.JsonObject;
import com.google.gson.JsonSerializer;
import com.google.gson.reflect.TypeToken;

import bean.Holiday;
import dao.HolidayDAO;

@WebServlet("/ManageHoliday")
public class ManageHoliday extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final String API_URL = "https://holiday-service-48048ca7054c.herokuapp.com/api/holidays";
    private final HolidayDAO holidayDAO = new HolidayDAO();
    
    private final Gson gson = new GsonBuilder()
        .registerTypeAdapter(LocalDate.class, (com.google.gson.JsonSerializer<LocalDate>) (src, typeOfSrc, context) -> new com.google.gson.JsonPrimitive(src.toString()))
        .registerTypeAdapter(LocalDate.class, (com.google.gson.JsonDeserializer<LocalDate>) (json, typeOfT, context) -> LocalDate.parse(json.getAsString()))
        .registerTypeAdapter(Holiday.class, (com.google.gson.JsonDeserializer<Holiday>) (json, typeOfT, context) -> {
            JsonObject obj = json.getAsJsonObject();
            Holiday h = new Holiday();
            if (obj.has("id")) h.setId(obj.get("id").getAsInt());
            if (obj.has("holidayName")) h.setName(obj.get("holidayName").getAsString());
            if (obj.has("holidayDate")) h.setDate(LocalDate.parse(obj.get("holidayDate").getAsString()));
            if (obj.has("holidayType") && !obj.get("holidayType").isJsonNull()) h.setType(obj.get("holidayType").getAsString());
            return h;
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

        List<Holiday> combinedHolidays = new ArrayList<>();

        // 1. Ambil dari DB Tempatan
        try {
            List<Holiday> localList = holidayDAO.getAllHolidays();
            if (localList != null) combinedHolidays.addAll(localList);
        } catch (Exception e) { e.printStackTrace(); }

        // 2. Ambil dari Microservice
        try {
            URL url = new URL(API_URL);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("GET");
            if (conn.getResponseCode() == 200) {
                Scanner scanner = new Scanner(conn.getInputStream());
                StringBuilder sb = new StringBuilder();
                while (scanner.hasNextLine()) sb.append(scanner.nextLine());
                scanner.close();
                List<Holiday> apiList = gson.fromJson(sb.toString(), new TypeToken<ArrayList<Holiday>>(){}.getType());
                if (apiList != null) combinedHolidays.addAll(apiList);
            }
        } catch (Exception e) { e.printStackTrace(); }

        request.setAttribute("holidays", combinedHolidays);
        request.getRequestDispatcher("/holidays.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String action = request.getParameter("action");
        try {
            // ================= DELETE =================
            if ("DELETE".equalsIgnoreCase(action)) {
                int id = Integer.parseInt(request.getParameter("holidayId"));
                
                // Padam di DB Tempatan
                holidayDAO.deleteHoliday(id);
                
                // Cuba padam di Microservice (Guna try-catch supaya jika tiada di cloud pun, proses jalan terus)
                try {
                    sendApiRequest(API_URL + "/" + id, "DELETE", null);
                } catch (Exception e) { System.err.println("Tiada di Cloud: " + e.getMessage()); }

                response.sendRedirect("ManageHoliday?msg=Holiday+deleted+from+both+systems");
                return;
            }

            String name = request.getParameter("holidayName");
            String dateStr = request.getParameter("holidayDate");
            String type = request.getParameter("holidayType");
            
            Holiday h = new Holiday();
            h.setName(name);
            h.setDate(LocalDate.parse(dateStr));
            h.setType(type);

            Map<String, Object> apiData = new HashMap<>();
            apiData.put("holidayName", name);
            apiData.put("holidayDate", dateStr);
            apiData.put("holidayType", type);

            // ================= ADD =================
            if ("ADD".equalsIgnoreCase(action)) {
                // Simpan ke DB Tempatan (Supaya masuk dalam database 'leave' anda)
                holidayDAO.addHoliday(h);
                
                // Simpan ke Microservice
                sendApiRequest(API_URL, "POST", apiData);
                
                response.sendRedirect("ManageHoliday?msg=Holiday+added+successfully+to+both");

            // ================= UPDATE =================
            } else if ("UPDATE".equalsIgnoreCase(action)) {
                int id = Integer.parseInt(request.getParameter("holidayId"));
                h.setId(id);
                apiData.put("id", id);

                // Kemaskini DB Tempatan
                holidayDAO.updateHoliday(h);
                
                // Kemaskini Microservice
                try {
                    sendApiRequest(API_URL + "/" + id, "PUT", apiData);
                } catch (Exception e) { System.err.println("Gagal kemaskini Cloud: " + e.getMessage()); }
                
                response.sendRedirect("ManageHoliday?msg=Holiday+updated+successfully");
            }
        } catch (Exception e) {
            response.sendRedirect("ManageHoliday?error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        }
    }

    private void sendApiRequest(String urlStr, String method, Object data) throws Exception {
        URL url = new URL(urlStr);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setConnectTimeout(5000); // Set timeout 5 saat
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
        // Hanya balingan ralat jika ralat teruk (bukan 404)
        if (code >= 500) {
            throw new RuntimeException("API Server Error: HTTP " + code);
        }
        conn.disconnect();
    }
}
