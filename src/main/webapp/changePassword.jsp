<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ include file="icon.jsp"%>

<%
if (session.getAttribute("empid") == null) {
	response.sendRedirect("login.jsp?error=Please login.");
	return;
}
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Security Settings | Klinik Dr Mohamad</title>
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
	--blue: #2563eb;
	--blue-hover: #1d4ed8;
	--radius: 20px;
}

* {
	box-sizing: border-box;
	font-family: 'Inter', sans-serif !important;
}

body {
	margin: 0;
	background: var(--bg);
	color: var(--text);
	overflow-x: hidden;
	-webkit-font-smoothing: antialiased;
}

/* Consistent PageWrap matching your other pages */
.pageWrap {
	padding: 32px 40px;
	max-width: 1300px;
	margin: 0;
}

/* Consistent Title & Sub-label styles */
.title {
	font-size: 26px;
	font-weight: 800;
	margin: 0;
	text-transform: uppercase;
	color: var(--text);
	letter-spacing: -0.02em;
}

.sub-label {
	color: var(--blue);
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
	box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.04);
	overflow: hidden;
	margin-top: 24px;
	max-width: 500px;
}

.label-xs {
	font-size: 10px;
	font-weight: 900;
	color: var(--muted);
	text-transform: uppercase;
	letter-spacing: 0.1em;
	margin-bottom: 8px;
	display: block;
}

/* THE FIX: Specificity override for Tailwind Reset */
.pageWrap input {
	width: 100% !important;
	padding: 0 18px !important; /* Horizontal gap fix */
	height: 52px !important;
	border: 1.5px solid #e2e8f0 !important;
	border-radius: 12px !important;
	font-size: 14px !important;
	font-weight: 600 !important;
	background: #fff !important;
	color: var(--text) !important;
	outline: none !important;
	display: block !important;
	box-sizing: border-box !important;
	transition: all 0.2s;
}

.pageWrap input::placeholder {
	color: #94a3b8;
	font-weight: 400;
}

.pageWrap input:focus {
	border-color: var(--blue) !important;
	box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.08) !important;
}

.btn-blue {
	width: 100%;
	height: 50px;
	border-radius: 14px;
	font-weight: 800;
	font-size: 12px;
	transition: 0.2s;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	gap: 10px;
	cursor: pointer;
	text-transform: uppercase;
	letter-spacing: 0.05em;
	background: var(--blue);
	color: #fff;
	border: none;
}

.btn-blue:hover {
	background: var(--blue-hover);
	transform: translateY(-1px);
}

.msg-box {
	padding: 12px 16px;
	border-radius: 12px;
	font-size: 12px;
	font-weight: 700;
	margin-bottom: 20px;
	display: flex;
	align-items: center;
	gap: 10px;
	transition: opacity 0.5s ease;
}

.icon-sm {
	width: 16px;
	height: 16px;
}
</style>
</head>
<body class="flex">

	<jsp:include page="sidebar.jsp" />

	<main
		class="ml-20 lg:ml-64 min-h-screen flex-1 transition-all duration-300">
		<jsp:include page="topbar.jsp" />

		<div class="pageWrap">
			<div class="mb-4">
				<h2 class="title">CHANGE PASSWORD</h2>
				<span class="sub-label">Maintain account security with a
					unique password</span>
			</div>

			<div class="card">
				<div class="px-8 py-4 border-b border-slate-50 bg-slate-50/30">
					<span
						class="text-[9px] font-black text-slate-400 uppercase tracking-widest">Security
						Credentials</span>
				</div>

				<form action="ChangePassword" method="post" class="p-8 space-y-6">

					<c:if test="${not empty param.error}">
						<div id="statusAlert"
							class="msg-box bg-red-50 text-red-600 border border-red-100">
							<%=AlertIcon("icon-sm")%>
							${param.error}
						</div>
					</c:if>
					<c:if test="${not empty param.msg}">
						<div id="statusAlert"
							class="msg-box bg-emerald-50 text-emerald-600 border border-emerald-100">
							<%=CheckCircleIcon("icon-sm")%>
							${param.msg}
						</div>
					</c:if>

					<div class="space-y-2">
						<span class="label-xs">Current Password</span> <input
							type="password" name="oldPassword" required
							placeholder="Enter current password">
					</div>

					<div class="pt-4 border-t border-slate-100 space-y-6">
						<div class="space-y-2">
							<span class="label-xs">New Password</span>
							<div class="relative">
								<input type="password" id="newPassword" name="newPassword"
									required placeholder="Enter strong new password">
								<button type="button" onclick="togglePassword('newPassword')"
									class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-blue-600 transition-colors">
									<%=EyeIcon("icon-sm")%>
								</button>
							</div>
						</div>

						<div class="space-y-2">
							<span class="label-xs">Confirm New Password</span>
							<div class="relative">
								<input type="password" id="confirmPassword"
									name="confirmPassword" required
									placeholder="Repeat new password">
								<button type="button"
									onclick="togglePassword('confirmPassword')"
									class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-blue-600 transition-colors">
									<%=EyeIcon("icon-sm")%>
								</button>
							</div>
						</div>
					</div>

					<div class="pt-4">
						<button type="submit"
							class="btn-blue shadow-lg shadow-blue-500/20">
							<%=LockIcon("icon-sm")%>
							Update Password
						</button>
						<a href="Profile"
							class="block text-center mt-5 text-[10px] font-black text-slate-400 hover:text-blue-600 uppercase tracking-widest transition-colors">
							Return to Profile </a>
					</div>
				</form>
			</div>
		</div>
	</main>

	<script>

function validateForm(event) {
    const oldPass = document.getElementsByName('oldPassword')[0].value;
    const newPass = document.getElementsByName('newPassword')[0].value;
    const confirmPass = document.getElementsByName('confirmPassword')[0].value;

    if (newPass === oldPass) {
        alert("NEW PASSWORD CANNOT BE THE SAME AS CURRENT PASSWORD!");
        event.preventDefault(); // Berhenti daripada hantar borang
        return false;
    }
    
    if (newPass !== confirmPass) {
        alert("NEW PASSWORDS DO NOT MATCH!");
        event.preventDefault();
        return false;
    }
    return true;
}
    // Fungsi untuk Show/Hide Password sahaja
    function togglePassword(inputId) {
        const input = document.getElementById(inputId);
        if (input.type === 'password') {
            input.type = 'text';
        } else {
            input.type = 'password';
        }
    }

    // Fungsi asal untuk hilangkan alert automatik
    window.addEventListener('DOMContentLoaded', () => {
        const alert = document.getElementById('statusAlert');
        if (alert) {
            setTimeout(() => {
                alert.style.opacity = '0';
                setTimeout(() => { alert.style.display = 'none'; }, 500);
            }, 3000);
        }
    });
</script>

</body>
</html>
