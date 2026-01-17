<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*"%>
<%@ page import="java.text.SimpleDateFormat"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ include file="icon.jsp"%>

<%
    if (session.getAttribute("empid") == null ||
        session.getAttribute("role") == null ||
        !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
        response.sendRedirect("login.jsp?error=Please login as admin.");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Employee Directory | Admin Access</title>

<script src="https://cdn.tailwindcss.com"></script>
<link
	href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap"
	rel="stylesheet">

<style>
:root {
	--bg: #f1f5f9;
	--card: #fff;
	--border: #cbd5e1;
	--text: #1e293b;
	--muted: #64748b;
	--blue-primary: #2563eb;
	--blue-light: #eff6ff;
	--red: #ef4444;
	--green: #10b981;
	--shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
	--radius: 16px;
}

* {
	box-sizing: border-box;
	font-family: 'Inter', sans-serif !important;
}

body {
	background: var(--bg);
	color: var(--text);
	margin: 0;
}

.pageWrap {
	padding: 32px 40px;
	max-width: 1240px;
	margin: 0 auto;
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

.tabs {
	display: flex;
	gap: 12px;
	margin: 24px 0;
}

.tab {
	text-decoration: none;
	font-weight: 800;
	font-size: 12px;
	padding: 10px 18px;
	border-radius: 10px;
	border: 1px solid var(--border);
	background: #fff;
	color: var(--muted);
	text-transform: uppercase;
	transition: 0.2s;
	display: inline-flex;
	align-items: center;
	gap: 8px;
}

.tab.active {
	border-color: var(--blue-primary);
	background: var(--blue-light);
	color: var(--blue-primary);
}

.card {
	background: var(--card);
	border: 1px solid var(--border);
	border-radius: var(--radius);
	box-shadow: var(--shadow);
	overflow: hidden;
}

.cardHead {
	padding: 20px 24px;
	border-bottom: 1px solid #f1f5f9;
	display: flex;
	justify-content: space-between;
	align-items: center;
}

.cardHead span {
	font-weight: 800;
	font-size: 15px;
	color: var(--text);
	text-transform: uppercase;
}

table {
	width: 100%;
	border-collapse: collapse;
}

th, td {
	border-bottom: 1px solid #f1f5f9;
	padding: 18px 24px;
	text-align: left;
}

th {
	background: #f8fafc;
	font-size: 11px;
	text-transform: uppercase;
	color: var(--muted);
	font-weight: 800;
	letter-spacing: 0.05em;
}

.row-inactive {
	background-color: #f8fafc;
	opacity: 0.6;
	filter: grayscale(1);
}

.badge {
	padding: 4px 10px;
	border-radius: 8px;
	font-size: 10px;
	font-weight: 800;
	text-transform: uppercase;
	border: 1px solid transparent;
}

.badge-admin {
	background: #eff6ff;
	color: var(--blue-primary);
	border-color: #dbeafe;
}

.badge-active {
	background: #ecfdf5;
	color: var(--green);
	border-color: #d1fae5;
}

.badge-inactive {
	background: #fef2f2;
	color: var(--red);
	border-color: #fee2e2;
}

.btnAction {
	font-weight: 800;
	font-size: 11px;
	padding: 8px 16px;
	border-radius: 8px;
	cursor: pointer;
	transition: 0.2s;
	text-transform: uppercase;
	display: inline-flex;
	align-items: center;
	gap: 6px;
	border: 1px solid transparent;
}

.btnDeactivate {
	color: var(--red);
	border-color: #fee2e2;
	background: #fff;
}

.btnDeactivate:hover {
	background: var(--red);
	color: #fff;
	border-color: var(--red);
}

.btnActivate {
	color: var(--green);
	border-color: #d1fae5;
	background: #fff;
}

.btnActivate:hover {
	background: var(--green);
	color: #fff;
	border-color: var(--green);
}

.modal-overlay {
	position: fixed;
	top: 0;
	left: 0;
	width: 100%;
	height: 100%;
	background: rgba(15, 23, 42, 0.6);
	backdrop-filter: blur(4px);
	display: none;
	align-items: center;
	justify-content: center;
	z-index: 1000;
}

.modal-content {
	background: white;
	width: 400px;
	border-radius: 16px;
	padding: 32px;
	box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
	text-align: center;
}

.modal-active {
	display: flex;
}

.msg-fade {
	transition: opacity 0.5s ease, transform 0.5s ease;
	opacity: 1;
}

.msg-hidden {
	opacity: 0;
	transform: translateY(-10px);
	pointer-events: none;
}

/* Custom color for Cancel Button */
.btn-cancel {
	background: #f1f5f9;
	color: #475569;
}

.btn-cancel:hover {
	background: #e2e8f0;
}
</style>
</head>

<body class="flex">
	<jsp:include page="sidebar.jsp" />

	<main
		class="flex-1 ml-20 lg:ml-64 min-h-screen transition-all duration-300">
		<jsp:include page="topbar.jsp" />

		<div class="pageWrap">
			<div class="mb-8">
				<h2 class="title">Employee Directory</h2>
				<span class="sub-label">List of employee record account
					permissions and status</span>
			</div>

			<div class="tabs">
				<a class="tab" href="RegisterEmployee"> <%= PlusIcon("w-3.5 h-3.5") %>Register
				</a> <a class="tab active" href="EmployeeDirectory"> <%= UsersIcon("w-3.5 h-3.5") %>Directory
				</a>
			</div>

			<c:if test="${not empty param.msg}">
				<div id="statusMsg"
					class="msg-fade bg-emerald-50 border border-emerald-100 p-4 rounded-xl text-emerald-700 font-bold mb-6 flex items-center gap-2 shadow-sm">
					<%= CheckCircleIcon("w-5 h-5") %>
					${param.msg}
				</div>
			</c:if>

			<div class="card">
				<div class="cardHead">
					<span>Staff Records</span>
					<%= BriefcaseIcon("w-6 h-6 text-blue-200") %>
				</div>

				<div class="overflow-x-auto">
					<table>
						<thead>
							<tr>
								<th>Staff Profile</th>
								<th>Contact & Access</th>
								<th>Join Date</th>
								<th style="text-align: center;">Status</th>
								<th style="text-align: right;">Actions</th>
							</tr>
						</thead>
						<tbody>
							<%
                            List<Map<String,Object>> users = (List<Map<String,Object>>) request.getAttribute("users");
                            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
                            Calendar cal = Calendar.getInstance();

                            if (users == null || users.isEmpty()) {
                        %>
							<tr>
								<td colspan="5"
									style="text-align: center; padding: 48px; color: var(--muted);">
									<%= InfoIcon("w-10 h-10 mx-auto mb-2 opacity-20") %> No
									database entries found.
								</td>
							</tr>
							<%
                            } else {
                                for (Map<String,Object> u : users) {
                                    int empid = (Integer) u.get("empid");
                                    String fullname = String.valueOf(u.get("fullname"));
                                    String email = String.valueOf(u.get("email"));
                                    String role = String.valueOf(u.get("role"));
                                    String phone = String.valueOf(u.get("phone"));
                                    String status = String.valueOf(u.get("status") != null ? u.get("status") : "ACTIVE");
                                    Date hiredate = (Date) u.get("hiredate");
                                    
                                    String joinYear = "0000";
                                    if (hiredate != null) {
                                        cal.setTime(hiredate);
                                        joinYear = String.valueOf(cal.get(Calendar.YEAR));
                                    }
                                    String customId = "EMP-" + joinYear + "-0" + empid;

                                    boolean isActive = "ACTIVE".equalsIgnoreCase(status);
                                    boolean isAdmin = "ADMIN".equalsIgnoreCase(role);
                        %>
							<tr class="<%= !isActive ? "row-inactive" : "" %>">
								<td>
									<div class="font-bold text-slate-800 uppercase text-sm"><%= fullname %></div>
									<div class="mt-1 flex items-center gap-2">
										<span
											class="badge <%= isAdmin ? "badge-admin" : "bg-slate-100 text-slate-500 border-slate-200" %>">
											<%= role %>
										</span> <span
											class="text-[10px] font-bold text-slate-400 uppercase tracking-tighter"><%= customId %></span>
									</div>
								</td>
								<td>
									<div class="text-[13px] font-semibold text-slate-700"><%= email %></div>
									<div class="text-[11px] text-slate-400 mt-1 font-medium"><%= (phone == null || phone.isBlank()) ? "---" : phone %></div>
								</td>
								<td class="text-[13px] font-bold text-slate-600"><%= hiredate != null ? sdf.format(hiredate) : "---" %>
								</td>
								<td style="text-align: center;"><span
									class="badge <%= isActive ? "badge-active" : "badge-inactive" %>">
										<%= status %>
								</span></td>
								<td style="text-align: right;">
									<% if (!isAdmin) { %>
									<button
										class="btnAction <%= isActive ? "btnDeactivate" : "btnActivate" %>"
										onclick="showConfirmModal('<%= empid %>', '<%= isActive ? "INACTIVE" : "ACTIVE" %>', '<%= fullname %>')">
										<%= isActive ? XCircleIcon("w-3.5 h-3.5") + " Deactivate" : CheckCircleIcon("w-3.5 h-3.5") + " Reactivate" %>
									</button> <% } else { %> <span
									class="text-[10px] font-black text-blue-300 uppercase italic tracking-widest">
										<%= ShieldCheckIcon("w-3.5 h-3.5 inline mr-1") %>System Root
								</span> <% } %>
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
		</div>

		<!-- Confirmation Modal -->
		<div id="confirmModal" class="modal-overlay">
			<div class="modal-content">
				<div id="modalIconContainer"
					class="w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4"></div>
				<h3 id="modalTitle"
					class="text-xl font-black text-slate-800 mb-2 uppercase tracking-tight">Are
					you sure?</h3>
				<p id="modalBody"
					class="text-slate-500 text-sm mb-8 font-medium leading-relaxed"></p>

				<form id="modalForm" action="ToggleEmployeeStatus" method="post">
					<input type="hidden" name="empid" id="modalEmpId"> <input
						type="hidden" name="targetStatus" id="modalTargetStatus">
					<div class="flex gap-3">
						<button type="button"
							class="flex-1 px-4 py-3 rounded-xl border border-slate-200 font-bold text-xs uppercase btn-cancel"
							onclick="closeModal()">Cancel</button>
						<button type="submit" id="modalSubmitBtn"
							class="flex-1 px-4 py-3 rounded-xl font-bold text-xs uppercase text-white shadow-lg">Confirm</button>
					</div>
				</form>
			</div>
		</div>
	</main>

	<script>
        // Auto-remove message after 3 seconds
        window.onload = function() {
            const statusMsg = document.getElementById('statusMsg');
            if (statusMsg) {
                setTimeout(() => {
                    statusMsg.classList.add('msg-hidden');
                    setTimeout(() => statusMsg.remove(), 500);
                }, 3000);
            }
        };

        function showConfirmModal(id, target, name) {
            const modal = document.getElementById('confirmModal');
            const formId = document.getElementById('modalEmpId');
            const formStatus = document.getElementById('modalTargetStatus');
            const body = document.getElementById('modalBody');
            const submitBtn = document.getElementById('modalSubmitBtn');
            const iconBox = document.getElementById('modalIconContainer');
            const title = document.getElementById('modalTitle');

            formId.value = id;
            formStatus.value = target;

            // Convert staff name to uppercase for strict styling
            const upperName = name.toUpperCase();

            if (target === 'INACTIVE') {
                title.innerText = "DEACTIVATE STAFF?";
                body.innerHTML = "Are you sure you want to deactivate <b class='text-slate-900'>" + upperName + "</b>? Access will be revoked immediately.";
                submitBtn.style.backgroundColor = "#ef4444";
                iconBox.style.backgroundColor = "#fee2e2";
                iconBox.innerHTML = `<%= XCircleIcon("w-8 h-8 text-red-500") %>`;
            } else {
                title.innerText = "REACTIVATE STAFF?";
                body.innerHTML = "Are you sure you want to reactivate <b class='text-slate-900'>" + upperName + "</b>? System access will be restored.";
                submitBtn.style.backgroundColor = "#10b981";
                iconBox.style.backgroundColor = "#ecfdf5";
                iconBox.innerHTML = `<%= CheckCircleIcon("w-8 h-8 text-emerald-500") %>`;
            }
            modal.classList.add('modal-active');
        }

        function closeModal() {
            document.getElementById('confirmModal').classList.remove('modal-active');
        }

        window.onclick = function(event) {
            const modal = document.getElementById('confirmModal');
            if (event.target == modal) closeModal();
        }
    </script>
</body>
</html>