<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>

<%
    // Admin guard
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
    <title>Manage Holidays</title>
    
    <script src="https://cdn.tailwindcss.com"></script>

    <style>
        :root {
            --bg: #f4f6fb;
            --card: #ffffff;
            --border: #e5e7eb;
            --text: #0f172a;
            --muted: #64748b;
            --primary: #2563eb;
            --shadow: 0 10px 25px rgba(0,0,0,0.06);
            --radius: 16px;
        }

        /* Paksa Arial secara menyeluruh */
        * { 
            box-sizing: border-box; 
            font-family: Arial, sans-serif !important; 
        }

        body {
            margin: 0;
            background: var(--bg);
            color: var(--text);
        }

        /* Layout Transition */
        main { transition: all 0.3s ease; }
        .content { padding: 24px; }
        .container { max-width: 1100px; margin: 0 auto; }

        /* Page Header - Consistent with Dashboard */
        .pageHeader { margin-bottom: 16px; }
        .pageTitle { margin: 0; font-size: 22px; font-weight: 800; }
        .pageSub { margin-top: 6px; font-size: 13px; color: var(--muted); }

        .grid {
            display: grid;
            grid-template-columns: 380px 1fr;
            gap: 20px;
            align-items: start;
        }
        @media (max-width: 980px) {
            .grid { grid-template-columns: 1fr; }
        }

        /* Card Styles */
        .card {
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            overflow: hidden;
        }
        .cardPad { padding: 18px; }
        .cardHead {
            padding: 16px 18px;
            border-bottom: 1px solid #eef2f7;
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-weight: 900;
        }
        .cardHead .left {
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 18px;
        }

        /* Form Controls */
        .field { display: flex; flex-direction: column; gap: 7px; margin-bottom: 14px; }
        label { font-weight: 800; font-size: 12px; color: #334155; text-transform: uppercase; }
        input, select {
            padding: 10px 12px;
            border-radius: 12px;
            border: 1px solid #cbd5e1;
            background: #fff;
            font-size: 13px;
            outline: none;
        }
        input:focus, select:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.18);
        }

        .btnPrimary {
            width: 100%;
            background: #1f2937;
            color: #fff;
            border: none;
            border-radius: 12px;
            padding: 12px 14px;
            font-weight: 900;
            font-size: 13px;
            cursor: pointer;
            text-transform: uppercase;
        }
        .btnPrimary:hover { filter: brightness(1.1); }

        .btnGhost {
            background: #fff;
            border: 1px solid var(--border);
            color: var(--text);
            border-radius: 12px;
            padding: 8px 12px;
            font-weight: 900;
            font-size: 11px;
            cursor: pointer;
        }

        /* Table Styles */
        table { width: 100%; border-collapse: collapse; }
        thead th {
            text-align: left;
            font-size: 12px;
            font-weight: 900;
            color: #334155;
            padding: 14px 18px;
            border-bottom: 1px solid #eef2f7;
            background: #f8fafc;
            text-transform: uppercase;
        }
        tbody td {
            padding: 14px 18px;
            border-bottom: 1px solid #f0f3f8;
            color: var(--text);
            font-size: 14px;
            vertical-align: middle;
        }
        tbody tr:hover { background: #f8fafc; }

        .pill {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 8px;
            font-weight: 900;
            font-size: 11px;
            text-transform: uppercase;
        }
        .pill.public { background: #fee2e2; color: #b91c1c; }
        .pill.state { background: #ffedd5; color: #c2410c; }
        .pill.company { background: #dbeafe; color: #1d4ed8; }

        .actions { display: flex; justify-content: flex-end; gap: 8px; }
        .iconBtn {
            width: 32px; height: 32px;
            border-radius: 10px;
            border: 1px solid #e5e7eb;
            background: #fff;
            cursor: pointer;
            display: flex; align-items: center; justify-content: center;
            color: #64748b;
        }
        .iconBtn:hover { background: #f8fafc; color: var(--primary); }
        .iconBtn.danger:hover { background: #fee2e2; border-color: #fecaca; color: #dc2626; }

        /* Mesej Alert */
        .msg, .err {
            padding: 12px 16px;
            border-radius: 12px;
            font-size: 13px;
            margin-bottom: 16px;
            font-weight: 700;
            border: 1px solid;
        }
        .msg { background: #ecfeff; border-color: #a5f3fc; color: #0e7490; }
        .err { background: #fee2e2; border-color: #fecaca; color: #b91c1c; }

        .editMode { border: 2px solid var(--primary) !important; box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.08); }
        .ico { width: 16px; height: 16px; display: block; }
    </style>
</head>

<body>
    <jsp:include page="sidebar.jsp" />

    <main class="ml-20 lg:ml-64 min-h-screen transition-all duration-300">
        
        <jsp:include page="topbar.jsp" />

        <div class="content">
            <div class="container">

                <div class="pageHeader">
                    <div>
                        <h2 class="pageTitle">Manage Holidays</h2>
                        <p class="pageSub">Manage list of Holiday in Malaysia.</p>
                    </div>
                </div>

                <c:if test="${not empty param.msg}">
                    <div class="msg"><b>${param.msg}</b></div>
                </c:if>
                <c:if test="${not empty param.error}">
                    <div class="err"><b>${param.error}</b></div>
                </c:if>

                <div class="grid">
                    <div id="formCard" class="card">
                        <div class="cardHead">
                            <div class="left">
                                <svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <rect x="3" y="4" width="18" height="18" rx="2"></rect>
                                    <path d="M16 2v4M8 2v4M3 10h18"></path>
                                </svg>
                                <span id="formTitle">Add New Holiday</span>
                            </div>
                            <button id="cancelEditBtn" type="button" class="btnGhost" style="display:none;" onclick="resetForm()">Cancel</button>
                        </div>

                        <div class="cardPad">
                            <form id="holidayForm" action="AddHolidayServlet" method="post">
                                <input type="hidden" name="holidayId" id="holidayId" value="">

                                <div class="field">
                                    <label>Holiday Name</label>
                                    <input type="text" name="holidayName" id="holidayName" placeholder="e.g. Founder's Day" required>
                                </div>

                                <div class="field">
                                    <label>Date</label>
                                    <input type="date" name="holidayDate" id="holidayDate" required>
                                </div>

                                <div class="field">
                                    <label>Type</label>
                                    <select name="holidayType" id="holidayType" required>
                                        <option value="PUBLIC">Public Holiday</option>
                                        <option value="STATE">State</option>
                                        <option value="COMPANY">Company</option>
                                    </select>
                                </div>

                                <button id="submitBtn" class="btnPrimary mt-2" type="submit">Add Holiday</button>
                            </form>
                        </div>
                    </div>

                    <div class="card">
                        <div class="p-4 bg-slate-50 border-b border-slate-100 flex justify-between items-center">
                            <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Holiday Calendar</span>
                            <span class="text-[11px] font-bold text-slate-500">${fn:length(holidays)} Records</span>
                        </div>

                        <div class="overflow-x-auto">
                            <table>
                                <thead>
                                    <tr>
                                        <th style="width:160px;">Date</th>
                                        <th>Holiday Name</th>
                                        <th style="width:130px;">Type</th>
                                        <th style="width:120px; text-align:right;">Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        List<Map<String,Object>> holidays = (List<Map<String,Object>>) request.getAttribute("holidays");
                                        if (holidays == null || holidays.isEmpty()) {
                                    %>
                                        <tr>
                                            <td colspan="4" style="text-align:center; padding:30px; color:#64748b;">No holidays found. Add one to get started.</td>
                                        </tr>
                                    <%
                                        } else {
                                            for (Map<String,Object> h : holidays) {
                                                String id = (h.get("id") == null) ? "" : String.valueOf(h.get("id"));
                                                String name = (h.get("name") == null) ? "" : String.valueOf(h.get("name"));
                                                String type = (h.get("type") == null) ? "" : String.valueOf(h.get("type"));
                                                String dateDisplay = (h.get("dateDisplay") == null) ? "-" : String.valueOf(h.get("dateDisplay"));
                                                String dateIso = (h.get("dateIso") == null) ? "" : String.valueOf(h.get("dateIso"));

                                                String pillClass = "company";
                                                if ("Public".equalsIgnoreCase(type)) pillClass = "public";
                                                else if ("State".equalsIgnoreCase(type)) pillClass = "state";
                                    %>
                                        <tr>
                                            <td style="font-weight: bold;"><%= dateDisplay %></td>
                                            <td style="font-weight: 500;"><%= name %></td>
                                            <td><span class="pill <%= pillClass %>"><%= type %></span></td>
                                            <td style="text-align:right;">
                                                <div class="actions">
                                                    <button type="button" class="iconBtn" title="Edit" onclick="editHoliday('<%= escapeJs(id) %>','<%= escapeJs(name) %>','<%= escapeJs(dateIso) %>','<%= escapeJs(type) %>')">
                                                        <svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M12 20h9"></path><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z"></path></svg>
                                                    </button>
                                                    <form action="DeleteHolidayServlet" method="post" style="margin:0;" onsubmit="return confirm('Delete this holiday?');">
                                                        <input type="hidden" name="holidayId" value="<%= id %>">
                                                        <button type="submit" class="iconBtn danger" title="Delete">
                                                            <svg class="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M3 6h18m-2 0v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6m3 0V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path></svg>
                                                        </button>
                                                    </form>
                                                </div>
                                            </td>
                                        </tr>
                                    <% } } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <div class="mt-12 text-center opacity-30 text-[10px] font-bold uppercase tracking-widest">
                    v1.2.1 © 2024 Klinik Dr Mohamad
                </div>

            </div>
        </div>
    </main>

    <%!
      public static String escapeJs(String s){
        if (s == null) return "";
        return s.replace("\\","\\\\").replace("'","\\'").replace("\"","\\\"");
      }
    %>

    <script>
      function editHoliday(id, name, dateIso, type){
        document.getElementById("holidayId").value = id || "";
        document.getElementById("holidayName").value = name || "";
        document.getElementById("holidayDate").value = dateIso || "";

        if (type && type.toUpperCase() === "PUBLIC") type = "Public";
        if (type && type.toUpperCase() === "STATE") type = "State";
        if (type && type.toUpperCase() === "COMPANY") type = "Company";

        document.getElementById("holidayType").value = type || "Public";

        document.getElementById("holidayForm").action = "UpdateHolidayServlet";
        document.getElementById("formTitle").textContent = "Edit Holiday";
        document.getElementById("submitBtn").textContent = "Update Holiday";
        document.getElementById("cancelEditBtn").style.display = "inline-block";
        document.getElementById("formCard").classList.add("editMode");

        window.scrollTo({ top: 0, behavior: "smooth" });
      }

      function resetForm(){
        document.getElementById("holidayForm").reset();
        document.getElementById("holidayId").value = "";
        document.getElementById("holidayForm").action = "AddHolidayServlet";
        document.getElementById("formTitle").textContent = "Add New Holiday";
        document.getElementById("submitBtn").textContent = "Add Holiday";
        document.getElementById("cancelEditBtn").style.display = "none";
        document.getElementById("formCard").classList.remove("editMode");
      }
    </script>
</body>
</html>