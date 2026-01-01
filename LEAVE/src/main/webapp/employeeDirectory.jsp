<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
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
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Employee Directory</title>

    <script src="https://cdn.tailwindcss.com"></script>

    <style>
        :root{
            --bg:#f4f6fb;
            --card:#ffffff;
            --border:#e5e7eb;
            --text:#0f172a;
            --muted:#64748b;
            --primary:#2563eb;
            --shadow:0 10px 25px rgba(0,0,0,0.06);
            --radius:16px;
        }

        *{box-sizing:border-box}
        body{margin:0;font-family:Arial, sans-serif;background:var(--bg);color:var(--text);}
        
        /* Transition content bila sidebar resize */
        main { transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1); }

        .content { padding: 24px; }
        .container { max-width: 1100px; margin: 0 auto; }
        
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

        /* Card & Table Styles */
        .card { background: var(--card); border: 1px solid var(--border); border-radius: var(--radius); box-shadow: var(--shadow); overflow: hidden; }
        .cardHead { padding: 16px 18px; border-bottom: 1px solid #eef2f7; display: flex; justify-content: space-between; align-items: center; font-weight: 900; }
        
        table { width: 100%; border-collapse: collapse; }
        th, td { border-bottom: 1px solid #eef2f7; padding: 14px; text-align: left; vertical-align: top; }
        th { background: #f8fafc; font-size: 12px; text-transform: uppercase; color: #334155; }
        
        .small { font-size: 12px; color: #64748b; }
        .badge { display: inline-block; padding: 2px 8px; border-radius: 6px; font-size: 10px; font-weight: 800; text-transform: uppercase; }
        .badge-admin { background: #eff6ff; color: #2563eb; border: 1px solid #dbeafe; }
        .badge-emp { background: #f8fafc; color: #64748b; border: 1px solid #e2e8f0; }

        .btnDel {
            border: 1px solid #fecaca; background: #fff; color: #dc2626;
            font-weight: 800; font-size: 11px; padding: 6px 12px; border-radius: 10px;
            cursor: pointer; transition: all 0.2s; text-transform: uppercase;
        }
        .btnDel:hover { background: #fef2f2; }

        .msg, .err { padding: 10px 12px; border-radius: 12px; font-size: 13px; margin-bottom: 12px; font-weight: 800; }
        .msg { background: #ecfeff; border: 1px solid #a5f3fc; color: #0e7490; }
        .err { background: #fee2e2; border: 1px solid #fecaca; color: #b91c1c; }
    </style>
</head>

<body>
    <jsp:include page="sidebar.jsp" />

    <main class="ml-20 lg:ml-64 min-h-screen transition-all duration-300">
        
        <jsp:include page="topbar.jsp" />

        <div class="content">
            <div class="container">

                <div class="pageHeader">
                    <h2 class="pageTitle">Employee Directory</h2>
                    <p class="pageSub">View and manage registered employees in the system.</p>
                </div>

                <div class="tabs">
                    <a class="tab" href="RegisterEmployeeServlet">Register Employee</a>
                    <a class="tab active" href="EmployeeDirectoryServlet">Employee Directory</a>
                </div>

                <c:if test="${not empty param.msg}">
                    <div class="msg">${param.msg}</div>
                </c:if>
                <c:if test="${not empty param.error}">
                    <div class="err">${param.error}</div>
                </c:if>

                <div class="card">
                    <div class="cardHead">
                        <span>Staff Directory</span>
                        <span class="text-[10px] text-slate-400 font-bold uppercase tracking-widest">Administrator Access</span>
                    </div>
                    
                    <div style="overflow-x:auto;">
                        <table>
                            <thead>
                                <tr>
                                    <th>Name / Role</th>
                                    <th>Contact Information</th>
                                    <th>Hire Date</th>
                                    <th style="width:140px; text-align: center;">Action</th>
                                </tr>
                            </thead>
                            <tbody>
                            <%
                                List<Map<String,Object>> users = (List<Map<String,Object>>) request.getAttribute("users");

                                if (users == null || users.isEmpty()) {
                            %>
                                <tr>
                                    <td colspan="4" style="text-align:center; padding:30px; color: var(--muted);">
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

                                        boolean isAdmin = "ADMIN".equalsIgnoreCase(role);
                            %>
                                <tr>
                                    <td>
                                        <div class="font-bold text-slate-900"><%= fullname %></div>
                                        <div class="mt-1">
                                            <span class="badge <%= isAdmin ? "badge-admin" : "badge-emp" %>">
                                                <%= role %>
                                            </span>
                                        </div>
                                        <div class="small mt-1 uppercase font-bold tracking-tighter">ID: <%= empid %></div>
                                    </td>
                                    <td>
                                        <div class="text-sm font-medium"><%= email %></div>
                                        <div class="small mt-1"><%= (phone == null || phone.isBlank()) ? "No Phone No." : phone %></div>
                                    </td>
                                    <td class="text-sm font-medium text-slate-600">
                                        <%= hiredate %>
                                    </td>
                                    <td style="text-align: center;">
                                        <% if (!isAdmin) { %>
                                            <form action="DeleteEmployeeServlet" method="post"
                                                  onsubmit="return confirm('Are you sure you want to delete this employee? This action cannot be undone.');">
                                                <input type="hidden" name="empid" value="<%= empid %>">
                                                <button class="btnDel" type="submit">Delete Staff</button>
                                            </form>
                                        <% } else { %>
                                            <span class="text-[10px] font-bold text-slate-300 uppercase italic">System Protected</span>
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
                </div><div class="mt-8 text-center opacity-30 text-[10px] font-bold uppercase tracking-widest">
                    v1.2.1 © 2024 Klinik Dr Mohamad
                </div>

            </div></div></main>
</body>
</html>