<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, bean.User, bean.LeaveBalance"%>
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

<style>
:root {
  --bg:#f1f5f9; --card:#fff; --border:#e2e8f0;
  --text:#1e293b; --muted:#64748b;
  --radius:18px; --shadow:0 4px 6px -1px rgba(0,0,0,.06);
}

html,body{margin:0;height:100%;background:var(--bg)}
.pageWrap{padding:24px 36px;height:100%;display:flex;flex-direction:column}

.card{
  background:var(--card);
  border:1px solid var(--border);
  border-radius:var(--radius);
  box-shadow:var(--shadow);
  margin-top:20px;
  display:flex;
  flex-direction:column;
  overflow:hidden;
}

.cardHead{
  padding:14px 22px;
  border-bottom:1px solid #f1f5f9;
  font-weight:900;
  display:flex;
  justify-content:space-between;
}

.scroll-container{
  flex:1;
  overflow:auto;
}

table{
  width:100%;
  border-collapse:separate;
  border-spacing:0;
  table-layout:fixed; /* ⭐ FIX UTAMA */
}

thead th{
  position:sticky;
  top:0;
  background:#f8fafc;
  padding:12px 14px;
  font-size:12px;
  font-weight:900;
  color:var(--muted);
  text-transform:uppercase;
}

th:first-child, td:first-child{
  position:sticky;
  left:0;
  background:#fff;
  z-index:5;
  border-right:1px solid #f1f5f9;
}

td{
  padding:14px;
  vertical-align:top;
  border-bottom:1px solid #f1f5f9;
  min-width:190px; /* ⭐ PENTING */
}

.empBox{
  display:flex;
  gap:10px;
}

.emp-name{
  font-size:13px;
  font-weight:900;
  text-transform:uppercase;
}

.role-badge{
  font-size:10px;
  font-weight:900;
  background:#eff6ff;
  color:#2563eb;
  padding:2px 6px;
  border-radius:4px;
  display:inline-block;
}

.status-tag{
  font-size:9px;
  font-weight:900;
  margin-top:3px;
  display:block;
}

.balCard{
  background:#f1f5f9;
  border:1.5px solid #3b82f6;
  border-radius:16px;
  padding:12px;
  min-width:160px;
  max-width:180px;
}

.avail-lbl{
  font-size:14px;
  font-weight:900;
}

.avail-summary{
  font-size:20px;
  font-weight:900;
  margin:4px 0 8px;
  display:flex;
  align-items:baseline;
  gap:3px;
}

.avail-total-base{
  font-size:12px;
  color:var(--muted);
}

.miniRow{
  display:flex;
  justify-content:space-between;
  font-size:11px;
  margin-top:4px;
  border-top:1px solid #e2e8f0;
  padding-top:4px;
}
</style>
</head>

<body class="flex">
<jsp:include page="sidebar.jsp"/>

<main class="flex-1 ml-20 lg:ml-64">
<jsp:include page="topbar.jsp"/>

<div class="pageWrap">

<h2 class="text-2xl font-black">Leave Balances</h2>
<span class="text-xs font-black uppercase text-blue-600">Record employee leave balance</span>

<div class="card">
<div class="cardHead">
<span>Staff Entitlements Matrix</span>
<span class="text-xs text-slate-400">Total Staff: <%= employees.size() %></span>
</div>

<div class="scroll-container">
<table>
<thead>
<tr>
<th>Staff Member</th>
<% for(Map<String,Object> t:leaveTypes){ %>
<th class="text-center"><%= esc(t.get("code").toString()) %></th>
<% } %>
</tr>
</thead>

<tbody>
<% for(User e:employees){
Map<Integer,LeaveBalance> empBals = balanceIndex.get(e.getEmpId());
%>
<tr>
<td>
<div class="empBox">
<div class="emp-name"><%= esc(e.getFullName()) %></div>
<div>
<div class="role-badge"><%= esc(e.getRole()) %></div>
<span class="status-tag text-emerald-600"><%= e.getStatus() %></span>
</div>
</div>
</td>

<% for(Map<String,Object> t:leaveTypes){
int typeId=(Integer)t.get("id");
LeaveBalance b= empBals!=null?empBals.get(typeId):null;
%>

<td class="text-center">
<% if(b==null){ %>
<span class="font-bold text-slate-400">NOT ASSIGNED</span>
<% } else { %>
<div class="balCard">
<span class="avail-lbl">AVAILABLE</span>
<div class="avail-summary">
<span><%= fmt(b.getTotalAvailable()) %></span>
<span class="avail-total-base">/<%= fmt(b.getEntitlement()+b.getCarriedForward()) %> DAYS</span>
</div>
<div class="miniRow"><span>Entitlement</span><b><%= fmt(b.getEntitlement()) %></b></div>
<div class="miniRow"><span>Used</span><b><%= fmt(b.getUsed()) %></b></div>
<div class="miniRow"><span>Pending</span><b><%= fmt(b.getPending()) %></b></div>
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
