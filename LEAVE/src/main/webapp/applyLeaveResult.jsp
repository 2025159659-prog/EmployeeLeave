<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
  Boolean ok = (Boolean) request.getAttribute("ok");
  if (ok == null) ok = false;

  String msg = (String) request.getAttribute("msg");
  if (msg == null) msg = "Done.";

  Object leaveId = request.getAttribute("leaveId");
  Object durationDays = request.getAttribute("durationDays");
  Object durationType = request.getAttribute("durationType");
  Object startDate = request.getAttribute("startDate");
  Object endDate = request.getAttribute("endDate");
  Object fileName = request.getAttribute("fileName");
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Apply Leave Result</title>
  <style>
    body{ margin:0; font-family:Arial,sans-serif; background:#f4f6fb; }
    .wrap{ min-height:100vh; display:flex; align-items:center; justify-content:center; padding:18px; }
    .modal{
      width:520px; max-width:95%;
      background:#fff;
      border-radius:16px;
      border:1px solid #e5e7eb;
      box-shadow:0 10px 25px rgba(0,0,0,0.10);
      padding:18px;
    }
    .title{ font-size:18px; font-weight:900; margin:0 0 8px; }
    .ok{ color:#16a34a; font-weight:900; }
    .bad{ color:#dc2626; font-weight:900; }
    .muted{ color:#64748b; font-size:13px; line-height:1.6; }
    .btn{
      display:inline-block;
      margin-top:14px;
      background:#2563eb; color:#fff; text-decoration:none;
      padding:10px 12px; border-radius:12px; font-weight:900;
    }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="modal">
      <div class="title">
        <%= ok ? "<span class='ok'>Success</span>" : "<span class='bad'>Failed</span>" %>
      </div>

      <div class="muted"><%= msg %></div>

      <% if (ok) { %>
        <hr style="border:none;border-top:1px solid #eef2f7;margin:12px 0;">
        <div class="muted">
          <b>Leave ID:</b> <%= leaveId %><br/>
          <b>Duration:</b> <%= durationType %> (<%= durationDays %> day)<br/>
          <b>Start:</b> <%= startDate %><br/>
          <b>End:</b> <%= endDate %><br/>
          <b>Attachment:</b> <%= (fileName==null? "None" : fileName) %>
        </div>
      <% } %>

      <a class="btn" href="EmployeeDashboard">Back to Dashboard</a>
      <a class="btn" style="background:#0f172a" href="ApplyLeaveServlet">Apply Another</a>
    </div>
  </div>
</body>
</html>
