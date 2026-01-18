<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.text.SimpleDateFormat"%>
<%@ include file="icon.jsp"%>

<%
HttpSession ses = request.getSession(false);
String role = (ses != null) ? String.valueOf(ses.getAttribute("role")) : "";
String userFullName = (ses != null) ? String.valueOf(ses.getAttribute("fullname")) : "User";

if (ses == null || ses.getAttribute("empid") == null
        || (!"EMPLOYEE".equalsIgnoreCase(role) && !"MANAGER".equalsIgnoreCase(role))) {
    response.sendRedirect(request.getContextPath() + "/login.jsp");
    return;
}

List<Map<String, Object>> allLeaves =
        (List<Map<String, Object>>) request.getAttribute("leaves");
List<String> years =
        (List<String>) request.getAttribute("years");

if (allLeaves == null) allLeaves = new ArrayList<>();
if (years == null) years = new ArrayList<>();

String currentStatus = request.getParameter("status") != null ? request.getParameter("status") : "ALL";
String currentYear = request.getParameter("year") != null ? request.getParameter("year") : "";

int pageSize = 10;
int totalRecords = allLeaves.size();
int currentPage = 1;
try {
    if (request.getParameter("p") != null)
        currentPage = Integer.parseInt(request.getParameter("p"));
} catch (Exception e) {}

int totalPages = (int) Math.ceil((double) totalRecords / pageSize);
if (currentPage < 1) currentPage = 1;
if (totalPages > 0 && currentPage > totalPages) currentPage = totalPages;

int startIdx = (currentPage - 1) * pageSize;
int endIdx = Math.min(startIdx + pageSize, totalRecords);
List<Map<String, Object>> leaves =
        (totalRecords > 0) ? allLeaves.subList(startIdx, endIdx) : new ArrayList<>();

SimpleDateFormat sdfDb = new SimpleDateFormat("yyyy-MM-dd");
SimpleDateFormat sdfDisplay = new SimpleDateFormat("dd/MM/yyyy");
SimpleDateFormat sdfTimeDb = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
SimpleDateFormat sdfTimeDisplay = new SimpleDateFormat("dd/MM/yyyy HH:mm");
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>LMS | My Leave History</title>
<link rel="stylesheet"
      href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<script src="https://cdn.tailwindcss.com"></script>
</head>

<body class="flex">
<jsp:include page="sidebar.jsp" />

<main class="ml-20 lg:ml-64 min-h-screen flex-1">
<jsp:include page="topbar.jsp" />

<div class="pageWrap">

<div class="table-card">
<table>
<thead>
<tr>
    <th>Record ID</th>
    <th>Leave Category</th>
    <th>Dates</th>
    <th>Days</th>
    <th>Status</th>
    <th>Applied On</th>
</tr>
</thead>

<tbody>
<%
if (leaves.isEmpty()) {
%>
<tr>
<td colspan="6" class="text-center text-slate-400 font-bold py-20">
NO LEAVE HISTORY FOUND
</td>
</tr>
<%
} else {
for (Map<String, Object> l : leaves) {

    /* ===============================
       🔥 FIX UTAMA – NORMALIZE DATA
       UI TAK DISENTUH
       =============================== */
    if (!l.containsKey("id") && l.containsKey("leaveId"))
        l.put("id", l.get("leaveId"));

    if (!l.containsKey("start") && l.containsKey("startDate"))
        l.put("start", l.get("startDate"));

    if (!l.containsKey("end") && l.containsKey("endDate"))
        l.put("end", l.get("endDate"));

    if (!l.containsKey("totalDays") && l.containsKey("days"))
        l.put("totalDays", l.get("days"));

    if (!l.containsKey("duration"))
        l.put("duration", "FULL_DAY");

    String startDisplay = "-";
    String endDisplay = "-";
    String appliedDisplay = "-";

    try {
        if (l.get("start") != null)
            startDisplay = sdfDisplay.format(sdfDb.parse(l.get("start").toString()));
        if (l.get("end") != null)
            endDisplay = sdfDisplay.format(sdfDb.parse(l.get("end").toString()));
        if (l.get("appliedOn") != null)
            appliedDisplay = sdfTimeDisplay.format(
                    sdfTimeDb.parse(l.get("appliedOn").toString()));
    } catch (Exception e) {}
%>

<tr>
<td class="font-mono font-bold text-blue-600">
    LR-<%=l.get("id")%>
</td>

<td class="font-bold uppercase">
    <%=l.get("type")%>
</td>

<td>
    <%=startDisplay%>
    <% if (!startDisplay.equals(endDisplay)) { %>
        <span class="block text-xs text-slate-500">to <%=endDisplay%></span>
    <% } %>
</td>

<td class="font-black text-blue-600">
    <%=l.get("totalDays")%>
</td>

<td class="font-bold uppercase">
    <%=l.get("status")%>
</td>

<td class="text-sm text-slate-500">
    <%=appliedDisplay%>
</td>
</tr>

<%
}
}
%>
</tbody>
</table>
</div>

</div>
</main>
</body>
</html>
