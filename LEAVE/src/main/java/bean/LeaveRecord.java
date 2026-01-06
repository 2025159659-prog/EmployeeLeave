package bean;

import java.io.Serializable;
import java.util.*;

/**
 * Enhanced LeaveRecord Bean for MVC pattern.
 * Supports standard leave data, employee details, and type-specific inheritance.
 */
public class LeaveRecord implements Serializable {
    private static final long serialVersionUID = 1L;

    // Core Leave Data
    private int id;
    private int leaveTypeId;
    private String typeCode;
    private String statusCode;
    private Date startDate;
    private Date endDate;
    private double totalDays;
    private Date appliedOn;
    private String fileName;
    private boolean hasFile;
    private String reason;
    private String adminComment;
    private String dbDuration;
    private String halfSession;

    // Employee Details (Required for Admin Views)
    private int empId;
    private String fullName;
    private String profilePic;
    private Date hireDate;

    // Inheritance Support (Type-Specific Data)
    // Stores dynamic fields like "Clinic Name", "Relationship", etc.
    private Map<String, String> typeSpecificData = new HashMap<>();

    public LeaveRecord() {}

    /**
     * Helper to get a professional duration string.
     */
    public String getDurationLabel() {
        if ("HALF_DAY".equalsIgnoreCase(dbDuration)) {
            String session = (halfSession != null) ? halfSession.toUpperCase() : "AM";
            return "HALF DAY (" + session + ")";
        }
        return "FULL DAY";
    }

    /**
     * Fallback logic for calculating days if DURATION_DAYS column is empty.
     */
    public double calculateDateDiff() {
        if ("HALF_DAY".equalsIgnoreCase(dbDuration)) return 0.5;
        if (startDate != null && endDate != null) {
            java.sql.Date s = new java.sql.Date(startDate.getTime());
            java.sql.Date e = new java.sql.Date(endDate.getTime());
            long diff = (e.toLocalDate().toEpochDay() - s.toLocalDate().toEpochDay()) + 1;
            return (double) Math.max(diff, 1);
        }
        return 0.0;
    }

    // --- Standard Getters and Setters ---

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getLeaveTypeId() { return leaveTypeId; }
    public void setLeaveTypeId(int leaveTypeId) { this.leaveTypeId = leaveTypeId; }

    public String getTypeCode() { return typeCode; }
    public void setTypeCode(String typeCode) { this.typeCode = typeCode; }

    public String getStatusCode() { return statusCode; }
    public void setStatusCode(String statusCode) { this.statusCode = statusCode; }

    public Date getStartDate() { return startDate; }
    public void setStartDate(Date startDate) { this.startDate = startDate; }

    public Date getEndDate() { return endDate; }
    public void setEndDate(Date endDate) { this.endDate = endDate; }

    public double getTotalDays() { return totalDays; }
    public void setTotalDays(double totalDays) { this.totalDays = totalDays; }

    public Date getAppliedOn() { return appliedOn; }
    public void setAppliedOn(Date appliedOn) { this.appliedOn = appliedOn; }

    public String getFileName() { return fileName; }
    public void setFileName(String fileName) { this.fileName = fileName; }

    public boolean isHasFile() { return hasFile; }
    public void setHasFile(boolean hasFile) { this.hasFile = hasFile; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }

    public String getAdminComment() { return adminComment; }
    public void setAdminComment(String adminComment) { this.adminComment = adminComment; }

    public String getDbDuration() { return dbDuration; }
    public void setDbDuration(String dbDuration) { this.dbDuration = dbDuration; }

    public String getHalfSession() { return halfSession; }
    public void setHalfSession(String halfSession) { this.halfSession = halfSession; }

    public int getEmpId() { return empId; }
    public void setEmpId(int empId) { this.empId = empId; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getProfilePic() { return profilePic; }
    public void setProfilePic(String profilePic) { this.profilePic = profilePic; }

    public Date getHireDate() { return hireDate; }
    public void setHireDate(Date hireDate) { this.hireDate = hireDate; }

    public Map<String, String> getTypeSpecificData() { return typeSpecificData; }
    public void setTypeSpecificData(Map<String, String> typeSpecificData) { this.typeSpecificData = typeSpecificData; }
}