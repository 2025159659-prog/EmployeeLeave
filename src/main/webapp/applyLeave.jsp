<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, bean.LeaveBalance"%>
<%@ include file="icon.jsp"%>

<%
/* =========================
   SECURITY CHECK (FIXED)
   ========================= */
HttpSession ses = request.getSession(false);
String role = (ses != null) ? String.valueOf(ses.getAttribute("role")) : "";

if (ses == null || ses.getAttribute("empid") == null ||
   (!"EMPLOYEE".equalsIgnoreCase(role) && !"MANAGER".equalsIgnoreCase(role))) {
    response.sendRedirect(request.getContextPath() + "/login.jsp?error=Please+login");
    return;
}

/* =========================
   GENDER LOGIC
   ========================= */
Object genderObj = ses.getAttribute("gender");
if (genderObj == null) genderObj = ses.getAttribute("GENDER");

String gen = (genderObj != null) ? genderObj.toString().toUpperCase() : "";
boolean isFemale = gen.startsWith("F") || gen.contains("FEMALE") || gen.contains("PEREMPUAN");
boolean isMale = !isFemale;

/* =========================
   DATA FROM SERVLET
   ========================= */
List<Map<String,Object>> leaveTypes =
    (List<Map<String,Object>>) request.getAttribute("leaveTypes");
List<LeaveBalance> balances =
    (List<LeaveBalance>) request.getAttribute("balances");

if (leaveTypes == null) leaveTypes = new ArrayList<>();
if (balances == null) balances = new ArrayList<>();
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Apply Leave</title>

<script src="https://cdn.tailwindcss.com"></script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800;900&display=swap" rel="stylesheet">

<style>
body{background:#f1f5f9;font-family:Inter}
.card{background:#fff;border-radius:20px;padding:40px;box-shadow:0 10px 20px rgba(0,0,0,.05)}
label{font-weight:900;font-size:12px;letter-spacing:.05em}
input,select,textarea{
  width:100%;border:1px solid #cbd5e1;border-radius:14px;
  height:52px;padding:0 16px;font-weight:600
}
textarea{height:120px;padding:16px}
.btn-submit{
  background:#2563eb;color:#fff;font-weight:900;
  height:56px;border-radius:16px;width:100%
}
</style>
</head>

<body class="flex">
<jsp:include page="sidebar.jsp"/>
<main class="flex-1 ml-20 lg:ml-64">
<jsp:include page="topbar.jsp"/>

<div class="max-w-4xl mx-auto p-10">
  <h2 class="text-3xl font-black uppercase">Apply Leave</h2>
  <p class="text-blue-600 text-xs font-black uppercase tracking-widest">
    Submit your leave request
  </p>

  <div class="card mt-6">

<form action="ApplyLeave" method="post" enctype="multipart/form-data">

<!-- TYPE -->
<label class="block mb-2 mt-2">Type of Leave *</label>
<select name="leaveTypeId" id="leaveTypeId" required>
  <option value="" disabled selected>-- SELECT TYPE --</option>

<%
for (Map<String, Object> t : leaveTypes) {

    String id   = String.valueOf(t.get("leave_type_id"));
    String code = String.valueOf(t.get("type_code")).toUpperCase();
    String desc = String.valueOf(t.get("description"));

    boolean canView = true;

    if (code.contains("MATERNITY") && !isFemale) canView = false;
    if (code.contains("PATERNITY") && !isMale) canView = false;

    if (canView) {
%>
  <option value="<%= id %>" data-code="<%= code %>">
      <%= code %>
  </option>
<%
    }
}
%>
</select>


<!-- DATES -->
<div class="grid grid-cols-2 gap-6 mt-6">
  <div>
    <label>Start Date *</label>
    <input type="date" name="startDate" required>
  </div>
  <div>
    <label>End Date *</label>
    <input type="date" name="endDate" required>
  </div>
</div>

<!-- REASON -->
<label class="block mt-6">Reason *</label>
<textarea name="reason" required placeholder="EXPLAIN WHY YOU ARE TAKING THIS LEAVE"></textarea>

<!-- ATTACHMENT -->
<label class="block mt-6">Supportive Attachment</label>
<input type="file" name="attachment" accept=".pdf,.jpg,.png,.jpeg">

<button class="btn-submit mt-8">SUBMIT APPLICATION</button>
</form>

  </div>
</div>
</main>
</body>
</html>

