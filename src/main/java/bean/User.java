package bean;

import java.io.Serializable;
import java.util.Date;

public class User implements Serializable {
	private static final long serialVersionUID = 1L;

	private int empId;
	private String fullName;
	private String email;
	private String password; // Added for registration
	private String role;
	private String phone;

	private String street;
	private String city;
	private String postalCode;
	private String state;

	private Date hireDate;
	private String icNumber;
	private String gender;
	private String profilePic;
	private String status;

	public User() {
	}

	// Getters and Setters
	public int getEmpId() {
		return empId;
	}

	public void setEmpId(int empId) {
		this.empId = empId;
	}

	public String getFullName() {
		return fullName;
	}

	public void setFullName(String fullName) {
		this.fullName = fullName;
	}

	public String getEmail() {
		return email;
	}

	public void setEmail(String email) {
		this.email = email;
	}

	public String getPassword() {
		return password;
	}

	public void setPassword(String password) {
		this.password = password;
	}

	public String getRole() {
		return role;
	}

	public void setRole(String role) {
		this.role = role;
	}

	public String getPhone() {
		return phone;
	}

	public void setPhone(String phone) {
		this.phone = phone;
	}

	public String getStreet() {
		return street;
	}

	public void setStreet(String street) {
		this.street = street;
	}

	public String getCity() {
		return city;
	}

	public void setCity(String city) {
		this.city = city;
	}

	public String getPostalCode() {
		return postalCode;
	}

	public void setPostalCode(String postalCode) {
		this.postalCode = postalCode;
	}

	public String getState() {
		return state;
	}

	public void setState(String state) {
		this.state = state;
	}

	public Date getHireDate() {
		return hireDate;
	}

	public void setHireDate(Date hireDate) {
		this.hireDate = hireDate;
	}

	public String getIcNumber() {
		return icNumber;
	}

	public void setIcNumber(String icNumber) {
		this.icNumber = icNumber;
	}

	public String getGender() {
		return gender;
	}

	public void setGender(String gender) {
		this.gender = gender;
	}

	public String getProfilePic() {
		return profilePic;
	}

	public void setProfilePic(String profilePic) {
		this.profilePic = profilePic;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}
}