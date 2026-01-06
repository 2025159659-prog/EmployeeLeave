<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

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

  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  <script src="https://cdn.tailwindcss.com"></script>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">

  <style>
    :root {
      --bg: #f8fafc;
      --card: #fff;
      --border: #e2e8f0;
      --text: #1e293b;
      --muted: #64748b;
      --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
      --radius: 16px;
      --primary: #2563eb;
      --red: #ef4444;
      --orange: #f97316;
      --blue: #3b82f6;
      --teal: #14b8a6;
      --purple: #a855f7;
      --indigo: #6366f1;
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
      max-width: 1200px; 
      margin: 0 auto;
    }

    /* Consistent Header Styling */
    h2.title { 
      font-size: 26px; 
      font-weight: 800; 
      margin: 0; 
      color: var(--text); 
      text-transform: uppercase; 
      letter-spacing: -0.025em;
    }
    
    .sub-label { 
      color: var(--indigo); 
      font-size: 11px; 
      font-weight: 800; 
      text-transform: uppercase; 
      letter-spacing: 0.1em;
      margin-top: 4px;
      display: block;
    }

    /* Tabs Navigation */
    .tabs { display: flex; gap: 12px; margin: 24px 0; }
    .tab {
      text-decoration: none; font-weight: 800; font-size: 12px; padding: 10px 16px;
      border-radius: 12px; border: 1px solid var(--border); background: #fff; color: var(--muted);
      text-transform: uppercase; transition: 0.2s;
    }
    .tab.active { 
      border-color: var(--indigo); 
      background: #f5f3ff; 
      color: var(--indigo); 
    }
    .tab:hover:not(.active) {
      border-color: var(--text);
      color: var(--text);
    }

    /* Card & Table Styles */
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
    
    .cardHead span:first-child { font-weight: 800; font-size: 15px; color: var(--text); text-transform: uppercase; }

    table { width: 100%; border-collapse: collapse; }
    th, td { border-bottom: 1px solid #f1f5f9; padding: 16px 24px; text-align: left; }
    th { 
      background: #f8fafc; 
      font-size: 11px; 
      text-transform: uppercase; 
      color: var(--muted); 
      font-weight: 800;
      letter-spacing: 0.05em;
    }
    
    .badge { 
      display: inline-flex; 
      padding: 4px 10px; 
      border-radius: 8px; 
      font-size: 10px; 
      font-weight: 800; 
      text-transform: uppercase; 
      letter-spacing: 0.02em;
    }
    .badge-admin { background: #eff6ff; color: var(--blue); border: 1px solid #dbeafe; }
    .badge-emp { background: #f8fafc; color: var(--muted); border: 1px solid #e2e8f0; }

    /* Updated Delete Button Style */
    .btnDel {
      border: 1px solid #fee2e2; 
      background: #fff; 
      color: var(--red);
      font-weight: 800; 
      font-size: 11px; 
      padding: 8px 14px; 
      border-radius: 10px;
      cursor: pointer; 
      transition: all 0.2s; 
      text-transform: uppercase;
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .btnDel:hover { 
      background: var(--red); 
      color: #fff; 
      border-color: var(--red);
      transform: translateY(-1px);
      box-shadow: 0 4px 6px -1px rgba(239, 68, 68, 0.2);
    }

    .msg, .err { padding: 14px 18px; border-radius: 12px; font-size: 13px; margin-bottom: 20px; font-weight: 700; display: flex; align-items: center; gap: 10px; }
    .msg { background: #f0fdfa; border: 1px solid #ccfbf1; color: #0f766e; }
    .err { background: #fef2f2; border: 1px solid #fee2e2; color: #b91c1c; }

    /* Custom Scrollbar */
    .pageWrap::-webkit-scrollbar { width: 6px; }
    .pageWrap::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }
  </style>
</head>

<body class="flex">
    <jsp:include page="sidebar.jsp" />

    <main class="flex-1 ml-20 lg:ml-64 min-h-screen transition-all duration-300">
        <jsp:include page="topbar.jsp" />

        <div class="pageWrap">
            <!-- Header Section -->
            <div class="mb-8">
                <h2 class="title">EMPLOYEE DIRECTORY</h2>
                <span class="sub-label">View and manage registered employees in the system.</span>
            </div>

            <!-- Navigation Tabs -->
            <div class="tabs">
                <a class="tab" href="RegisterEmployeeServlet">
                    <i class="fa fa-user-plus mr-2"></i>Register
                </a>
                <a class="tab active" href="EmployeeDirectoryServlet">
                    <i class="fa fa-list mr-2"></i>Directory
                </a>
            </div>

            <!-- Notifications -->
            <c:if test="${not empty param.msg}">
                <div class="msg shadow-sm"><i class="fa fa-check-circle"></i> ${param.msg}</div>
            </c:if>
            <c:if test="${not empty param.error}">
                <div class="err shadow-sm"><i class="fa fa-exclamation-triangle"></i> ${param.error}</div>
            </c:if>

            <!-- Table Card -->
            <div class="card">
                <div class="cardHead">
                    <span>Active Personnel</span>
                    <span class="text-[10px] text-slate-400 font-bold uppercase tracking-widest">Administrator Access Only</span>
                </div>
                
                <div style="overflow-x:auto;">
                    <table>
                        <thead>
                            <tr>
                                <th>Name / Designation</th>
                                <th>Contact Details</th>
                                <th>Employment Date</th>
                                <th style="width:160px; text-align: center;">Management</th>
                            </tr>
                        </thead>
                        <tbody>
                        <%
                            List<Map<String,Object>> users = (List<Map<String,Object>>) request.getAttribute("users");
                            SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");

                            if (users == null || users.isEmpty()) {
                        %>
                            <tr>
                                <td colspan="4" style="text-align:center; padding:48px; color: var(--muted);">
                                    <i class="fa fa-folder-open fa-2x mb-3 block opacity-20"></i>
                                    No employees found in the directory.
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
                                    Object hiredate = u.get("hiredate");
                                    
                                    // Formatting date to DD/MM/YYYY
                                    String formattedDate = (hiredate != null) ? sdf.format(hiredate) : "---";

                                    boolean isAdmin = "ADMIN".equalsIgnoreCase(role);
                        %>
                            <tr class="hover:bg-slate-50 transition-colors">
                                <td>
                                    <div class="font-bold text-slate-800"><%= fullname %></div>
                                    <div class="mt-1.5 flex items-center gap-2">
                                        <span class="badge <%= isAdmin ? "badge-admin" : "badge-emp" %>">
                                            <%= role %>
                                        </span>
                                        <span class="text-[10px] font-bold text-slate-400 uppercase tracking-tighter">ID: <%= empid %></span>
                                    </div>
                                </td>
                                <td>
                                    <div class="text-[13px] font-semibold text-slate-700"><%= email %></div>
                                    <div class="text-[11px] text-slate-400 mt-1 font-medium">
                                        <i class="fa fa-phone mr-1 opacity-50"></i>
                                        <%= (phone == null || phone.isBlank()) ? "Not provided" : phone %>
                                    </div>
                                </td>
                                <td class="text-[13px] font-bold text-slate-600">
                                    <%= formattedDate %>
                                </td>
                                <td style="text-align: center;">
                                    <% if (!isAdmin) { %>
                                        <form action="DeleteEmployeeServlet" method="post" class="inline-block"
                                              onsubmit="return confirm('WARNING: Are you sure you want to delete this employee? This action cannot be undone.');">
                                            <input type="hidden" name="empid" value="<%= empid %>">
                                            <button class="btnDel" type="submit">
                                                <i class="fa fa-trash-can"></i> Delete Staff
                                            </button>
                                        </form>
                                    <% } else { %>
                                        <span class="text-[10px] font-bold text-slate-300 uppercase italic tracking-widest">
                                            <i class="fa fa-shield-halved mr-1"></i>Protected
                                        </span>
                                    <% } %>
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
    </main>
</body>
</html>