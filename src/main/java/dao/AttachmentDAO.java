package dao;

import bean.Attachment;
import util.DatabaseConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class AttachmentDAO {

    public Attachment getLatestAttachmentByLeaveId(int leaveId, Connection conn) throws Exception {

        String sql = """
            SELECT file_data, mime_type, file_name
            FROM leave.leave_request_attachments
            WHERE leave_id = ?
            ORDER BY uploaded_on DESC
            LIMIT 1
        """;

        try (PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, leaveId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Attachment attachment = new Attachment();
                    attachment.setDataStream(rs.getBinaryStream("file_data"));
                    attachment.setContentType(rs.getString("mime_type"));
                    attachment.setFileName(rs.getString("file_name"));
                    return attachment;
                }
            }
        }

        return null;
    }
}
