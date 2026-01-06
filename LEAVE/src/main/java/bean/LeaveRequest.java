package bean;

import java.time.LocalDate;

public class LeaveRequest {
    private int empId;
    private int leaveTypeId;
    private int statusId;
    private LocalDate startDate;
    private LocalDate endDate;
    private String duration; // FULL_DAY or HALF_DAY
    private double durationDays;
    private String reason;
    private String halfSession; // AM or PM
    private String medicalFacility;
    private String refSerialNo;
    private LocalDate eventDate;
    private LocalDate dischargeDate;
    private String emergencyCategory;
    private String emergencyContact;
    private String spouseName;

    // Getters and Setters for all fields...
    public int getEmpId() { return empId; }
    public void setEmpId(int empId) { this.empId = empId; }
    public int getLeaveTypeId() { return leaveTypeId; }
    public void setLeaveTypeId(int leaveTypeId) { this.leaveTypeId = leaveTypeId; }
    public int getStatusId() { return statusId; }
    public void setStatusId(int statusId) { this.statusId = statusId; }
    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }
    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }
    public String getDuration() { return duration; }
    public void setDuration(String duration) { this.duration = duration; }
    public double getDurationDays() { return durationDays; }
    public void setDurationDays(double durationDays) { this.durationDays = durationDays; }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
    public String getHalfSession() { return halfSession; }
    public void setHalfSession(String halfSession) { this.halfSession = halfSession; }
    public String getMedicalFacility() { return medicalFacility; }
    public void setMedicalFacility(String medicalFacility) { this.medicalFacility = medicalFacility; }
    public String getRefSerialNo() { return refSerialNo; }
    public void setRefSerialNo(String refSerialNo) { this.refSerialNo = refSerialNo; }
    public LocalDate getEventDate() { return eventDate; }
    public void setEventDate(LocalDate eventDate) { this.eventDate = eventDate; }
    public LocalDate getDischargeDate() { return dischargeDate; }
    public void setDischargeDate(LocalDate dischargeDate) { this.dischargeDate = dischargeDate; }
    public String getEmergencyCategory() { return emergencyCategory; }
    public void setEmergencyCategory(String emergencyCategory) { this.emergencyCategory = emergencyCategory; }
    public String getEmergencyContact() { return emergencyContact; }
    public void setEmergencyContact(String emergencyContact) { this.emergencyContact = emergencyContact; }
    public String getSpouseName() { return spouseName; }
    public void setSpouseName(String spouseName) { this.spouseName = spouseName; }
}