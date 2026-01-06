import bean.Attachment;
import dao.AttachmentDAO;
import util.DatabaseConnection;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;
import java.sql.Connection;

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

        // 1. Security Check
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("empid") == null) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Please login to view attachments.");
            return;
        }

        // 2. Resource Management
        // We open the connection here so we can close it after the stream is finished
        try (Connection conn = DatabaseConnection.getConnection()) {
            
            String idStr = request.getParameter("id");
            if (idStr == null || idStr.isBlank()) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing Leave ID");
                return;
            }

            int leaveId = Integer.parseInt(idStr);

            // 3. Fetch Model from DAO
            Attachment attachment = attachmentDAO.getLatestAttachmentByLeaveId(leaveId, conn);

            if (attachment == null) {
                response.sendError(HttpServletResponse.SC_NOT_FOUND, "Attachment not found.");
                return;
            }

            // 4. Configure Response Headers
            String contentType = attachment.getContentType();
            if (contentType == null || contentType.isBlank()) {
                contentType = "application/octet-stream";
            }
            
            String fileName = attachment.getFileName();
            if (fileName == null || fileName.isBlank()) {
                fileName = "attachment";
            }

            response.setContentType(contentType);
            response.setHeader("X-Content-Type-Options", "nosniff");
            response.setHeader("Content-Disposition", "inline; filename=\"" + fileName.replace("\"", "") + "\"");

            // 5. Stream the Data directly to the Output Stream
            try (InputStream in = attachment.getDataStream();
                 OutputStream out = response.getOutputStream()) {
                
                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = in.read(buffer)) != -1) {
                    out.write(buffer, 0, bytesRead);
                }
                out.flush();
            }

        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid ID format.");
        } catch (Exception e) {
            e.printStackTrace();
            if (!response.isCommitted()) {
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Error retrieving file.");
            }
        }
    }
}