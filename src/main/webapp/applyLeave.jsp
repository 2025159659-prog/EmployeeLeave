<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, bean.LeaveBalance"%>
<%@ include file="icon.jsp"%>

<%
HttpSession ses = request.getSession(false);
String role = (ses != null) ? String.valueOf(ses.getAttribute("role")) : "";

if (ses == null || ses.getAttribute("empid") == null || (!"EMPLOYEE".equalsIgnoreCase(role))) {
	response.sendRedirect(request.getContextPath() + "/login.jsp?error=Please+login+as+employee");
	return;
}

// ===== GENDER =====
Object genderObj = ses.getAttribute("gender");
String gen = (genderObj != null) ? String.valueOf(genderObj).toUpperCase() : "";
boolean isFemale = gen.startsWith("F") || gen.contains("FEMALE") || gen.contains("PEREMPUAN");
boolean isMale = !isFemale;

// ===== DATA =====
List<Map<String, Object>> leaveTypes =
	(List<Map<String, Object>>) request.getAttribute("leaveTypes");
List<LeaveBalance> balances =
	(List<LeaveBalance>) request.getAttribute("balances");

if (leaveTypes == null) leaveTypes = new ArrayList<>();
if (balances == null) balances = new ArrayList<>();

String typeError = (String) request.getAttribute("typeError");
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Apply Leave</title>
<script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="flex">
<jsp:include page="sidebar.jsp" />

<main class="flex-1 ml-20 lg:ml-64 min-h-screen transition-all duration-300">
<jsp:include page="topbar.jsp" />

<div class="pageWrap">
<div class="card">

<% if (typeError != null) { %>
<div class="validation-error" style="display:flex;">
	<%=AlertIcon("w-5 h-5")%>
	<span><%=typeError%></span>
</div>
<% } %>

<form action="ApplyLeave" method="post" enctype="multipart/form-data"
	id="applyForm" onsubmit="return handleApplyForm(event)">

<div class="form-grid">

<!-- =======================
     TYPE OF LEAVE (FIXED)
     ======================= -->
<div>
<label>Type of Leave <span class="req-star">*</span></label>

<select name="leaveTypeId" id="leaveTypeId" required
	onchange="handleTypeChange(); validateForm();">

	<!-- 🔧 FIX: JANGAN disabled -->
	<option value="">-- SELECT TYPE --</option>

	<%
	for (Map<String, Object> t : leaveTypes) {
		String id = String.valueOf(t.get("id"));
		String code = String.valueOf(t.get("code")).toUpperCase();

		boolean canView = true;
		if (code.contains("MATERNITY") && !isFemale) canView = false;
		if (code.contains("PATERNITY") && !isMale) canView = false;

		if (canView) {
	%>
	<option value="<%=id%>" data-code="<%=code%>"><%=code%></option>
	<%
		}
	}
	%>
</select>

<div id="balanceHint"
	class="text-[10px] font-black text-blue-600 uppercase mt-2 hidden">
	Available Balance: <span id="hintDays">0</span> Days
</div>
</div>

<!-- =======================
     LEAVE PERIOD
     ======================= -->
<div>
<label>Leave Period <span class="req-star">*</span></label>
<div class="duration-options">
<label class="duration-tile selected" onclick="selectDuration(this)">
<input type="radio" name="duration" value="FULL_DAY" checked>
<span>Full Day</span>
</label>

<label class="duration-tile" onclick="selectDuration(this)">
<input type="radio" name="duration" value="HALF_DAY_AM">
<span>Half (AM)</span>
</label>

<label class="duration-tile" onclick="selectDuration(this)">
<input type="radio" name="duration" value="HALF_DAY_PM">
<span>Half (PM)</span>
</label>
</div>
</div>

<div id="dynamicAttributes" class="dynamic-attributes">
<div id="dynamicFields" class="dynamic-grid"></div>
</div>

</div>

<div class="form-grid">
<div>
<label>Start Date *</label>
<input type="date" name="startDate" id="startDate" required>
</div>
<div>
<label>End Date *</label>
<input type="date" name="endDate" id="endDate" required>
</div>
</div>

<div class="mb-8">
<label>Reason *</label>
<textarea name="reason" required></textarea>
</div>

<div class="mb-10">
<label>Supportive Attachment</label>
<input type="file" name="attachment" id="attachment">
</div>

<button type="submit" class="btn-submit">
<%=SendIcon("w-5 h-5")%> Submit Application
</button>

</form>
</div>
</div>
</main>

<script>
const leaveBalances = {
<% for (LeaveBalance b : balances) { %>
"<%=b.getLeaveTypeId()%>": <%=b.getTotalAvailable()%>,
<% } %>
};

// 🔧 SAFETY FIX – JANGAN CRASH
if (!document.getElementById("leaveTypeId")) {
	console.error("leaveTypeId not found");
}
</script>

</body>
</html>
