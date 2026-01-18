package bean;

import java.time.LocalDate;

public class Holiday {
	private int id;
	private String name;
	private String type;
	private LocalDate date;

	// Default Constructor
	public Holiday() {
	}

	// Constructor with fields
	public Holiday(int id, String name, String type, LocalDate date) {
		this.id = id;
		this.name = name;
		this.type = type;
		this.date = date;
	}

	// Getters and Setters
	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public LocalDate getDate() {
		return date;
	}

	public void setDate(LocalDate date) {
		this.date = date;
	}
}