<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ include file="icon.jsp"%>

<%
    String role = (session.getAttribute("role") != null) ? (String) session.getAttribute("role") : "EMPLOYEE";
    
    // Get the current path (could be the Servlet URL or the forwarded JSP path)
    String path = request.getServletPath();
    String activePage = path.substring(path.lastIndexOf("/") + 1);
    
    // Clean the string: remove .jsp and convert to lowercase for easy comparison
    if (activePage.contains(".")) {
        activePage = activePage.substring(0, activePage.lastIndexOf("."));
    }
    String pageKey = activePage.toLowerCase();
    
    boolean isAdmin = role.equalsIgnoreCase("ADMIN");
    boolean isManager = role.equalsIgnoreCase("MANAGER");
%>

<script src="https://cdn.tailwindcss.com"></script>

<style>
.no-scrollbar::-webkit-scrollbar {
	display: none;
}

#appSidebar {
	transition: width 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

#appSidebar * {
	font-family: Arial, sans-serif !important;
}

/* High Contrast Active Style - Adjusted for better "length" and balance */
.active-blue {
	background-color: #2563eb !important;
	color: #ffffff !important;
	box-shadow: 0 4px 12px rgba(37, 99, 235, 0.25);
	position: relative;
}

/* Vertical indicator bar - refined for the rounded-xl look */
.active-blue::before {
	content: '';
	position: absolute;
	left: 0;
	top: 25%;
	height: 50%;
	width: 3.5px;
	background-color: #ffffff;
	border-radius: 0 4px 4px 0;
}

/* Icon color override for active state */
.active-blue svg, .active-blue i {
	color: white !important;
	stroke: white !important;
}

/* Custom transition for a smoother hover feel */
.nav-item {
	transition: all 0.2s ease-in-out;
}
</style>

<aside id="appSidebar"
	class="fixed left-0 top-0 h-full bg-[#0f172a] text-slate-200 border-r border-slate-800 z-50 flex flex-col w-20 lg:w-64 transition-all duration-300">

	<div
		class="p-4 lg:p-6 border-b border-slate-800 flex items-center gap-3 overflow-hidden shrink-0">
		<div
			class="min-w-[40px] w-10 h-10 bg-white rounded-lg flex items-center justify-center shrink-0 p-1">
			<img
				src="https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcRNhLlRcJ19hFyLWQOGP3EWiaxRZiHWupjWp6xtRzs5cdMeCUzu"
				alt="Logo" class="max-w-full max-h-full object-contain" />
		</div>
		<div class="hidden lg:block">
			<h1
				class="text-[12px] font-extrabold text-white leading-tight uppercase">
				Klinik <br>Dr Mohamad
			</h1>
		</div>
	</div>

	<!-- Navigation Area: Using mx-3 on items to pull them in from the edges -->
	<nav class="flex-1 px-2 mt-4 space-y-1.5 no-scrollbar overflow-y-auto">
		<% if (isAdmin) { %>
		<a href="AdminDashboard"
			class="nav-item flex items-center gap-3 px-3 py-2.5 mx-2 rounded-xl <%= pageKey.equals("admindashboard") ? "active-blue" : "text-slate-400 hover:bg-slate-800/50 hover:text-white" %>">
			<span class="shrink-0"><%= BriefcaseIcon("w-5 h-5") %></span> <span
			class="hidden lg:block whitespace-nowrap text-sm font-semibold">Admin
				Dashboard</span>
		</a> <a href="RegisterEmployee"
			class="nav-item flex items-center gap-3 px-3 py-2.5 mx-2 rounded-xl <%= (pageKey.contains("employee") || pageKey.contains("register")) ? "active-blue" : "text-slate-400 hover:bg-slate-800/50 hover:text-white" %>">
			<span class="shrink-0"><%= UsersIcon("w-5 h-5") %></span> <span
			class="hidden lg:block whitespace-nowrap text-sm font-semibold">Employees</span>
		</a> <a href="LeaveEmpBalances"
			class="nav-item flex items-center gap-3 px-3 py-2.5 mx-2 rounded-xl <%= (pageKey.contains("balance")) ? "active-blue" : "text-slate-400 hover:bg-slate-800/50 hover:text-white" %>">
			<span class="shrink-0"><%= ChartBarIcon("w-5 h-5") %></span> <span
			class="hidden lg:block whitespace-nowrap text-sm font-semibold">Leave
				Balances</span>
		</a> <a href="leaveEmpHistory"
			class="nav-item flex items-center gap-3 px-3 py-2.5 mx-2 rounded-xl <%= pageKey.equals("leaveemphistory") ? "active-blue" : "text-slate-400 hover:bg-slate-800/50 hover:text-white" %>">
			<span class="shrink-0"><%= ClipboardListIcon("w-5 h-5") %></span> <span
			class="hidden lg:block whitespace-nowrap text-sm font-semibold">Leave
				History</span>
		</a> <a href="ManageHoliday"
			class="nav-item flex items-center gap-3 px-3 py-2.5 mx-2 rounded-xl <%= (pageKey.contains("holiday")) ? "active-blue" : "text-slate-400 hover:bg-slate-800/50 hover:text-white" %>">
			<span class="shrink-0"><%= CalendarIcon("w-5 h-5") %></span> <span
			class="hidden lg:block whitespace-nowrap text-sm font-semibold">Manage
				Holidays</span>
		</a>

		<% } else if (isManager) { %>
		<a href="ReviewLeave"
			class="nav-item flex items-center gap-3 px-3 py-2.5 mx-2 rounded-xl <%= pageKey.contains("review") ? "active-blue" : "text-slate-400 hover:bg-slate-800/50 hover:text-white" %>">
			<span class="shrink-0"><%= CheckCircleIcon("w-5 h-5") %></span> <span
			class="hidden lg:block whitespace-nowrap text-sm font-semibold">Review
				Applications</span>
		</a>

		<% } else { %>
		<a href="EmployeeDashboard"
			class="nav-item flex items-center gap-3 px-3 py-2.5 mx-2 rounded-xl <%= pageKey.equals("employeedashboard") ? "active-blue" : "text-slate-400 hover:bg-slate-800/50 hover:text-white" %>">
			<span class="shrink-0"><%= HomeIcon("w-5 h-5") %></span> <span
			class="hidden lg:block whitespace-nowrap text-sm font-semibold">Dashboard</span>
		</a> <a href="ApplyLeave"
			class="nav-item flex items-center gap-3 px-3 py-2.5 mx-2 rounded-xl <%= pageKey.contains("apply") ? "active-blue" : "text-slate-400 hover:bg-slate-800/50 hover:text-white" %>">
			<span class="shrink-0"><%= CalendarIcon("w-5 h-5") %></span> <span
			class="hidden lg:block whitespace-nowrap text-sm font-semibold">Apply
				Leave</span>
		</a> <a href="LeaveHistory"
			class="nav-item flex items-center gap-3 px-3 py-2.5 mx-2 rounded-xl <%= (pageKey.equals("leavehistory")) ? "active-blue" : "text-slate-400 hover:bg-slate-800/50 hover:text-white" %>">
			<span class="shrink-0"><%= ClipboardListIcon("w-5 h-5") %></span> <span
			class="hidden lg:block whitespace-nowrap text-sm font-semibold">My
				History</span>
		</a>
		<% } %>
	</nav>
</aside>