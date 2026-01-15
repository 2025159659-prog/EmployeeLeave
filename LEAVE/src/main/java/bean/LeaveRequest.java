package bean;

import java.io.Serializable;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

/**
 * Comprehensive Model class representing a Leave Request.
 * Acts as the Data Transfer Object (DTO) for the base table and all inherited tables.
 */
public class LeaveRequest implements Serializable {
    private static final long serialVersionUID = 1L;

    // Primary and Foreign Keys
    private int leaveId;
    private int empId;
    private int leaveTypeId;
    private int statusId;

    // Core Leave Data (Base Table: LEAVE_REQUESTS)
    private LocalDate startDate;
    private LocalDate endDate;
    private String duration;      // FULL_DAY or HALF_DAY
    private double durationDays;  // Total calculated days
    private String halfSession;   // AM or PM
    private String reason;

    // Inheritance Metadata (Mapped from specific LR_* tables)
    private String medicalFacility;   // Clinic Name / Hospital Name / Location
    private String refSerialNo;       // MC Serial Number
    private LocalDate eventDate;      // Admit Date / Expected Due Date / Delivery Date
    private LocalDate dischargeDate;  // Only for Hospitalization
    private String emergencyCategory; // Only for Emergency
    private String emergencyContact;  // Only for Emergency
    private String spouseName;        // Only for Paternity
    private int weekPregnancy;        // Only for Maternity (e.g., 32 weeks)

    // Audit and Joined Metadata for Display
    private Timestamp appliedOn;
    private String managerComment;
    private String typeCode;
    private String statusCode;
    private String fileName;

    public LeaveRequest() {}

    // --- Getters and Setters ---

    public int getLeaveId() { return leaveId; }
    public void setLeaveId(int leaveId) { this.leaveId = leaveId; }

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

    public String getHalfSession() { return halfSession; }
    public void setHalfSession(String halfSession) { this.halfSession = halfSession; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }

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

    public int getWeekPregnancy() { return weekPregnancy; }
    public void setWeekPregnancy(int weekPregnancy) { this.weekPregnancy = weekPregnancy; }

    public Timestamp getAppliedOn() { return appliedOn; }
    public void setAppliedOn(Timestamp appliedOn) { this.appliedOn = appliedOn; }

    public String getManagerComment() { return managerComment; }
    public void setManagerComment(String managerComment) { this.managerComment = managerComment; }

    public String getTypeCode() { return typeCode; }
    public void setTypeCode(String typeCode) { this.typeCode = typeCode; }

    public String getStatusCode() { return statusCode; }
    public void setStatusCode(String statusCode) { this.statusCode = statusCode; }

    public String getFileName() { return fileName; }
    public void setFileName(String fileName) { this.fileName = fileName; }

    // --- Helper Methods ---

    /**
     * Formatting helper for UI labels.
     */
    public String getDurationLabel() {
        if ("HALF_DAY".equalsIgnoreCase(this.duration)) {
            String session = (this.halfSession != null) ? this.halfSession.toUpperCase() : "AM";
            return "HALF DAY (" + session + ")";
        }
        return "FULL DAY";
    }

    /**
     * Calculation fallback if DAO hasn't provided durationDays.
     */
    public double getTotalDays() {
        if (durationDays > 0) return durationDays;
        if ("HALF_DAY".equalsIgnoreCase(this.duration)) return 0.5;
        if (startDate != null && endDate != null) {
            return (double) ChronoUnit.DAYS.between(startDate, endDate) + 1;
        }
        return 0.0;
    }
}