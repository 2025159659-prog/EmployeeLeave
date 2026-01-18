package dao;

import bean.Attachment;
import util.DatabaseConnection;
import java.sql.*;

public class AttachmentDAO {

	public Attachment getLatestAttachmentByLeaveId(int leaveId, Connection conn) throws Exception {
		String sql = "SELECT FILE_DATA, MIME_TYPE, FILE_NAME FROM ( " + "  SELECT FILE_DATA, MIME_TYPE, FILE_NAME, "
				+ "  ROW_NUMBER() OVER (ORDER BY UPLOADED_ON DESC) rn "
				+ "  FROM LEAVE_REQUEST_ATTACHMENTS WHERE LEAVE_ID = ? " + ") WHERE rn = 1";

		PreparedStatement ps = conn.prepareStatement(sql);
		ps.setInt(1, leaveId);
		ResultSet rs = ps.executeQuery();

		if (rs.next()) {
			Attachment attachment = new Attachment();
			attachment.setDataStream(rs.getBinaryStream("FILE_DATA"));
			attachment.setContentType(rs.getString("MIME_TYPE"));
			attachment.setFileName(rs.getString("FILE_NAME"));
			return attachment;
		}
		return null;
	}
}