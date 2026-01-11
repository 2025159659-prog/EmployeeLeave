<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ include file="icon.jsp" %>

<%
    // Simple Security check to prevent direct access without login
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
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">

    <style>
        :root {
            --bg: #f8fafc;
            --card: #ffffff;
            --border: #e2e8f0;
            --text: #1e293b;
            --muted: #64748b;
            --blue: #2563eb;
            --blue-hover: #1d4ed8;
            --radius: 16px;
        }

        * { box-sizing: border-box; font-family: 'Inter', sans-serif !important; }
        body { margin: 0; background: var(--bg); color: var(--text); overflow-x: hidden; -webkit-font-smoothing: antialiased; }

        /* Compacted vertical layout for single-screen fit */
        .pageWrap { max-width: 460px; margin: 0 auto; padding: 15px 24px; }
        
        h2.title { 
            font-size: 26px; 
            font-weight: 800; 
            margin: 0; 
            color: var(--text); 
            text-transform: uppercase; 
            letter-spacing: -0.025em;
        }
        
        .sub-label { 
            color: var(--blue); 
            font-size: 11px; 
            font-weight: 800; 
            text-transform: uppercase; 
            letter-spacing: 0.1em;
            margin-top: 2px;
            display: block;
        }

        .card { 
            background: var(--card); 
            border: 1px solid var(--border); 
            border-radius: var(--radius); 
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.04); 
            overflow: hidden; 
            margin-top: 16px;
        }

        .label-xs { font-size: 10px; font-weight: 900; color: var(--muted); text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 4px; display: block; }
        
        input {
            width: 100%; padding: 0 18px; height: 44px; border: 1.5px solid #e2e8f0;
            border-radius: 12px; font-size: 13px; background: #fff; transition: all 0.2s;
            color: var(--text);
        }
        input:focus { outline: none; border-color: var(--blue); box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.08); }

        .btn { 
            width: 100%; height: 44px; border-radius: 12px; font-weight: 800; font-size: 12px; 
            transition: 0.2s; display: inline-flex; align-items: center; justify-content: center; 
            gap: 10px; cursor: pointer; text-transform: uppercase; letter-spacing: 0.02em; 
        }
        .btn-blue { background: var(--blue); color: #fff; }
        .btn-blue:hover { background: var(--blue-hover); transform: translateY(-1px); }

        .msg-box { padding: 10px 14px; border-radius: 10px; font-size: 12px; font-weight: 700; margin-bottom: 16px; display: flex; align-items: center; gap: 8px; }
        
        .icon-sm { width: 14px; height: 14px; }
    </style>
</head>
<body class="flex">

<jsp:include page="sidebar.jsp" />

<main class="ml-20 lg:ml-64 min-h-screen flex-1 transition-all duration-300">
    <jsp:include page="topbar.jsp" />

    <div class="pageWrap">
        <!-- Consistent Header -->
        <div class="mb-4">
            <h2 class="title">CHANGE PASSWORD</h2>
            <span class="sub-label">Maintain account security with a unique password.</span>
        </div>

        <div class="card">
            <div class="px-8 py-3 border-b border-slate-50 bg-slate-50/30">
                <span class="text-[9px] font-black text-slate-400 uppercase tracking-widest">Security Credentials</span>
            </div>

            <!-- Redirection points to /ChangePassword mapped in the Servlet -->
            <form action="ChangePassword" method="post" class="p-6 space-y-4">
                
                <!-- Feedback Messages -->
                <c:if test="${not empty param.error}">
                    <div class="msg-box bg-red-50 text-red-600 border border-red-100">
                        <%= AlertIcon("icon-sm") %> ${param.error}
                    </div>
                </c:if>
                <c:if test="${not empty param.msg}">
                    <div class="msg-box bg-emerald-50 text-emerald-600 border border-emerald-100">
                        <%= CheckCircleIcon("icon-sm") %> ${param.msg}
                    </div>
                </c:if>

                <div>
                    <span class="label-xs">Current Password</span>
                    <input type="password" name="oldPassword" required placeholder="Verify identity with old password">
                </div>

                <div class="pt-4 border-t border-slate-100 space-y-4">
                    <div>
                        <span class="label-xs">New Password</span>
                        <input type="password" name="newPassword" required placeholder="Select a strong password">
                    </div>

                    <div>
                        <span class="label-xs">Confirm New Password</span>
                        <input type="password" name="confirmPassword" required placeholder="Repeat the new password">
                    </div>
                </div>

                <div class="pt-2">
                    <button type="submit" class="btn btn-blue shadow-lg shadow-blue-500/15">
                        <%= LockIcon("icon-sm") %> Confirm Update
                    </button>
                    <a href="Profile" class="block text-center mt-3 text-[9px] font-black text-slate-400 hover:text-slate-600 uppercase tracking-widest transition-colors">
                        Return to Profile
                    </a>
                </div>
            </form>
        </div>

        <div class="mt-8 text-center opacity-20 text-[9px] font-black uppercase tracking-[0.4em]">
            Security Handshake • v2.1.2
        </div>
    </div>
</main>

</body>
</html>