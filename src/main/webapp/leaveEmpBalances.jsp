<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.text.SimpleDateFormat, bean.User, bean.LeaveBalance"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ include file="icon.jsp"%>

<%
    // =========================
    // ADMIN SECURITY GUARD
    // =========================
    if (session.getAttribute("empid") == null ||
        session.getAttribute("role") == null ||
        !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
        response.sendRedirect("login.jsp?error=Please+login+as+admin.");
        return;
    }

    String ctx = request.getContextPath();
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
    Calendar cal = Calendar.getInstance();

    List<User> employees =
        (List<User>) request.getAttribute("employees");

    List<Map<String,Object>> leaveTypes =
        (List<Map<String,Object>>) request.getAttribute("leaveTypes");

    Map<Integer, Map<Integer, LeaveBalance>> balanceIndex =
        (Map<Integer, Map<Integer, LeaveBalance>>) request.getAttribute("balanceIndex");

    String error = (String) request.getAttribute("error");
%>

<%!
    String fmt(double d) {
        if (d == (long) d) return String.valueOf((long) d);
        return String.format("%.1f", d);
    }

    String esc(String s){
        if(s == null) return "";
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
<title>Leave Balances | Admin</title>
<script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="flex">
<jsp:include page="sidebar.jsp" />

<main class="flex-1 ml-20 lg:ml-64">
<jsp:include page="topbar.jsp" />

<div class="p-6">

<h2 class="text-2xl font-black uppercase">Leave Balances</h2>
<p class="text-blue-600 text-xs font-bold uppercase mb-4">
Record employee leave balance and usage
</p>

<% if (error != null) { %>
<div class="bg-red-50 text-red-600 p-3 rounded mb-4 text-xs font-bold">
    <%= error %>
</div>
<% } %>

<div class="bg-white border rounded-xl overflow-auto">

<table class="min-w-full border-collapse">

<thead class="bg-slate-100 text-xs uppercase font-black">
<tr>
    <th class="p-3 sticky left-0 bg-slate-100">Staff</th>

    <% if (leaveTypes != null) {
        for (Map<String,Object> t : leaveTypes) { %>
        <th class="p-3 text-center">
            <%= esc(String.valueOf(t.get("typeCode"))) %>
        </th>
    <% }} %>
</tr>
</thead>

<tbody>

<% if (employees == null || employees.isEmpty()) { %>
<tr>
<td colspan="20" class="p-10 text-center text-slate-300 font-black uppercase">
No staff records found
</td>
</tr>
<% } else {

for (User e : employees) {

    int empId = e.getEmpId();
    String fullName = e.getFullName();
    String role = e.getRole();
    String status = e.getStatus() != null ? e.getStatus().toUpperCase() : "ACTIVE";

    Map<Integer, LeaveBalance> empBals =
        balanceIndex != null ? balanceIndex.get(empId) : null;
%>

<tr class="border-t">

<td class="p-3 sticky left-0 bg-white">
    <div class="font-black uppercase text-sm"><%= esc(fullName) %></div>
    <div class="text-xs font-bold text-blue-600"><%= esc(role) %></div>
    <div class="text-[10px] font-bold text-slate-400"><%= status %></div>
</td>

<% if (leaveTypes != null) {
    for (Map<String,Object> t : leaveTypes) {

        int typeId = (Integer) t.get("leaveTypeId");
        LeaveBalance b = empBals != null ? empBals.get(typeId) : null;

        if (b == null) { %>

<td class="p-3 text-center text-xs font-black text-slate-400">
NOT ASSIGNED
</td>

<% } else {

double available = b.getTotalAvailable();
double used = b.getUsed();
double pending = b.getPending();
double entitlement = b.getEntitlement();
double total = entitlement + b.getCarriedForward();
%>

<td class="p-3">
<div class="bg-slate-100 border rounded-lg p-3 text-xs">

<div class="font-black text-lg <%= available <= 0 ? "text-red-500" : "" %>">
<%= fmt(available) %> / <%= fmt(total) %>
</div>

<div class="flex justify-between mt-2">
<span>Entitlement</span><b><%= fmt(entitlement) %></b>
</div>

<div class="flex justify-between">
<span>Used</span><b><%= fmt(used) %></b>
</div>

<div class="flex justify-between">
<span>Pending</span>
<b class="<%= pending > 0 ? "text-orange-500" : "" %>">
<%= fmt(pending) %>
</b>
</div>

</div>
</td>

<% } } } %>

</tr>

<% } } %>

</tbody>
</table>

</div>
</div>
</main>
</body>
</html>
