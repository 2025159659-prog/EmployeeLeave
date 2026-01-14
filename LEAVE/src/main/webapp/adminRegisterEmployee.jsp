<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ include file="icon.jsp" %>
<%
    if (session.getAttribute("empid") == null || session.getAttribute("role") == null ||
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
    <title>Register Employee | Admin Access</title>
    
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <style>
        :root {
            --bg: #f8fafc;
            --card: #ffffff;
            --border: #cbd5e1;
            --text: #1e293b;
            --muted: #64748b;
            --blue-primary: #2563eb;
            --blue-light: #eff6ff;
            --blue-hover: #1d4ed8;
            --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
            --radius: 12px;
        }

        * { 
            box-sizing: border-box; 
            font-family: 'Inter', Arial, sans-serif !important; 
        }
        
        body { 
            margin: 0; 
            background: var(--bg); 
            color: var(--text); 
            overflow-x: hidden;
        }
        
        main { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }

        .pageWrap { 
            padding: 32px 40px; 
            max-width: 1000px; 
            margin: 0 auto;
        }

        h2.title { 
            font-size: 26px; 
            font-weight: 800; 
            margin: 0; 
            color: var(--text); 
            text-transform: uppercase; 
            letter-spacing: -0.025em;
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

        .tabs { display: flex; gap: 12px; margin: 24px 0; }
        .tab {
            text-decoration: none; font-weight: 800; font-size: 12px; padding: 10px 16px;
            border-radius: 10px; border: 1px solid var(--border); background: #fff; color: var(--muted);
            text-transform: uppercase; transition: 0.2s;
            display: inline-flex;
            align-items: center;
        }
        .tab.active { 
            border-color: var(--blue-primary); 
            background: var(--blue-light); 
            color: var(--blue-primary); 
        }
        .tab:hover:not(.active) {
            border-color: var(--text);
            color: var(--text);
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
        .cardHead span { font-weight: 800; font-size: 15px; color: var(--text); text-transform: uppercase; }

        .cardBody { padding: 32px; }

        .grid-form { 
            display: grid; 
            grid-template-columns: 1fr 1fr; 
            gap: 20px; 
        }
        .field { display: flex; flex-direction: column; gap: 8px; }
        .span2 { grid-column: span 2; }
        
        label { 
            font-size: 11px; 
            font-weight: 800; 
            color: var(--muted); 
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        input, select {
            width: 100%; 
            height: 48px;
            padding: 0 18px; 
            border: 1px solid var(--border);
            border-radius: 10px; 
            font-size: 14px; 
            background: #fff;
            color: var(--text);
            transition: 0.2s;
            font-weight: 500;
        }
        
        input:focus, select:focus { 
            outline: none; 
            border-color: var(--blue-primary); 
            box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.1); 
        }
        input::placeholder { color: #cbd5e1; }

        .actions { 
            display: flex; 
            justify-content: flex-end; 
            gap: 12px; 
            margin-top: 32px; 
            padding-top: 24px;
            border-top: 1px solid #f1f5f9;
        }

        .btn { 
            padding: 12px 24px; 
            border-radius: 10px; 
            cursor: pointer; 
            font-weight: 800; 
            font-size: 13px; 
            text-decoration: none; 
            text-transform: uppercase;
            transition: 0.2s;
            border: 1px solid transparent;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .btnPrimary { background: var(--blue-primary); color: #fff; }
        .btnPrimary:hover {
            background: var(--blue-hover);
            transform: translateY(-1px);
            box-shadow: 0 4px 6px -1px rgba(37, 99, 235, 0.3);
        }
        
        .btnGhost { background: #fff; border: 1px solid var(--border); color: var(--text); }
        .btnGhost:hover { background: #f8fafc; border-color: var(--text); }

        .msg, .err { padding: 14px 18px; border-radius: 12px; font-size: 13px; margin-bottom: 20px; font-weight: 700; display: flex; align-items: center; gap: 10px; }
        .msg { background: #f0fdfa; border: 1px solid #ccfbf1; color: #0f766e; }
        .err { background: #fef2f2; border: 1px solid #fee2e2; color: #b91c1c; }

        /* ✅ Custom Modal Styles */
        .confirm-overlay {
            position: fixed;
            inset: 0;
            background: rgba(15, 23, 42, 0.6);
            backdrop-filter: blur(4px);
            z-index: 9999;
            display: none;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .confirm-overlay.show { display: flex; }
        
        .confirm-modal {
            background: white;
            width: 100%;
            max-width: 450px;
            border-radius: 20px;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
            overflow: hidden;
            animation: slideUp 0.3s ease;
        }

        @keyframes slideUp { 
            from { opacity: 0; transform: translateY(20px); } 
            to { opacity: 1; transform: translateY(0); } 
        }

        .confirm-header {
            padding: 24px;
            text-align: center;
            border-bottom: 1px solid #f1f5f9;
        }
        .confirm-body { padding: 32px 24px; text-align: center; }
        .confirm-footer {
            padding: 16px 24px;
            background: #f8fafc;
            display: flex;
            justify-content: center;
            gap: 12px;
        }

        @media (max-width: 768px) { 
            .grid-form { grid-template-columns: 1fr; } 
            .span2 { grid-column: span 1; } 
        }
        
        .icon-sm { width: 16px; height: 16px; }
        .icon-md { width: 20px; height: 20px; }
        .icon-lg { width: 24px; height: 24px; }
    </style>
    
    <script>
        /**
         * Custom Modal Confirmation logic
         */
        function showConfirmModal(event) {
            event.preventDefault(); // Prevent immediate submission
            
            const nameInput = document.querySelector('input[name="fullname"]');
            const name = nameInput ? nameInput.value.trim() : "this user";
            
            // Set the name in the modal text
            document.getElementById('confirmNameText').textContent = name.toUpperCase();
            
            // Show the modal
            document.getElementById('confirmOverlay').classList.add('show');
            return false;
        }

        function closeConfirmModal() {
            document.getElementById('confirmOverlay').classList.remove('show');
        }

        function proceedWithRegistration() {
            document.getElementById('registrationForm').submit();
        }
    </script>
</head>

<body class="flex">
    <jsp:include page="sidebar.jsp" />

    <main class="flex-1 ml-20 lg:ml-64 min-h-screen transition-all duration-300">
        <jsp:include page="topbar.jsp" />

        <div class="pageWrap">
            <div class="mb-8">
                <h2 class="title">REGISTER EMPLOYEE</h2>
                <span class="sub-label">Complete the fields below to create a secure employee profile.</span>
            </div>

            <div class="tabs">
                <a class="tab active" href="RegisterEmployee">
                    <%= PlusIcon("icon-sm mr-2") %>Register
                </a>
                <a class="tab" href="EmployeeDirectory">
                    <%= UsersIcon("icon-sm mr-2") %>Directory
                </a>
            </div>

            <c:if test="${not empty param.msg}">
                <div class="msg shadow-sm"><%= CheckCircleIcon("icon-md") %> ${param.msg}</div>
            </c:if>
            <c:if test="${not empty param.error}">
                <div class="err shadow-sm"><%= AlertIcon("icon-md") %> ${param.error}</div>
            </c:if>

            <div class="card">
                <div class="cardHead">
                    <span>Account Identification</span>
                    <%= BriefcaseIcon("icon-lg text-blue-200") %>
                </div>

                <div class="cardBody">
                    <form id="registrationForm" action="RegisterEmployee" method="post" onsubmit="return showConfirmModal(event)">
                        <div class="grid-form">
                            <div class="field span2">
                                <label>Full Name as per IC *</label>
                                <input type="text" name="fullname" placeholder="e.g., Ahmad Bin Abdullah" required>
                            </div>

                            <div class="field">
                                <label>Work Email Address *</label>
                                <input type="email" name="email" placeholder="e.g., ahmad@klinik.com" required>
                            </div>

                            <div class="field">
                                <label>System Password *</label>
                                <input type="password" name="password" placeholder="••••••••" required>
                            </div>

                            <div class="field">
                                <label>IC Number *</label>
                                <input type="text" name="icNumber" placeholder="900101045566" required>
                            </div>

                            <div class="field">
                                <label>Gender Selection *</label>
                                <select name="gender" required>
                                    <option value="" disabled selected>Select Gender</option>
                                    <option value="M">Male</option>
                                    <option value="F">Female</option>
                                </select>
                            </div>

                            <div class="field">
                                <label>Phone Contact</label>
                                <input type="text" name="phoneNo" placeholder="0123456789">
                            </div>

                            <div class="field">
                                <label>Date of Joining *</label>
                                <input type="date" name="hireDate" required>
                            </div>

                            <div class="field span2">
                                <label>Street Address *</label>
                                <input type="text" name="street" placeholder="No. 12, Jalan Merlimau" required>
                            </div>

                            <div class="field">
                                <label>City *</label>
                                <input type="text" name="city" placeholder="Jasin" required>
                            </div>

                            <div class="field">
                                <label>Postal Code *</label>
                                <input type="text" name="postalCode" placeholder="77300" required>
                            </div>

                            <div class="field span2">
                                <label>State *</label>
                                <select name="state" required>
                                    <option value="" disabled selected>Select State</option>
                                    <optgroup label="States">
                                        <option value="Johor">Johor</option>
                                        <option value="Kedah">Kedah</option>
                                        <option value="Kelantan">Kelantan</option>
                                        <option value="Melaka">Melaka</option>
                                        <option value="Negeri Sembilan">Negeri Sembilan</option>
                                        <option value="Pahang">Pahang</option>
                                        <option value="Perak">Perak</option>
                                        <option value="Perlis">Perlis</option>
                                        <option value="Penang">Penang</option>
                                        <option value="Selangor">Selangor</option>
                                        <option value="Terengganu">Terengganu</option>
                                    </optgroup>
                                    <optgroup label="Federal Territories">
                                        <option value="Kuala Lumpur">Kuala Lumpur</option>
                                        <option value="Putrajaya">Putrajaya</option>
                                        <option value="Labuan">Labuan</option>
                                    </optgroup>
                                    <optgroup label="East Malaysia">
                                        <option value="Sabah">Sabah</option>
                                        <option value="Sarawak">Sarawak</option>
                                    </optgroup>
                                </select>
                            </div>
                        </div>

                        <div class="actions">
                            <a class="btn btnGhost" href="EmployeeDirectory">
                                <%= ArrowLeftIcon("icon-sm") %> Cancel
                            </a>
                            <button class="btn btnPrimary" type="submit">
                                <%= SaveIcon("icon-sm") %> Create Account
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </main>

    <!-- ✅ Custom Confirmation Modal -->
    <div id="confirmOverlay" class="confirm-overlay">
        <div class="confirm-modal">
            <div class="confirm-header">
                <div class="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
                    <%= UsersIcon("w-6 h-6 text-blue-600") %>
                </div>
                <h3 class="text-lg font-extrabold text-slate-900 uppercase">Confirm Registration</h3>
            </div>
            <div class="confirm-body">
                <p class="text-sm text-slate-500 font-medium leading-relaxed">
                    ARE YOU SURE WANT TO REGISTER <br>
                    <span id="confirmNameText" class="text-blue-600 font-black"></span> <br>
                    AS A NEW EMPLOYEE?
                </p>
            </div>
            <div class="confirm-footer">
                <button type="button" onclick="closeConfirmModal()" class="btn btnGhost px-6 py-2.5">
                    No, Cancel
                </button>
                <button type="button" onclick="proceedWithRegistration()" class="btn btnPrimary px-6 py-2.5">
                    Yes, Register
                </button>
            </div>
        </div>
    </div>
</body>
</html>