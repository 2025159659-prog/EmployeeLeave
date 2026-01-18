<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.text.SimpleDateFormat, bean.User, bean.LeaveBalance"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ include file="icon.jsp"%>

<%
    // =========================
    // ADMIN SECURITY GUARD
    // =========================
    if (session.getAttribute("empid") == null || session.getAttribute("role") == null ||
        !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
        response.sendRedirect("login.jsp?error=Please+login+as+admin.");
        return;
    }

    String ctx = request.getContextPath();
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
    Calendar cal = Calendar.getInstance();

    // ===== SAFE FETCH (ELAK NULL)
    List<User> employees =
        (List<User>) request.getAttribute("employees");
    if (employees == null) employees = new ArrayList<>();

    List<Map<String,Object>> leaveTypes =
        (List<Map<String,Object>>) request.getAttribute("leaveTypes");
    if (leaveTypes == null) leaveTypes = new ArrayList<>();

    Map<Integer, Map<Integer, LeaveBalance>> balanceIndex =
        (Map<Integer, Map<Integer, LeaveBalance>>) request.getAttribute("balanceIndex");
    if (balanceIndex == null) balanceIndex = new HashMap<>();

    String error = (String) request.getAttribute("error");
%>

<%!
  // =========================
  // FORMATTERS
  // =========================
  String fmt(double d) {
    if (d == (long) d) return String.format("%d", (long) d);
    return String.format("%.1f", d);
  }

  String esc(String s) {
    if (s == null) return "";
    return s.replace("&","&amp;")
            .replace("<","&lt;")
            .replace(">","&gt;")
            .replace("\"","&quot;")
            .replace("'","&#39;");
  }
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Leave Balances</title>

<script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="flex">
<jsp:include page="sidebar.jsp" />

<main class="flex-1 ml-20 lg:ml-64 transition-all duration-300">
<jsp:include page="topbar.jsp" />

<div class="pageWrap">

<h2 class="title">Leave Balances</h2>
<span class="sub-label">Record employee leave balance and usage status</span>

<% if (error != null) { %>
<div class="bg-red-50 text-red-600 p-4 rounded-2xl mt-4 text-xs font-bold uppercase">
    <%= error %>
</div>
<% } %>

<div class="card">
<div class="cardHead">
<span>Staff Entitlements Matrix</span>
<div class="text-[13px] font-black text-slate-400 uppercase">
    Total Staff: <%= employees.size() %>
</div>
</div>

<div class="scroll-container">
<table>

<thead>
<tr>
<th>Staff Member</th>
<% for (Map<String,Object> t : leaveTypes) { %>
    <th class="text-center">
        <%= esc(String.valueOf(t.get("code"))) %>
    </th>
<% } %>
</tr>
</thead>

<tbody>

<% if (employees.isEmpty()) { %>
<tr>
<td colspan="20" class="py-32 text-center text-slate-300 font-black uppercase text-xs italic">
    No staff records found
</td>
</tr>
<% } %>

<% for (User e : employees) {

   int empId = e.getEmpId();
   String fullName = e.getFullName();
   String role = e.getRole();
   String status = (e.getStatus() != null ? e.getStatus().toUpperCase() : "ACTIVE");
   String profilePic = e.getProfilePic();
   Date hireDate = e.getHireDate();

   boolean inactive = "INACTIVE".equals(status);

   String joinYear = "0000";
   if (hireDate != null) {
       cal.setTime(hireDate);
       joinYear = String.valueOf(cal.get(Calendar.YEAR));
   }

   String customId = "EMP-" + joinYear + "-" + String.format("%02d", empId);

   Map<Integer, LeaveBalance> empBals = balanceIndex.get(empId);
%>

<tr class="<%= inactive ? "row-inactive" : "" %>">

<td>
<div class="empBox">
<div class="w-10 h-10 rounded-xl bg-slate-100 overflow-hidden flex items-center justify-center">
<% if (profilePic != null && !profilePic.isEmpty() && !"null".equalsIgnoreCase(profilePic)) { %>
    <img src="<%= ctx + "/" + profilePic %>" class="w-full h-full object-cover">
<% } else { %>
    <div class="text-slate-400 font-black text-xs uppercase">
        <%= esc(fullName.substring(0,1)) %>
    </div>
<% } %>
</div>

<div class="min-w-0">
<div class="emp-name"><%= esc(fullName) %></div>
<div class="role-badge"><%= esc(role) %></div>
<span class="emp-meta"><%= customId %></span>
<span class="status-tag <%= inactive ? "text-slate-400" : "text-emerald-600" %>">
    <%= status %>
</span>
</div>
</div>
</td>

<% for (Map<String,Object> t : leaveTypes) {

   Integer typeId = (Integer) t.get("id");
   LeaveBalance bal = (empBals != null ? empBals.get(typeId) : null);
%>

<td class="text-center">

<% if (bal == null) { %>

<div class="text-[13px] font-black text-slate-400">NOT ASSIGNED</div>

<% } else {

   double available = bal.getTotalAvailable();
   double entitlement = bal.getEntitlement();
   double used = bal.getUsed();
   double pending = bal.getPending();
   double totalQuota = entitlement + bal.getCarriedForward();
%>

<div class="balCard">
<span class="avail-lbl">AVAILABLE</span>

<div class="avail-summary">
<span class="<%= (available <= 0 ? "text-warning" : "") %>">
    <%= fmt(available) %>
</span>
<span class="avail-total-base">/<%= fmt(totalQuota) %></span>
<span class="text-[12px] font-bold text-slate-600 ml-1">DAYS</span>
</div>

<div class="miniRow"><span>Entitlement</span><b><%= fmt(entitlement) %></b></div>
<div class="miniRow"><span>Used</span><b><%= fmt(used) %></b></div>
<div class="miniRow">
<span>Pending</span>
<b class="<%= pending > 0 ? "text-orange-500" : "" %>"><%= fmt(pending) %></b>
</div>
</div>

<% } %>

</td>

<% } %>
</tr>

<% } %>

</tbody>
</table>
</div>
</div>

</div>
</main>
</body>
</html>
