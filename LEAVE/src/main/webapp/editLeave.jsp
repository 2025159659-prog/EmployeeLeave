   <%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head>
  <title>Edit Leave</title>
  <meta charset="UTF-8">
</head>
<body>

  <form id="editForm" action="<%=request.getContextPath()%>/EditLeave" method="post">
    <input type="hidden" id="editLeaveId" name="leaveId">

    <div class="edit-grid">
      <div class="edit-field" style="grid-column:1 / -1;">
        <label>Leave Type</label>
        <select id="editLeaveType" name="leaveType" required></select>
      </div>

      <div class="edit-field">
        <label>Start Date</label>
        <input type="date" id="editStartDate" name="startDate" required>
      </div>

      <div class="edit-field">
        <label>End Date</label>
        <input type="date" id="editEndDate" name="endDate" required>
      </div>

      <div class="edit-field">
        <label>Duration</label>
        <select id="editDuration" name="duration" required>
          <option value="FULL_DAY">Full Day</option>
          <option value="HALF_DAY_AM">Half Day (AM)</option>
          <option value="HALF_DAY_PM">Half Day (PM)</option>
        </select>
      </div>

      <div class="edit-field" style="grid-column:1 / -1;">
        <label>Reason</label>
        <textarea id="editReason" name="reason" required></textarea>
      </div>
    </div>

    <div class="edit-actions">
      <button type="button" class="btn-modal btn-gray" onclick="closeEditModal()">Cancel</button>
      <button type="submit" class="btn-modal btn-blue">Save Changes</button>
    </div>
  </form>

</body>
</html>