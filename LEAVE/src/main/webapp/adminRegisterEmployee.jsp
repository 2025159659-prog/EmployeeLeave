<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%
    if (session.getAttribute("empid") == null || session.getAttribute("role") == null ||
        !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
        response.sendRedirect("login.jsp?error=Please login as admin.");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Register Employee</title>
    
    <script src="https://cdn.tailwindcss.com"></script>

    <style>
        :root{
            --bg:#f4f6fb;
            --card:#ffffff;
            --border:#e5e7eb;
            --text:#0f172a;
            --muted:#64748b;
            --primary:#2563eb;
            --primary2:#1d4ed8;
            --shadow:0 10px 25px rgba(0,0,0,0.06);
            --radius:16px;
        }

        /* Ikut sebiji CSS Admin Dashboard awak */
        *{box-sizing:border-box}
        body{margin:0;font-family:Arial, sans-serif;background:var(--bg);color:var(--text);}
        
        .content { padding: 24px; }
        .container { max-width: 1100px; margin: 0 auto; } /* Sama dengan Dashboard */
        
        .pageHeader { margin-bottom: 16px; }
        .pageTitle { margin: 0; font-size: 22px; font-weight: 800; }
        .pageSub { margin-top: 6px; font-size: 13px; color: var(--muted); }

        /* Tabs Navigation */
        .tabs { display: flex; gap: 10px; margin: 14px 0 18px; }
        .tab {
            text-decoration: none; font-weight: 800; font-size: 13px; padding: 10px 12px;
            border-radius: 12px; border: 1px solid var(--border); background: #fff; color: var(--text);
        }
        .tab.active { border-color: rgba(37,99,235,0.35); background: rgba(37,99,235,0.08); color: var(--primary); }

        /* Card & Form Styles */
        .card { background: var(--card); border: 1px solid var(--border); border-radius: var(--radius); box-shadow: var(--shadow); overflow: hidden; }
        .cardHead { padding: 16px 18px; border-bottom: 1px solid #eef2f7; display: flex; justify-content: space-between; align-items: center; gap: 12px; font-weight: 900; }
        .cardBody { padding: 24px; }
        .hint { font-size: 12px; color: var(--muted); font-weight: 700; }

        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
        .field { display: flex; flex-direction: column; gap: 6px; }
        .span2 { grid-column: span 2; }
        
        label { font-size: 12px; font-weight: 800; color: #334155; }
        input, select {
            width: 100%; padding: 10px 12px; border: 1px solid #cbd5e1;
            border-radius: 12px; font-size: 13px; background: #fff;
        }
        input:focus { outline: none; border-color: var(--primary); box-shadow: 0 0 0 3px rgba(37,99,235,0.18); }

        .actions { display: flex; justify-content: flex-end; gap: 10px; margin-top: 10px; }
        .btn { padding: 10px 16px; border: none; border-radius: 12px; cursor: pointer; font-weight: 900; font-size: 12px; text-decoration: none; }
        .btnPrimary { background: var(--primary); color: #fff; }
        .btnGhost { background: #fff; border: 1px solid var(--border); color: var(--text); }

        /* Transition content bila sidebar resize */
        main { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }

        @media (max-width: 860px) { .grid { grid-template-columns: 1fr; } .span2 { grid-column: span 1; } }
    </style>
</head>

<body>
    <jsp:include page="sidebar.jsp" />

    <main class="ml-20 lg:ml-64 min-h-screen transition-all duration-300">
        
        <jsp:include page="topbar.jsp" />

        <div class="content">
            <div class="container">

                <div class="pageHeader">
                    <h2 class="pageTitle">Register Employee</h2>
                    <p class="pageSub">Create a new employee/admin account. Use a valid email because it will be used for login.</p>
                </div>

                <div class="tabs">
                    <a class="tab active" href="RegisterEmployeeServlet">Register Employee</a>
                    <a class="tab" href="EmployeeDirectoryServlet">Employee Directory</a>
                </div>

                <c:if test="${not empty param.msg}">
                    <div class="mb-4 p-3 bg-cyan-50 border border-cyan-200 text-cyan-800 rounded-xl text-xs font-bold">${param.msg}</div>
                </c:if>
                <c:if test="${not empty param.error}">
                    <div class="mb-4 p-3 bg-red-50 border border-red-200 text-red-800 rounded-xl text-xs font-bold">${param.error}</div>
                </c:if>

                <div class="card">
                    <div class="cardHead">
                        <span>Employee Details</span>
                        <span class="hint uppercase">Admin Only</span>
                    </div>

                    <div class="cardBody">
                        <form action="RegisterEmployeeServlet" method="post">
                            <div class="grid">
                                <div class="field span2">
                                    <label>Full Name *</label>
                                    <input type="text" name="fullname" placeholder="e.g., Ali Bin Abu" required>
                                </div>

                                <div class="field">
                                    <label>Email *</label>
                                    <input type="email" name="email" placeholder="e.g., ali@company.com" required>
                                </div>

                                <div class="field">
                                    <label>Password *</label>
                                    <input type="password" name="password" placeholder="Create a password" required>
                                </div>

                                <div class="field">
                                    <label>IC Number *</label>
                                    <input type="text" name="icNumber" placeholder="e.g., 010203041234" required>
                                </div>

                                <div class="field">
                                    <label>Gender *</label>
                                    <select name="gender" required>
                                        <option value="M">Male</option>
                                        <option value="F">Female</option>
                                    </select>
                                </div>

                                <div class="field">
                                    <label>Phone No</label>
                                    <input type="text" name="phoneNo" placeholder="e.g., 01xxxxxxxx">
                                </div>

                                <div class="field">
                                    <label>Hire Date *</label>
                                    <input type="date" name="hireDate" required>
                                </div>

                                <div class="field span2">
                                    <label>Address</label>
                                    <input type="text" name="address" placeholder="e.g., Melaka">
                                </div>

                                <div class="field span2">
                                    <label>Role *</label>
                                    <select name="role" required style="font-weight: 800; color: var(--primary);">
                                        <option value="EMPLOYEE">EMPLOYEE</option>
                                        <option value="ADMIN">ADMIN</option>
                                    </select>
                                </div>
                            </div>

                            <div class="actions">
                                <a class="btn btnGhost" href="EmployeeDirectoryServlet">View Directory</a>
                                <button class="btn btnPrimary" type="submit">Create Account</button>
                            </div>
                        </form>
                    </div>
                </div><div class="mt-8 text-center opacity-40 text-[10px] font-bold uppercase tracking-widest">
                    v1.2.1 © 2024 Klinik Dr Mohamad
                </div>

            </div></div></main>
</body>
</html>