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

    List<User> employees = (List<User>) request.getAttribute("employees");
    List<Map<String,Object>> leaveTypes = (List<Map<String,Object>>) request.getAttribute("leaveTypes");
    Map<Integer, Map<Integer, LeaveBalance>> balanceIndex =
        (Map<Integer, Map<Integer, LeaveBalance>>) request.getAttribute("balanceIndex");
    String error = (String) request.getAttribute("error");
%>

<%!
  String fmt(double d) {
    if(d == (long) d) return String.format("%d", (long)d);
    else return String.format("%.1f", d);
  }

  String esc(String s){
    if(s == null) return "";
    return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
            .replace("\"","&quot;").replace("'","&#39;");
  }
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Leave Balances</title>
<script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="flex">
<jsp:include page="sidebar.jsp" />

<main class="flex-1 ml-20 lg:ml-64">
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
</div>

<div class="scroll-container">
<table>
<thead>
<tr>
<th>Staff Member</th>
<% for (Map<String,Object> t : leaveTypes) { %>
    <th class="text-center"><%= esc(String.valueOf(t.get("type_code"))) %></th>
<% } %>
</tr>
</thead>

<tbody>
<% for (User e : employees) {
   int empId = e.getEmpId();
   String fullName = e.getFullName();
   String status = e.getStatus();
   String profilePic = e.getProfilePic();
   Map<Integer, LeaveBalance> empBals = balanceIndex.get(empId);
%>

<tr class="<%= "INACTIVE".equalsIgnoreCase(status) ? "row-inactive" : "" %>">

<td>
<div class="empBox">
<div class="w-10 h-10 rounded-xl bg-slate-100 overflow-hidden">
<% if(profilePic != null && !profilePic.isEmpty()) { %>
<img src="<%= ctx + "/" + profilePic %>" class="w-full h-full object-cover">
<% } else { %>
<div class="text-slate-400 font-black text-xs"><%= fullName.substring(0,1) %></div>
<% } %>
</div>

<div>
<div class="emp-name"><%= esc(fullName) %></div>
<div class="role-badge">EMPLOYEE</div>
<span class="status-tag text-emerald-600"><%= status %></span>
</div>
</div>
</td>

<% for (Map<String,Object> t : leaveTypes) {
   int typeId = (Integer) t.get("leave_type_id");
   LeaveBalance bal = (empBals != null ? empBals.get(typeId) : null);
%>

<td class="text-center">
<% if (bal == null) { %>
<span class="text-slate-400 font-bold">NOT ASSIGNED</span>
<% } else { %>
<div class="balCard">
<span class="avail-lbl">AVAILABLE</span>
<div class="avail-summary">
<span><%= fmt(bal.getTotalAvailable()) %></span>
<span class="avail-total-base">/<%= fmt(bal.getEntitlement() + bal.getCarriedForward()) %></span>
</div>

<div class="miniRow"><span>Entitlement</span><b><%= fmt(bal.getEntitlement()) %></b></div>
<div class="miniRow"><span>Used</span><b><%= fmt(bal.getUsed()) %></b></div>
<div class="miniRow"><span>Pending</span><b><%= fmt(bal.getPending()) %></b></div>
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
