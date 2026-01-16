<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, bean.Holiday, java.time.format.DateTimeFormatter" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ include file="icon.jsp" %>

<%
    // ADMIN GUARD
    HttpSession ses = request.getSession(false);
    if (ses == null || ses.getAttribute("empid") == null || !"ADMIN".equalsIgnoreCase(String.valueOf(ses.getAttribute("role")))) {
        response.sendRedirect("login.jsp"); return;
    }

    // Data from Controller
    List<Holiday> holidays = (List<Holiday>) request.getAttribute("holidays");
    String error = request.getParameter("error");
    String msg = request.getParameter("msg");
    
    // Capture the ID of the just-added or edited record to trigger highlighting
    String highlightId = request.getParameter("id"); 

    DateTimeFormatter dtf = DateTimeFormatter.ofPattern("dd/MM/yyyy");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Holiday Calendar | Admin Access</title>
    
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <style>
        :root {
            --bg: #F1F5F9;
            --card: #ffffff;
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

        * { box-sizing: border-box; font-family: 'Inter', sans-serif !important; }
        body { background: var(--bg); color: var(--text); margin: 0; }
        
        .pageWrap { padding: 32px 40px; max-width: 1240px; margin: 0 auto; }

        .title { font-size: 26px; font-weight: 800; margin: 0; text-transform: uppercase; color: var(--text); }
        .sub-label { color: var(--blue-primary); font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.1em; margin-top: 4px; display: block; }

        .card { background: var(--card); border: 1px solid var(--border); border-radius: var(--radius); box-shadow: var(--shadow); overflow: hidden; margin-top: 24px; }
        .cardHead { padding: 20px 24px; border-bottom: 1px solid #f1f5f9; display: flex; justify-content: space-between; align-items: center; }
        .cardHead span { font-weight: 800; font-size: 15px; color: var(--text); text-transform: uppercase; }

        table { width: 100%; border-collapse: collapse; }
        th, td { border-bottom: 1px solid #f1f5f9; padding: 18px 24px; text-align: left; vertical-align: middle; }
        th { background: #f8fafc; font-size: 13px; text-transform: uppercase; color: var(--muted); font-weight: 900; letter-spacing: 0.05em; }

        /* ✅ ACTIVE ROW HIGHLIGHT - Visible for 3 seconds */
        .row-highlight { 
            background-color: #f1f5f9 !important; 
            border-left: 4px solid #2563eb; 
            transition: all 0.8s ease; 
        }
        
        .just-now-badge { 
            background: #2563eb; 
            color: white; 
            padding: 2px 8px; 
            border-radius: 6px; 
            font-size: 9px; 
            font-weight: 950; 
            margin-left: 12px; 
            vertical-align: middle; 
            display: inline-block; 
            letter-spacing: 0.05em;
            box-shadow: 0 4px 6px -1px rgba(37, 99, 235, 0.2);
            transition: opacity 0.5s ease; 
        }

        .btn-add { background: var(--blue-primary); color: white; padding: 10px 20px; border-radius: 10px; font-size: 12px; font-weight: 800; text-transform: uppercase; transition: 0.2s; display: flex; align-items: center; gap: 8px; border:none; cursor:pointer;}
        .btn-add:hover { background: #1d4ed8; transform: translateY(-1px); }

        .action-btn { width: 34px; height: 34px; border-radius: 10px; display: inline-flex; align-items: center; justify-content: center; transition: 0.2s; border: 1px solid var(--border); background: #fff; cursor: pointer; color: var(--muted); }
        .btn-edit:hover { background: var(--blue-light); border-color: var(--blue-primary); color: var(--blue-primary); }
        .btn-delete:hover { background: #fef2f2; border-color: var(--red); color: var(--red); }

        .pill { display: inline-block; padding: 4px 10px; border-radius: 8px; font-weight: 800; font-size: 13px; text-transform: uppercase; border: 1px solid transparent; }
        .pill-public { background: #eff6ff; color: var(--blue-primary); border-color: #dbeafe; }
        .pill-company { background: #ecfdf5; color: var(--green); border-color: #d1fae5; }
        .pill-state { background: #fef3c7; color: #d97706; border-color: #fde68a; }

        .modal-overlay { position:fixed; inset:0; background:rgba(15, 23, 42, 0.6); display:none; align-items:center; justify-content:center; z-index:9999; backdrop-filter:blur(4px); padding: 20px; }
        .modal-overlay.show { display:flex; }
        .modal-content { background:white; width: 450px; border-radius: 20px; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1); animation: slideUp 0.3s ease; overflow: hidden; }
        @keyframes slideUp { from{opacity:0; transform:translateY(20px);} to{opacity:1; transform:translateY(0);} }
        
        .modal-header { padding: 20px 24px; border-bottom: 1px solid #f1f5f9; display: flex; justify-content: space-between; align-items: center; background: #fcfcfd; }
        .modal-body { padding: 24px; }
        
        .form-group { margin-bottom: 18px; }
        .form-group label { font-size: 10px; font-weight: 800; color: var(--muted); text-transform: uppercase; display: block; margin-bottom: 6px; letter-spacing: 0.05em; }
        
        /* UPDATED: form-control to 45px height and 20px padding */
        .form-control { 
            width: 100%; 
            height: 45px !important; 
            padding: 0 20px !important; 
            border-radius: 12px; 
            border: 1px solid var(--border); 
            outline: none; 
            font-size: 14px; 
            font-weight: 600; 
            color: var(--text); 
            text-transform: uppercase; 
            transition: all 0.2s;
        }
        .form-control:focus { border-color: var(--blue-primary); box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.1); }

        .btn-submit { width: 100%; background: #1e293b; color: white; padding: 14px; border-radius: 12px; font-size: 12px; font-weight: 800; text-transform: uppercase; transition: 0.2s; margin-top: 10px; letter-spacing: 0.05em; border:none; cursor:pointer;}
        .btn-submit:hover { background: var(--blue-primary); transform: translateY(-1px); }

        .btn-confirm-yes { border:none; cursor:pointer; background: var(--red); color: white; padding: 12px 24px; border-radius: 10px; font-size: 12px; font-weight: 800; text-transform: uppercase; }
        .btn-confirm-no { border:none; cursor:pointer; background: #f1f5f9; color: var(--text); padding: 12px 24px; border-radius: 10px; font-size: 12px; font-weight: 800; text-transform: uppercase; }

        .alert-box { transition: opacity 0.5s ease; }
    </style>
</head>
<body class="flex">
    <jsp:include page="sidebar.jsp" />
    
    <main class="flex-1 ml-20 lg:ml-64 min-h-screen transition-all duration-300">
        <jsp:include page="topbar.jsp" />
        
        <div class="pageWrap">
            <div class="flex justify-between items-end mb-8">
                <div>
                    <h2 class="title">Holiday Calendar</h2>
                    <span class="sub-label">Manage Public Holidays and Events</span>
                </div>
                <button onclick="openModal('ADD')" class="btn-add shadow-sm">
                    <%= PlusIcon("w-4 h-4") %> Add Holiday
                </button>
            </div>

            <% if (error != null) { %>
                <div class="alert-box bg-red-50 border border-red-100 text-red-600 p-4 rounded-xl mb-6 font-bold text-sm flex items-center gap-3">
                    <%= AlertIcon("w-5 h-5") %> <%= error %>
                </div>
            <% } %>
            <% if (msg != null) { %>
                <div class="alert-box bg-emerald-50 border border-emerald-100 text-emerald-600 p-4 rounded-xl mb-6 font-bold text-sm flex items-center gap-3">
                    <%= CheckCircleIcon("w-5 h-5") %> <%= msg %>
                </div>
            <% } %>

            <div class="card">
                <div class="cardHead">
                    <span>System Holiday List</span>
                    <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                        Total Records: <%= (holidays != null ? holidays.size() : 0) %>
                    </div>
                </div>
                <div class="overflow-x-auto">
                    <table>
                        <thead>
                            <tr>
                                <th>Holiday Name</th>
                                <th>Category</th>
                                <th>Event Date</th>
                                <th style="text-align:right">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (holidays == null || holidays.isEmpty()) { %>
                                <tr><td colspan="4" class="py-24 text-center text-slate-300 font-bold uppercase text-xs italic tracking-widest">No holidays configured</td></tr>
                            <% } else { 
                                for (Holiday h : holidays) { 
                                    String typeClass = "pill-public";
                                    if("COMPANY".equalsIgnoreCase(h.getType())) typeClass = "pill-company";
                                    else if("STATE".equalsIgnoreCase(h.getType())) typeClass = "pill-state";

                                    String dateDisplay = (h.getDate() != null) ? h.getDate().format(dtf) : "-";
                                    String dateIso = (h.getDate() != null) ? h.getDate().toString() : "";
                                    
                                    boolean isHighlighted = String.valueOf(h.getId()).equals(highlightId);
                            %>
                                <tr id="holiday_row_<%= h.getId() %>" class="<%= isHighlighted ? "row-highlight" : "hover:bg-slate-50/50" %> transition-all">
                                    <td>
                                        <div class="font-bold text-slate-800 text-sm uppercase flex items-center">
                                            <%= h.getName() %>
                                            <% if (isHighlighted) { %><span class="just-now-badge">JUST NOW</span><% } %>
                                        </div>
                                    </td>
                                    <td><span class="pill <%= typeClass %>"><%= h.getType() %></span></td>
                                    <td>
                                        <div class="flex items-center gap-2 text-xs font-semibold text-slate-600">
                                            <%= CalendarIcon("w-3.5 h-3.5 text-blue-500") %> <%= dateDisplay %>
                                        </div>
                                    </td>
                                    <td style="text-align:right">
                                        <div class="flex justify-end gap-2">
                                            <button onclick="openModal('UPDATE', '<%= h.getId() %>', '<%= h.getName() %>', '<%= dateIso %>', '<%= h.getType() %>')" class="action-btn btn-edit" title="Edit">
                                                <%= EditIcon("w-3.5 h-3.5") %>
                                            </button>
                                            <form action="ManageHoliday" method="POST" id="formDelete_<%= h.getId() %>" style="display:inline">
                                                <input type="hidden" name="action" value="DELETE">
                                                <input type="hidden" name="holidayId" value="<%= h.getId() %>">
                                                <button type="button" onclick="triggerConfirm('DELETE', 'formDelete_<%= h.getId() %>')" class="action-btn btn-delete" title="Delete">
                                                    <%= TrashIcon("w-3.5 h-3.5") %>
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
    </main>

    <div class="modal-overlay" id="holidayModal">
        <div class="modal-content">
            <form action="ManageHoliday" method="POST" id="holidayForm">
                <input type="hidden" name="action" id="modalAction" value="ADD">
                <input type="hidden" name="holidayId" id="modalId">
                
                <div class="modal-header">
                    <div><h3 class="text-base font-extrabold text-slate-900 uppercase" id="modalTitle">Register Holiday</h3></div>
                    <button type="button" onclick="closeModal()" class="text-slate-400 hover:text-red-500 transition-colors border-none bg-transparent cursor-pointer"><%= XCircleIcon("w-6 h-6") %></button>
                </div>
                <div class="modal-body">
                    <div class="form-group">
                        <label>Holiday Description</label>
                        <input type="text" name="holidayName" id="modalName" class="form-control" required placeholder="e.g. LUNAR NEW YEAR">
                    </div>
                    <div class="form-group">
                        <label>Date</label>
                        <input type="date" name="holidayDate" id="modalDate" class="form-control" required>
                    </div>
                    <div class="form-group">
                        <label>Holiday Category</label>
                        <select name="holidayType" id="modalType" class="form-control" required>
                            <option value="PUBLIC">PUBLIC</option>
                            <option value="STATE">STATE</option>
                            <option value="COMPANY">COMPANY</option>
                        </select>
                    </div>
                    <button type="button" onclick="triggerConfirm(document.getElementById('modalAction').value, 'holidayForm')" class="btn-submit shadow-lg shadow-slate-200">Confirm Changes</button>
                </div>
            </form>
        </div>
    </div>

    <div class="modal-overlay" id="confirmModal">
        <div class="modal-content" style="width: 400px; text-align: center; padding: 32px;">
            <div class="mb-4 flex justify-center"><div id="confirmIconContainer" class="w-16 h-16 rounded-full flex items-center justify-center"></div></div>
            <h3 class="text-xl font-extrabold text-slate-900 uppercase mb-2" id="confirmTitle">Confirm Action</h3>
            <p class="text-sm text-slate-500 font-medium mb-8" id="confirmMsg">Are you sure you want to proceed?</p>
            <div class="flex gap-3">
                <button type="button" onclick="closeConfirm()" class="btn-confirm-no flex-1">Cancel</button>
                <button type="button" id="btnConfirmProceed" class="btn-confirm-yes flex-1 shadow-lg shadow-red-100">Proceed</button>
            </div>
        </div>
    </div>

    <script>
        let currentTargetFormId = null;

        window.addEventListener('DOMContentLoaded', () => {
            // 1. Auto-dismiss alerts (3 seconds)
            const alerts = document.querySelectorAll('.alert-box');
            alerts.forEach(alert => {
                setTimeout(() => {
                    alert.style.opacity = '0';
                    setTimeout(() => alert.style.display = 'none', 500);
                }, 3000);
            });

            // 2. Highlighting & Auto-Scroll Logic
            const highlightId = "<%= highlightId != null ? highlightId : "" %>";
            if (highlightId) {
                const row = document.getElementById('holiday_row_' + highlightId);
                if (row) {
                    // Smooth scroll to the updated row
                    setTimeout(() => {
                        row.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    }, 400);

                    // Revert background color and badge after exactly 3 seconds
                    setTimeout(() => {
                        row.classList.remove('row-highlight');
                        const badge = row.querySelector('.just-now-badge');
                        if (badge) {
                            badge.style.opacity = '0';
                            setTimeout(() => badge.style.display = 'none', 500);
                        }
                    }, 3000);
                }
                
                // Clean the URL parameters without reloading
                setTimeout(() => {
                    const newUrl = window.location.protocol + "//" + window.location.host + window.location.pathname;
                    window.history.pushState({path:newUrl}, '', newUrl);
                }, 4000);
            }
        });

        function triggerConfirm(action, formId) {
            currentTargetFormId = formId;
            const titleEl = document.getElementById('confirmTitle');
            const msgEl = document.getElementById('confirmMsg');
            const iconContainer = document.getElementById('confirmIconContainer');
            const btnProceed = document.getElementById('btnConfirmProceed');

            // Reset classes
            btnProceed.className = "btn-confirm-yes flex-1 shadow-lg";
            iconContainer.className = "w-16 h-16 rounded-full flex items-center justify-center";

            if (action === 'ADD') {
                titleEl.textContent = "Register Holiday";
                msgEl.textContent = "Confirm registration of this new holiday?";
                iconContainer.classList.add("bg-blue-50", "text-blue-600");
                iconContainer.innerHTML = `<%= PlusIcon("w-8 h-8") %>`;
                btnProceed.classList.add("bg-blue-600", "shadow-blue-100");
            } else if (action === 'UPDATE') {
                titleEl.textContent = "Update Record";
                msgEl.textContent = "Save changes for this holiday record?";
                iconContainer.classList.add("bg-amber-50", "text-amber-600");
                iconContainer.innerHTML = `<%= EditIcon("w-8 h-8") %>`;
                btnProceed.classList.add("bg-amber-600", "shadow-amber-100");
            } else if (action === 'DELETE') {
                titleEl.textContent = "Delete Forever";
                msgEl.textContent = "This action is permanent. Delete this holiday?";
                iconContainer.classList.add("bg-red-50", "text-red-600");
                iconContainer.innerHTML = `<%= TrashIcon("w-8 h-8") %>`;
                btnProceed.classList.add("bg-red-600", "shadow-red-100");
            }

            btnProceed.onclick = () => document.getElementById(currentTargetFormId).submit();
            document.getElementById('confirmModal').classList.add('show');
        }

        function closeConfirm() { document.getElementById('confirmModal').classList.remove('show'); }

        function openModal(action, id = '', name = '', date = '', type = 'PUBLIC') {
            document.getElementById('modalAction').value = action;
            document.getElementById('modalTitle').textContent = action === 'ADD' ? 'Register Holiday' : 'Update Holiday';
            document.getElementById('modalId').value = id;
            document.getElementById('modalName').value = name.toUpperCase();
            document.getElementById('modalDate').value = date;
            document.getElementById('modalType').value = type;
            document.getElementById('holidayModal').classList.add('show');
        }

        function closeModal() { document.getElementById('holidayModal').classList.remove('show'); }

        window.onclick = (e) => { 
            if (e.target.id === 'holidayModal') closeModal(); 
            if (e.target.id === 'confirmModal') closeConfirm(); 
        }

        document.getElementById('modalName').addEventListener('input', function() {
            this.value = this.value.toUpperCase();
        });
    </script>
</body>
</html>