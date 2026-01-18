<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ include file="icon.jsp"%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Employee Login</title>
<script src="https://cdn.tailwindcss.com"></script>
<style>
* {
	box-sizing: border-box;
}

body {
	margin: 0;
	padding: 0;
	font-family: Arial, sans-serif;
	background: #f1f5f9;
	display: flex;
	align-items: center;
	justify-content: center;
	min-height: 100vh;
}

.card {
	background: #ffffff;
	width: 380px;
	border-radius: 16px;
	box-shadow: 0 10px 25px rgba(0, 0, 0, 0.08);
	overflow: hidden;
}

.card-header {
	background: #2563eb;
	color: #ffffff;
	padding: 24px;
	text-align: center;
}

.logo-box {
	width: 56px;
	height: 56px;
	border-radius: 14px;
	border: 2px solid rgba(255, 255, 255, 0.5);
	display: flex;
	align-items: center;
	justify-content: center;
	margin: 0 auto 10px;
	font-weight: bold;
	font-size: 24px;
}

.card-header h1 {
	margin: 0;
	font-size: 22px;
}

.card-header p {
	margin: 4px 0 0;
	font-size: 13px;
	opacity: 0.9;
}

.card-body {
	padding: 24px 24px 28px;
}

.form-group {
	margin-bottom: 14px;
}

label {
	display: block;
	margin-bottom: 4px;
	font-size: 13px;
	color: #374151;
	font-weight: 600;
}

input[type="email"], input[type="password"], input[type="text"] {
	width: 100% !important; /* Paksa width 100% */
	padding: 10px 12px;
	border-radius: 8px;
	border: 1px solid #cbd5e1;
	font-size: 14px;
	transition: all 0.2s;
	display: block;
}

/* Tambah focus state untuk type="text" sekali */
input[type="email"]:focus, input[type="password"]:focus, input[type="text"]:focus
	{
	outline: none;
	border-color: #2563eb;
	box-shadow: 0 0 0 2px rgba(37, 99, 235, 0.25);
}

.password-wrapper {
	position: relative;
	width: 100%; /* Pastikan wrapper pun full width */
}

.password-wrapper input {
	padding-right: 45px !important;
}

.toggle-btn {
	position: absolute;
	right: 12px;
	top: 50%;
	transform: translateY(-50%);
	/* Bagi dia duduk tengah secara vertical */
	background: none;
	border: none;
	cursor: pointer;
	color: #94a3b8;
	display: flex;
	align-items: center;
	padding: 0;
	outline: none;
}

.btn-primary {
	width: 100%;
	padding: 10px 12px;
	border-radius: 8px;
	border: none;
	background: #2563eb;
	color: white;
	font-size: 15px;
	font-weight: bold;
	cursor: pointer;
	margin-top: 6px;
}

.btn-primary:hover {
	background: #1d4ed8;
}

.alert-error {
	background: #fee2e2;
	color: #b91c1c;
	border: 1px solid #fecaca;
	padding: 8px 10px;
	border-radius: 8px;
	font-size: 13px;
	margin-bottom: 10px;
}

.demo-box {
	margin-top: 14px;
	padding: 8px 10px;
	background: #f8fafc;
	border-radius: 8px;
	border: 1px solid #e2e8f0;
	font-size: 11px;
	color: #64748b;
}

.password-wrapper {
	position: relative;
	display: flex;
	align-items: center;
}
</style>
</head>
<body>

	<div class="card">
		<div class="card-header">
			<div class="flex justify-center mb-2">
				<img
					src="https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcRNhLlRcJ19hFyLWQOGP3EWiaxRZiHWupjWp6xtRzs5cdMeCUzu"
					alt="Logo Klinik"
					class="w-20 h-20 object-contain bg-white rounded-2xl p-2 shadow-sm">
			</div>
			<h1>Employee Leave System</h1>
			<p>Login using your registered account</p>
		</div>

		<div class="card-body">
			<!-- Error from servlet -->
			<c:if test="${not empty param.error}">
				<div class="alert-error">
					<c:out value="${param.error}" />
				</div>
			</c:if>

			<!-- Optional message -->
			<c:if test="${not empty param.msg}">
				<div class="demo-box">
					<c:out value="${param.msg}" />
				</div>
			</c:if>

			<form action="LoginServlet" method="post">
				<div class="form-group">
					<label for="email">Email Address</label> <input type="email"
						id="email" name="email" placeholder="you@example.com" required />
				</div>


				<div class="form-group">
					<label for="password">Password</label>
					<div class="password-wrapper">
						<input type="password" id="password" name="password"
							placeholder="Enter your password" required />

						<button type="button" class="toggle-btn"
							onclick="togglePassword('password')">
							<%=EyeIcon("w-5 h-5")%>
						</button>
					</div>
				</div>

				<button type="submit" class="btn-primary">Sign In</button>


			</form>
		</div>
	</div>

	<script>
		function togglePassword(inputId) {
			const input = document.getElementById(inputId);
			if (input.type === 'password') {
				input.type = 'text';
			} else {
				input.type = 'password';
			}
		}
	</script>
</body>
</html>
