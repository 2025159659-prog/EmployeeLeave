package bean;

import java.io.Serializable;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

/**
 * Comprehensive Model class representing a Leave Request.
 * Includes all fields for application, attachments, and administrative tracking.
 */
public class LeaveRequest implements Serializable {
    private static final long serialVersionUID = 1L;

    // Primary and Foreign Keys
    private int leaveId;
    private int empId;
    private int leaveTypeId;
    private int statusId;

    // Core Leave Data
    private LocalDate startDate;
    private LocalDate endDate;
    private String duration;      // FULL_DAY or HALF_DAY
    private double durationDays;  // Total calculated days
    private String halfSession;   // AM or PM (used if duration is HALF_DAY)
    private String reason;

    // Specific Form Details
    private String medicalFacility;
    private String refSerialNo;
    private LocalDate eventDate;
    private LocalDate dischargeDate;
    private String emergencyCategory;
    private String emergencyContact;
    private String spouseName;

    // Audit and Joined Metadata
    private Timestamp appliedOn;    // When the request was submitted
    private String managerComment;    // Remarks from the manager/admin
    private String typeCode;        // Joined from LEAVE_TYPES (e.g., 'AL', 'MC')
    private String statusCode;      // Joined from LEAVE_STATUSES (e.g., 'PENDING')
    private String fileName;        // Joined from LEAVE_REQUEST_ATTACHMENTS

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

    // --- MVC Helper Methods for JSP Display ---

    /**
     * Returns a user-friendly label for the duration.
     */
    public String getDurationLabel() {
        if ("HALF_DAY".equalsIgnoreCase(this.duration)) {
            String session = (this.halfSession != null) ? this.halfSession.toUpperCase() : "AM";
            return "HALF DAY (" + session + ")";
        }
        return "FULL DAY";
    }

    /**
     * Logic to return the total days.
     * Calculates based on dates if durationDays is not yet set.
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