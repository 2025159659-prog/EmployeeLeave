package bean;

public class LeaveBalance {
    private int leaveTypeId;
    private String typeCode;
    private String description;
    private int entitlement;
    private int carriedForward;
    private double used;
    private double pending;
    private double totalAvailable;

    public LeaveBalance() {}

    // Getters and Setters
    public int getLeaveTypeId() { return leaveTypeId; }
    public void setLeaveTypeId(int leaveTypeId) { this.leaveTypeId = leaveTypeId; }

    public String getTypeCode() { return typeCode; }
    public void setTypeCode(String typeCode) { this.typeCode = typeCode; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public int getEntitlement() { return entitlement; }
    public void setEntitlement(int entitlement) { this.entitlement = entitlement; }

    public int getCarriedForward() { return carriedForward; }
    public void setCarriedForward(int carriedForward) { this.carriedForward = carriedForward; }

    public double getUsed() { return used; }
    public void setUsed(double used) { this.used = used; }

    public double getPending() { return pending; }
    public void setPending(double pending) { this.pending = pending; }

    public double getTotalAvailable() { return totalAvailable; }
    public void setTotalAvailable(double totalAvailable) { this.totalAvailable = totalAvailable; }
}