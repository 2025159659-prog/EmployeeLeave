<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page
	import="java.util.*, java.text.SimpleDateFormat, bean.User, bean.LeaveBalance"%>
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

    // MVC Data Retrieval - Using Beans
    List<User> employees = (List<User>) request.getAttribute("employees");
    List<Map<String,Object>> leaveTypes = (List<Map<String,Object>>) request.getAttribute("leaveTypes");
    Map<Integer, Map<Integer, LeaveBalance>> balanceIndex =
        (Map<Integer, Map<Integer, LeaveBalance>>) request.getAttribute("balanceIndex");
    String error = (String) request.getAttribute("error");
%>

<%!
  /**
   * ✅ NEW: Robust Formatter to handle decimals (0.5) correctly.
   * If value is a whole number (14.0), it displays as 14.
   * If value is a decimal (0.5), it displays as 0.5.
   */
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
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Leave Balances | Admin Intelligence</title>

<script src="https://cdn.tailwindcss.com"></script>
<link
	href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap"
	rel="stylesheet">

<style>
:root {
	--bg: #f1f5f9;
	--card: #ffffff;
	--border: #e2e8f0;
	--text: #1e293b;
	--muted: #64748b;
	--blue-primary: #2563eb;
	--blue-light: #eff6ff;
	--radius: 20px;
	--shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
}

* {
	box-sizing: border-box;
	font-family: 'Inter', sans-serif !important;
}

html, body {
	background: var(--bg);
	color: var(--text);
	margin: 0;
	height: 100vh;
	width: 100vw;
	overflow: hidden;
}

main {
	height: 100vh;
	display: flex;
	flex-direction: column;
	min-width: 0;
}

.pageWrap {
	padding: 24px 40px;
	flex: 1;
	display: flex;
	flex-direction: column;
	overflow: hidden;
	min-height: 0;
}

.title {
	font-size: 26px;
	font-weight: 800;
	margin: 0;
	text-transform: uppercase;
	color: var(--text);
}

.sub-label {
	color: var(--blue-primary);
	font-size: 11px;
	font-weight: 800;
	text-transform: uppercase;
	letter-spacing: 0.1em;
	margin-top: 4px;
	display: block;
}

.card {
	background: var(--card);
	border: 1px solid var(--border);
	border-radius: var(--radius);
	box-shadow: var(--shadow);
	margin-top: 24px;
	flex: 1;
	display: flex;
	flex-direction: column;
	overflow: hidden;
}

.cardHead {
	padding: 16px 24px;
	border-bottom: 1px solid #f1f5f9;
	display: flex;
	justify-content: space-between;
	align-items: center;
	background: #fcfcfd;
	flex-shrink: 0;
}

.cardHead span {
	font-weight: 800;
	font-size: 15px;
	color: var(--text);
	text-transform: uppercase;
}

.scroll-container {
	flex: 1;
	overflow: auto;
	min-height: 0;
	position: relative;
}

.scroll-container::-webkit-scrollbar {
	width: 6px;
	height: 6px;
}

.scroll-container::-webkit-scrollbar-thumb {
	background: #cbd5e1;
	border-radius: 10px;
}

table {
	width: 100%;
	border-collapse: separate;
	border-spacing: 0;
}

thead th {
	position: sticky;
	top: 0;
	z-index: 20;
	background: #f8fafc;
	border-bottom: 1px solid #f1f5f9;
	padding: 12px 16px;
	text-align: left;
	font-size: 13px;
	text-transform: uppercase;
	color: var(--muted);
	font-weight: 900;
}

th:first-child, td:first-child {
	position: sticky;
	left: 0;
	z-index: 15;
	border-right: 1px solid #f1f5f9;
	background: #fff;
}

thead th:first-child {
	z-index: 30;
	background: #f8fafc;
}

td {
	padding: 12px 16px;
	border-bottom: 1px solid #f1f5f9;
	vertical-align: top;
}

.row-inactive {
	opacity: 0.55;
	filter: grayscale(1);
	background-color: #f8fafc;
}

.empBox {
	width: 180px;
	display: flex;
	align-items: flex-start;
	gap: 10px;
}

.emp-name {
	font-size: 13px;
	font-weight: 800;
	color: #0f172a;
	line-height: 1.3;
	text-transform: uppercase;
}

.role-badge {
	font-size: 10px;
	font-weight: 900;
	background: #eff6ff;
	color: #2563eb;
	padding: 2px 6px;
	border-radius: 4px;
	border: 1px solid #dbeafe;
	text-transform: uppercase;
	margin-top: 4px;
	display: inline-block;
}

.emp-meta {
	font-size: 10px;
	font-weight: 700;
	color: #3b4a5f;
	text-transform: uppercase;
	margin-top: 2px;
	display: block;
}

.status-tag {
	font-size: 9px;
	font-weight: 950;
	text-transform: uppercase;
	margin-top: 4px;
	display: block;
}

.balCard {
	background: #f1f5f9;
	border: 1.5px solid #3b82f6;
	border-radius: var(--radius);
	padding: 12px;
	min-width: 155px;
	transition: all 0.2s ease;
}

.balCard:hover {
	background: #ffffff;
	transform: scale(1.02);
	box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
}

.avail-lbl {
	color: #0f172a;
	font-size: 16px;
	font-weight: 900;
	text-transform: uppercase;
	display: block;
	margin-bottom: 5px;
}

.avail-summary {
	font-size: 20px;
	font-weight: 900;
	color: #1e3a8a;
	line-height: 1;
	margin-bottom: 10px;
	display: flex;
	align-items: baseline;
	gap: 2px;
}

.avail-total-base {
	font-size: 13px;
	font-weight: 700;
	color: var(--muted);
}

.miniRow {
	display: flex;
	justify-content: space-between;
	align-items: center;
	font-size: 11px;
	padding-top: 6px;
	margin-top: 6px;
	border-top: 1px solid #e2e8f0;
}

.miniRow span {
	color: #475569;
	font-size: 10px;
	font-weight: 900;
	text-transform: uppercase;
}

.miniRow b {
	color: #0f172a;
	font-weight: 900;
	font-size: 11px;
}

.text-warning {
	color: #ef4444 !important;
}
</style>
</head>

<body class="flex">
	<jsp:include page="sidebar.jsp" />

	<main class="flex-1 ml-20 lg:ml-64 transition-all duration-300">
		<jsp:include page="topbar.jsp" />

		<div class="pageWrap">
			<div class="flex-shrink-0">
				<h2 class="title">Leave Balances</h2>
				<span class="sub-label">Record employee leave balance and
					usage status</span>
			</div>

			<% if (error != null) { %>
			<div
				class="bg-red-50 text-red-600 p-4 rounded-2xl mt-4 text-xs font-bold border border-red-100 uppercase flex items-center gap-3">
				<%= AlertIcon("w-5 h-5") %>
				<%= error %>
			</div>
			<% } %>

			<div class="card">
				<div class="cardHead">
					<span>Staff Entitlements Matrix</span>
					<div
						class="text-[13px] font-black text-slate-400 uppercase bg-slate-50 px-3 py-1 rounded-full border border-slate-100">
						Total Staff:
						<%= (employees != null ? employees.size() : 0) %>
					</div>
				</div>

				<div class="scroll-container">
					<table>
						<thead>
							<tr>
								<th>Staff Member</th>
								<% if (leaveTypes != null) {
                                     for (Map<String,Object> t : leaveTypes) { %>
								<th class="text-center"><%= esc(String.valueOf(t.get("code"))) %></th>
								<%   }
                                   } %>
							</tr>
						</thead>
						<tbody>
							<% if (employees == null || employees.isEmpty()) { %>
							<tr>
								<td colspan="20"
									class="py-32 text-center text-slate-300 font-black uppercase text-xs tracking-widest italic">No
									staff records found</td>
							</tr>
							<% } else {
                                 for (User e : employees) {
                                    int empId = e.getEmpId();
                                    String fullName = e.getFullName();
                                    String roleName = e.getRole();
                                    String status = (e.getStatus() != null) ? e.getStatus().toUpperCase() : "ACTIVE";
                                    java.util.Date hireDate = e.getHireDate();
                                    String profilePic = e.getProfilePic();
                                    
                                    boolean isInactive = "INACTIVE".equals(status);
                                    
                                    String joinYear = "0000";
                                    if(hireDate != null) { cal.setTime(hireDate); joinYear = String.valueOf(cal.get(Calendar.YEAR)); }
                                    String customId = "EMP-" + joinYear + "-" + String.format("%02d", empId);

                                    // Lookup balance indexed by LeaveTypeID
                                    Map<Integer, LeaveBalance> empBals = (balanceIndex != null ? balanceIndex.get(empId) : null);
                            %>
							<tr class="<%= isInactive ? "row-inactive" : "" %>">
								<td>
									<div class="empBox">
										<div
											class="w-10 h-10 rounded-xl bg-slate-100 overflow-hidden flex-shrink-0 border border-slate-200 flex items-center justify-center shadow-sm">
											<% if (profilePic != null && !profilePic.isEmpty() && !profilePic.equalsIgnoreCase("null")) { %>
											<img src="<%= ctx + "/" + profilePic %>"
												class="w-full h-full object-cover">
											<% } else { %>
											<div class="text-slate-400 font-black text-xs uppercase"><%= fullName.substring(0,1) %></div>
											<% } %>
										</div>
										<div class="min-w-0 flex-1">
											<div class="emp-name"><%= esc(fullName) %></div>
											<div class="role-badge"><%= esc(roleName) %></div>
											<span class="emp-meta mt-1"><%= customId %></span> <span
												class="status-tag <%= isInactive ? "text-slate-400" : "text-emerald-600" %>">
												<%= status %>
											</span>
										</div>
									</div>
								</td>

								<% if (leaveTypes != null) {
                                         for (Map<String,Object> t : leaveTypes) {
                                            int typeId = (Integer)t.get("id");
                                            LeaveBalance bal = (empBals != null ? empBals.get(typeId) : null);

                                            if (bal == null) { %>
								<td class="text-center"><div
										class="text-[15px] font-black text-slate-900">NOT
										ASSIGNED</div></td>
								<%      } else {
                                                double available = bal.getTotalAvailable();
                                                double used      = bal.getUsed();
                                                double pending   = bal.getPending();
                                                double entitlement = bal.getEntitlement();
                                                double totalQuota = entitlement + bal.getCarriedForward();
                                    %>
								<td>
									<div class="balCard shadow-sm">
										<span class="avail-lbl">AVAILABLE</span>
										<div class="avail-summary">
											<%-- ✅ Decimal formatter used here to show 0.5 correctly --%>
											<span class="<%= (available <= 0 ? "text-warning" : "") %>"><%= fmt(available) %></span>
											<span class="avail-total-base">/<%= fmt(totalQuota) %></span>
											<span class="text-[12px] font-bold text-slate-600 ml-1">DAYS</span>
										</div>

										<div class="miniRow">
											<span>Entitlement</span> <b><%= fmt(entitlement) %></b>
										</div>
										<div class="miniRow">
											<span>Used</span> <b><%= fmt(used) %></b>
										</div>
										<div class="miniRow">
											<span>Pending</span> <b
												class="<%= (pending > 0 ? "text-orange-500" : "") %>"><%= fmt(pending) %></b>
										</div>
									</div>
								</td>
								<%      }
                                         }
                                       } %>
							</tr>
							<%   } 
                               } %>
						</tbody>
					</table>
				</div>
			</div>
		</div>
	</main>
</body>
</html>
