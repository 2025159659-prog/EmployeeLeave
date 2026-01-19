package bean;

import java.io.Serializable;
import java.util.Date;

/**
 * LeaveRecord Bean Comprehensive data object used for Admin Leave History
 * views. Updated to include leaveTypeId and all sub-table metadata fields.
 */
public class LeaveRecord implements Serializable {
	private static final long serialVersionUID = 1L;

	// Primary Leave Details
	private int leaveId;
	private int empId;
	private String fullName;
	private Date hireDate;
	private String profilePic;
	private String typeCode;
	private String statusCode;
	private double durationDays;
	private String duration;
	private String startDate;
	private String endDate;
	private String appliedOn;
	private String reason;
	private String managerComment;
	private String attachment;

	// Type Tracking
	private String leaveTypeId;

	// Metadata / Dynamic Attributes (Class Table Inheritance)
	private String medicalFacility;
	private String refSerialNo;
	private String eventDate;
	private String dischargeDate;
	private String emergencyCategory;
	private String emergencyContact;
	private String spouseName;
	private int weekPregnancy; // Added for Maternity Leave tracking
	private boolean hasFile;

	public LeaveRecord() {
	}

	// Getters and Setters
	public int getLeaveId() {
		return leaveId;
	}

	public void setLeaveId(int leaveId) {
		this.leaveId = leaveId;
	}

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

	public Date getHireDate() {
		return hireDate;
	}

	public void setHireDate(Date hireDate) {
		this.hireDate = hireDate;
	}

	public String getProfilePic() {
		return profilePic;
	}

	public void setProfilePic(String profilePic) {
		this.profilePic = profilePic;
	}

	public String getTypeCode() {
		return typeCode;
	}

	public void setTypeCode(String typeCode) {
		this.typeCode = typeCode;
	}

	public String getStatusCode() {
		return statusCode;
	}

	public void setStatusCode(String statusCode) {
		this.statusCode = statusCode;
	}

	public double getDurationDays() {
		return durationDays;
	}

	public void setDurationDays(double durationDays) {
		this.durationDays = durationDays;
	}

	public String getDuration() {
		return duration;
	}

	public void setDuration(String duration) {
		this.duration = duration;
	}

	public String getStartDate() {
		return startDate;
	}

	public void setStartDate(String startDate) {
		this.startDate = startDate;
	}

	public String getEndDate() {
		return endDate;
	}

	public void setEndDate(String endDate) {
		this.endDate = endDate;
	}

	public String getAppliedOn() {
		return appliedOn;
	}

	public void setAppliedOn(String appliedOn) {
		this.appliedOn = appliedOn;
	}

	public String getReason() {
		return reason;
	}

	public void setReason(String reason) {
		this.reason = reason;
	}

	public String getManagerComment() {
		return managerComment;
	}

	public void setManagerComment(String managerComment) {
		this.managerComment = managerComment;
	}

	public String getAttachment() {
		return attachment;
	}

	public void setAttachment(String attachment) {
		this.attachment = attachment;
	}

	public String getLeaveTypeId() {
		return leaveTypeId;
	}

	public void setLeaveTypeId(String leaveTypeId) {
		this.leaveTypeId = leaveTypeId;
	}

	public String getMedicalFacility() {
		return medicalFacility;
	}

	public void setMedicalFacility(String medicalFacility) {
		this.medicalFacility = medicalFacility;
	}

	public String getRefSerialNo() {
		return refSerialNo;
	}

	public void setRefSerialNo(String refSerialNo) {
		this.refSerialNo = refSerialNo;
	}

	public String getEventDate() {
		return eventDate;
	}

	public void setEventDate(String eventDate) {
		this.eventDate = eventDate;
	}

	public String getDischargeDate() {
		return dischargeDate;
	}

	public void setDischargeDate(String dischargeDate) {
		this.dischargeDate = dischargeDate;
	}

	public String getEmergencyCategory() {
		return emergencyCategory;
	}

	public void setEmergencyCategory(String emergencyCategory) {
		this.emergencyCategory = emergencyCategory;
	}

	public String getEmergencyContact() {
		return emergencyContact;
	}

	public void setEmergencyContact(String emergencyContact) {
		this.emergencyContact = emergencyContact;
	}

	public String getSpouseName() {
		return spouseName;
	}

	public void setSpouseName(String spouseName) {
		this.spouseName = spouseName;
	}

	public int getWeekPregnancy() {
		return weekPregnancy;
	}

	public void setWeekPregnancy(int weekPregnancy) {
		this.weekPregnancy = weekPregnancy;
	}
		
	public boolean isHasFile() {
	    return hasFile;
	}

	public void setHasFile(boolean hasFile) {
    this.hasFile = hasFile;
	}

}
