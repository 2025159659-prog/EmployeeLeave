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
* { box-sizing: border-box; }

body {
    margin: 0;
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
    box-shadow: 0 10px 25px rgba(0,0,0,0.08);
    overflow: hidden;
}

.card-header {
    background: #2563eb;
    color: white;
    padding: 24px;
    text-align: center;
}

.card-header h1 {
    margin: 0;
    font-size: 22px;
}

.card-header p {
    font-size: 13px;
    opacity: .9;
}

.card-body {
    padding: 24px;
}

.form-group {
    margin-bottom: 14px;
}

label {
    display: block;
    font-size: 13px;
    font-weight: 600;
    margin-bottom: 4px;
}

input {
    width: 100%;
    padding: 10px 12px;
    border-radius: 8px;
    border: 1px solid #cbd5e1;
    font-size: 14px;
}

input:focus {
    outline: none;
    border-color: #2563eb;
    box-shadow: 0 0 0 2px rgba(37,99,235,.25);
}

.password-wrapper {
    position: relative;
}

.password-wrapper input {
    padding-right: 42px;
}

.toggle-btn {
    position: absolute;
    right: 10px;
    top: 50%;
    transform: translateY(-50%);
    background: none;
    border: none;
    cursor: pointer;
    color: #94a3b8;
}

.btn-primary {
    width: 100%;
    margin-top: 6px;
    padding: 10px;
    border-radius: 8px;
    border: none;
    background: #2563eb;
    color: white;
    font-weight: bold;
    cursor: pointer;
}

.btn-primary:hover {
    background: #1d4ed8;
}

.alert-error {
    background: #fee2e2;
    border: 1px solid #fecaca;
    color: #b91c1c;
    padding: 8px;
    border-radius: 8px;
    font-size: 13px;
    margin-bottom: 10px;
}
</style>
</head>

<body>

<div class="card">

    <div class="card-header">
        <div class="flex justify-center mb-2">
            <img src="https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcRNhLlRcJ19hFyLWQOGP3EWiaxRZiHWupjWp6xtRzs5cdMeCUzu"
                 class="w-20 h-20 bg-white rounded-2xl p-2 shadow-sm object-contain">
        </div>
        <h1>Employee Leave System</h1>
        <p>Login using your registered account</p>
    </div>

    <div class="card-body">

        <!-- ERROR MESSAGE -->
        <c:if test="${not empty param.error}">
            <div class="alert-error">
                <c:out value="${param.error}"/>
            </div>
        </c:if>

        <form action="LoginServlet" method="post">

            <div class="form-group">
                <label>Email Address</label>
                <input type="email" name="email" required>
            </div>

            <div class="form-group">
                <label>Password</label>
                <div class="password-wrapper">
                    <input type="password" id="password" name="password" required>
                    <button type="button" class="toggle-btn"
                            onclick="togglePassword()">
                        <%= EyeIcon("w-5 h-5") %>
                    </button>
                </div>
            </div>

            <button type="submit" class="btn-primary">Sign In</button>
        </form>

    </div>
</div>

<script>
function togglePassword() {
    const p = document.getElementById("password");
    p.type = (p.type === "password") ? "text" : "password";
}
</script>

</body>
</html>
