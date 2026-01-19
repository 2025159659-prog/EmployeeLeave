import bean.Attachment;
import dao.AttachmentDAO;
import util.DatabaseConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.*;
import java.sql.Connection;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@WebServlet("/ViewAttachment")
public class ViewAttachment extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private AttachmentDAO attachmentDAO;

    @Override
    public void init() {
        attachmentDAO = new AttachmentDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        /* =====================================================
           1. SECURITY CHECK
           ===================================================== */
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("empid") == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED,
                    "Please login to view attachments.");
            return;
        }

        /* =====================================================
           2. VALIDATE PARAMETER
           ===================================================== */
        String idStr = request.getParameter("id");
        if (idStr == null || idStr.isBlank()) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                    "Missing Leave ID");
            return;
        }

        int leaveId;
        try {
            leaveId = Integer.parseInt(idStr);
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST,
                    "Invalid Leave ID");
            return;
        }

        /* =====================================================
           3. FETCH ATTACHMENT
           ===================================================== */
        try (Connection conn = DatabaseConnection.getConnection()) {

            Attachment attachment =
                    attachmentDAO.getLatestAttachmentByLeaveId(leaveId, conn);

            if (attachment == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND,
                        "Attachment not found.");
                return;
            }

            /* =====================================================
               4. DETERMINE SAFE CONTENT TYPE
               ===================================================== */
            String contentType = attachment.getContentType();

            // 🔒 Whitelist common safe types
            if (contentType == null ||
                (!contentType.equalsIgnoreCase("application/pdf")
                 && !contentType.startsWith("image/")
                 && !contentType.equalsIgnoreCase("text/plain"))) {

                // fallback SAFE type (avoid octet-stream)
                contentType = "application/pdf";
            }

            /* =====================================================
               5. SAFE FILENAME HANDLING
               ===================================================== */
            String fileName = attachment.getFileName();
            if (fileName == null || fileName.isBlank()) {
                fileName = "document.pdf";
            }

            // sanitize filename
            fileName = fileName.replaceAll("[\\r\\n\"]", "_");

            // RFC 5987 encoding for Chrome
            String encodedFileName =
                    URLEncoder.encode(fileName, StandardCharsets.UTF_8)
                              .replace("+", "%20");

            /* =====================================================
               6. SECURITY HEADERS (CRITICAL)
               ===================================================== */
            response.reset();
            response.setContentType(contentType);

            // INLINE view (not download)
            response.setHeader(
                    "Content-Disposition",
                    "inline; filename=\"" + fileName + "\"; filename*=UTF-8''" + encodedFileName
            );

            // 🔴 MOST IMPORTANT FOR GOOGLE WARNING
            response.setHeader("X-Content-Type-Options", "nosniff");

            // Extra hardening (safe defaults)
            response.setHeader("X-Frame-Options", "SAMEORIGIN");
            response.setHeader("Referrer-Policy", "no-referrer");
            response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
            response.setHeader("Pragma", "no-cache");

            /* =====================================================
               7. STREAM FILE
               ===================================================== */
            try (InputStream in = attachment.getDataStream();
                 OutputStream out = response.getOutputStream()) {

                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = in.read(buffer)) != -1) {
                    out.write(buffer, 0, bytesRead);
                }
                out.flush();
            }

        } catch (Exception e) {
            e.printStackTrace();
            if (!response.isCommitted()) {
                response.sendError(
                        HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                        "Error retrieving attachment."
                );
            }
        }
    }
}
