package bean;

import java.io.InputStream;
import java.io.Serializable;

public class Attachment implements Serializable {
	private static final long serialVersionUID = 1L;

	private InputStream dataStream;
	private String contentType;
	private String fileName;

	public Attachment() {
	}

	public InputStream getDataStream() {
		return dataStream;
	}

	public void setDataStream(InputStream dataStream) {
		this.dataStream = dataStream;
	}

	public String getContentType() {
		return contentType;
	}

	public void setContentType(String contentType) {
		this.contentType = contentType;
	}

	public String getFileName() {
		return fileName;
	}

	public void setFileName(String fileName) {
		this.fileName = fileName;
	}
}