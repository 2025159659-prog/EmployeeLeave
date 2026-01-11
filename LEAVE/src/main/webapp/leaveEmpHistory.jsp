<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.time.*" %>
<%@ page import="java.time.format.TextStyle" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="bean.LeaveRecord" %> 
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ include file="icon.jsp" %>

<%
    // ADMIN GUARD
    HttpSession ses = request.getSession(false);
    if (ses == null || ses.getAttribute("empid") == null || !"ADMIN".equalsIgnoreCase(String.valueOf(ses.getAttribute("role")))) {
        response.sendRedirect("login.jsp"); return;
    }

    // Correctly cast to List of LeaveRecord (MVC Pattern)
    List<LeaveRecord> history = (List<LeaveRecord>) request.getAttribute("history");
    List<String> years = (List<String>) request.getAttribute("years");
    
    String currentStatus = request.getParameter("status") != null ? request.getParameter("status") : "ALL";
    String currentYear = request.getParameter("year") != null ? request.getParameter("year") : "";
    String currentMonth = request.getParameter("month") != null ? request.getParameter("month") : "";

    Calendar cal = Calendar.getInstance();
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Leave History | Admin Access</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <style>
        :root {
            --bg: #f8fafc;
            --card: #fff;
            --border: #cbd5e1;
            --text: #1e293b;
            --muted: #64748b;
            --blue-primary: #2563eb;
            --blue-light: #eff6ff;
            --radius: 16px;
            --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
        }

        * { box-sizing: border-box; font-family: 'Inter', sans-serif !important; }
        body { background: var(--bg); color: var(--text); margin: 0; }
        
        .pageWrap { padding: 32px 40px; max-width: 1240px; margin: 0 auto; }

        .title { font-size: 26px; font-weight: 800; margin: 0; text-transform: uppercase; color: var(--text); }
        .sub-label { color: var(--blue-primary); font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.1em; margin-top: 4px; display: block; }

        /* Filter Toolbar */
        .toolbar { background: #fff; border: 1px solid var(--border); border-radius: 12px; padding: 12px 20px; display: flex; align-items: center; gap: 16px; margin-bottom: 24px; box-shadow: var(--shadow); }
        .filter-group { display: flex; flex-direction: column; }
        .filter-group label { font-size: 9px; font-weight: 800; color: var(--muted); text-transform: uppercase; margin-bottom: 2px; }
        .filter-group select { border: none; background: transparent; font-size: 13px; font-weight: 700; color: var(--text); outline: none; cursor: pointer; padding: 0; }

        /* Card Pattern */
        .card { background: var(--card); border: 1px solid var(--border); border-radius: var(--radius); box-shadow: var(--shadow); overflow: hidden; }
        .cardHead { padding: 20px 24px; border-bottom: 1px solid #f1f5f9; display: flex; justify-content: space-between; align-items: center; }
        .cardHead span { font-weight: 800; font-size: 15px; color: var(--text); text-transform: uppercase; }

        /* Table Design */
        table { width: 100%; border-collapse: collapse; }
        th, td { border-bottom: 1px solid #f1f5f9; padding: 18px 24px; text-align: left; vertical-align: middle; }
        th { background: #f8fafc; font-size: 11px; text-transform: uppercase; color: var(--muted); font-weight: 800; letter-spacing: 0.05em; }

        /* Badges */
        .badge { padding: 4px 10px; border-radius: 8px; font-size: 10px; font-weight: 800; text-transform: uppercase; display: inline-flex; align-items: center; gap: 6px; }
        .status-pending { background: #fffbeb; color: #b45309; border: 1px solid #fde68a; } 
        .status-approved { background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; } 
        .status-rejected { background: #fef2f2; color: #ef4444; border: 1px solid #fecaca; } 
        .status-cancelled { background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0; } 

        /* ✅ Standardized Modal Size */
        .modal-overlay { position:fixed; inset:0; background:rgba(15,23,42,0.6); display:none; align-items:center; justify-content:center; z-index:9999; backdrop-filter:blur(4px); padding: 20px; }
        .modal-overlay.show { display:flex; }
        
        .modal-content { 
            background:white; 
            width: 850px; 
            height: 650px; 
            max-width: 95vw;
            max-height: 90vh;
            border-radius: 20px; 
            box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1); 
            display: flex;
            flex-direction: column;
            overflow: hidden;
            animation: slideUp 0.3s ease; 
        }

        @keyframes slideUp { from{opacity:0; transform:translateY(20px);} to{opacity:1; transform:translateY(0);} }
        
        .modal-header { padding: 24px 32px; border-bottom: 1px solid #f1f5f9; display: flex; justify-content: space-between; align-items: center; background: #fcfcfd; flex-shrink: 0; }
        .modal-body { padding: 32px 40px; overflow-y: auto; flex: 1; }
        
        .info-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 24px; margin-bottom: 24px; border-bottom: 1px solid #f1f5f9; padding-bottom: 16px; }
        .info-grid:last-of-type { border-bottom: none; }
        .info-item { display: flex; flex-direction: column; }
        .info-label { font-size: 10px; font-weight: 800; color: var(--muted); text-transform: uppercase; margin-bottom: 4px; letter-spacing: 0.05em; }
        .info-value { font-size: 14px; font-weight: 700; color: var(--text); }

        .btn-close { width: 36px; height: 36px; border-radius: 10px; border: 1px solid var(--border); background: #fff; cursor: pointer; display: flex; align-items: center; justify-content: center; color: var(--muted); transition: 0.2s; }
        .btn-close:hover { background: #fef2f2; color: #ef4444; border-color: #fecaca; }

        .btn-apply { background: var(--blue-primary); color: white; padding: 10px 24px; border-radius: 10px; font-size: 12px; font-weight: 800; text-transform: uppercase; transition: 0.2s; }
        .btn-apply:hover { background: #1d4ed8; transform: translateY(-1px); }

        .btn-view-file { display: inline-flex; align-items: center; gap: 8px; background: white; border: 1px solid var(--border); padding: 6px 12px; border-radius: 8px; font-size: 11px; font-weight: 800; color: var(--text); transition: 0.2s; }
        .btn-view-file:hover { border-color: var(--blue-primary); color: var(--blue-primary); background: var(--blue-light); }
    </style>
</head>
<body>

<div class="flex">
    <jsp:include page="sidebar.jsp" />
    
    <main class="flex-1 ml-20 lg:ml-64 min-h-screen transition-all duration-300">
        <jsp:include page="topbar.jsp" />
        
        <div class="pageWrap">
            <div class="mb-8">
                <h2 class="title">Leave History</h2>
                <span class="sub-label">Administrator Control Panel: List of employee leave request records and status tracking</span>
            </div>

            <form action="leaveEmpHistory" method="get" class="toolbar">
                <div class="filter-group">
                    <label>Status Filter</label>
                    <select name="status">
                        <option value="ALL" <%= "ALL".equals(currentStatus)?"selected":"" %>>All Statuses</option>
                        <option value="PENDING" <%= "PENDING".equals(currentStatus)?"selected":"" %>>Pending</option>
                        <option value="APPROVED" <%= "APPROVED".equals(currentStatus)?"selected":"" %>>Approved</option>
                        <option value="REJECTED" <%= "REJECTED".equals(currentStatus)?"selected":"" %>>Rejected</option>
                    </select>
                </div>
                <div class="w-px h-8 bg-slate-200"></div>
                <div class="filter-group">
                    <label>Month</label>
                    <select name="month">
                        <option value="">Full Year</option>
                        <% for(int m=1; m<=12; m++) { 
                            String mVal = String.format("%02d", m);
                            String mName = Month.of(m).getDisplayName(TextStyle.FULL, Locale.ENGLISH);
                        %>
                            <option value="<%=mVal%>" <%= mVal.equals(currentMonth)?"selected":"" %>><%=mName%></option>
                        <% } %>
                    </select>
                </div>
                <div class="filter-group">
                    <label>Year</label>
                    <select name="year">
                        <option value="">Select Year</option>
                        <% if(years != null) { for(String yr : years) { %>
                            <option value="<%=yr%>" <%= yr.equals(currentYear)?"selected":"" %>><%=yr%></option>
                        <% } } %>
                    </select>
                </div>
                <button type="submit" class="btn-apply ml-auto shadow-sm flex items-center gap-2">
                    <%= SearchIcon("w-4 h-4") %> Update Records
                </button>
            </form>

            <div class="card">
                <div class="cardHead">
                    <span>Leave Applications List</span>
                    <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                        Total Records: <%= (history != null ? history.size() : 0) %>
                    </div>
                </div>
                <div class="overflow-x-auto">
                    <table>
                        <thead>
                            <tr>
                                <th>Staff Member</th>
                                <th>Type</th>
                                <th>Dates</th>
                                <th>Days</th>
                                <th>Status</th>
                                <th style="text-align:right">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (history == null || history.isEmpty()) { %>
                                <tr>
                                    <td colspan="6" class="text-center py-24 text-slate-300 font-bold uppercase text-xs italic tracking-widest">
                                        <div class="mb-2"><%= InfoIcon("w-8 h-8 mx-auto opacity-20") %></div>
                                        No matching history records found.
                                    </td>
                                </tr>
                            <% } else { 
                                for (LeaveRecord r : history) { 
                                    String status = r.getStatusCode();
                                    String badgeClass = "status-pending";
                                    if ("APPROVED".equalsIgnoreCase(status)) badgeClass = "status-approved";
                                    else if ("REJECTED".equalsIgnoreCase(status)) badgeClass = "status-rejected";
                                    else if ("CANCELLED".equalsIgnoreCase(status)) badgeClass = "status-cancelled";
                                    
                                    java.util.Date joinDate = r.getHireDate();
                                    String joinYear = (joinDate != null) ? String.valueOf(cal.get(Calendar.YEAR)) : "0000";
                                    if(joinDate != null) { cal.setTime(joinDate); joinYear = String.valueOf(cal.get(Calendar.YEAR)); }

                                    String displayEmpId = "EMP-" + joinYear + "-" + String.format("%02d", r.getEmpId());
                            %>
                                <tr class="hover:bg-slate-50/50 transition-colors">
                                    <td>
                                        <div class="flex items-center gap-3">
                                            <div class="w-10 h-10 rounded-lg bg-slate-100 overflow-hidden flex-shrink-0 border border-slate-200 flex items-center justify-center">
                                                <% if (r.getProfilePic() != null && !r.getProfilePic().isEmpty()) { %>
                                                    <img src="<%= request.getContextPath() + "/" + r.getProfilePic() %>" class="w-full h-full object-cover">
                                                <% } else { %>
                                                    <div class="text-slate-400 font-bold text-xs uppercase">
                                                        <%= (r.getFullName() != null) ? r.getFullName().substring(0,1) : "?" %>
                                                    </div>
                                                <% } %>
                                            </div>
                                            <div>
                                                <div class="font-bold text-slate-800 text-sm"><%= r.getFullName() %></div>
                                                <div class="text-[10px] text-blue-600 font-bold uppercase tracking-tighter"><%= displayEmpId %></div>
                                            </div>
                                        </div>
                                    </td>
                                    <td><span class="bg-slate-100 text-slate-500 px-3 py-1 rounded-lg text-[9px] font-black uppercase border border-slate-200"><%= r.getTypeCode() %></span></td>
                                    <td class="text-xs font-semibold text-slate-600"><%= r.getStartDate() %> — <%= r.getEndDate() %></td>
                                    <td class="font-bold text-slate-800 text-sm"><%= r.getDurationDays() %> </td>
                                    <td>
                                        <span class="badge <%= badgeClass %>">
                                            <span class="w-1.5 h-1.5 rounded-full bg-current"></span> 
                                            <%= (status != null) ? status.replace("_", " ") : "UNKNOWN" %>
                                        </span>
                                    </td>
                                    <td style="text-align:right">
                                        <button onclick="viewDetails(this)" class="bg-white border border-slate-200 text-slate-600 px-4 py-2 rounded-lg text-[10px] font-bold hover:bg-slate-900 hover:text-white transition-all uppercase tracking-widest flex items-center gap-2 ml-auto"
                                                data-id="<%= r.getLeaveId() %>"
                                                data-name="<%= r.getFullName() %>" data-idcode="<%= displayEmpId %>"
                                                data-type="<%= r.getTypeCode() %>" data-start="<%= r.getStartDate() %>"
                                                data-end="<%= r.getEndDate() %>" data-days="<%= r.getDurationDays() %>"
                                                data-duration="<%= r.getDuration() %>" data-applied="<%= r.getAppliedOn() %>"
                                                data-reason="<%= r.getReason() %>" data-status="<%= status %>"
                                                data-attachment="<%= r.getAttachment() != null ? r.getAttachment() : "" %>"
                                                data-med="<%= r.getMedicalFacility() %>" data-ref="<%= r.getRefSerialNo() %>"
                                                data-evt="<%= r.getEventDate() %>" data-dis="<%= r.getDischargeDate() %>"
                                                data-cat="<%= r.getEmergencyCategory() %>" data-cnt="<%= r.getEmergencyContact() %>"
                                                data-spo="<%= r.getSpouseName() %>"
                                                data-comment="<%= r.getAdminComment() != null ? r.getAdminComment() : "-" %>">
                                            <%= EyeIcon("w-3 h-3") %> View
                                        </button>
                                    </td>
                                </tr>
                            <% } } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </main>
</div>

<!-- ✅ Redesigned Modal Popup (Standardized Layout) -->
<div class="modal-overlay" id="detailModal">
    <div class="modal-content">
        <div class="modal-header">
            <div>
                <span class="text-[10px] font-black text-blue-600 uppercase tracking-widest">Leave Details</span>
                <h3 class="text-xl font-extrabold text-slate-900 uppercase tracking-tight">Employee Application</h3>
            </div>
            <button type="button" class="btn-close" onclick="closeModal()">
                <%= XCircleIcon("w-5 h-5") %>
            </button>
        </div>

        <div class="modal-body">
            <!-- Row 1: Employee & ID -->
            <div class="info-grid">
                <div class="info-item">
                    <span class="info-label">Employee Name</span>
                    <span class="info-value" id="popName"></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Employee ID</span>
                    <span class="info-value text-blue-600" id="popId"></span>
                </div>
            </div>

            <!-- Row 2: Category & Days -->
            <div class="info-grid">
                <div class="info-item">
                    <span class="info-label">Leave Category</span>
                    <span class="info-value" id="popType"></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Total Days</span>
                    <span class="info-value font-black" id="popDays"></span>
                </div>
            </div>

            <!-- Row 3: Start Date & End Date -->
            <div class="info-grid">
                <div class="info-item">
                    <span class="info-label">Start Date</span>
                    <span class="info-value" id="popStart"></span>
                </div>
                <div class="info-item">
                    <span class="info-label">End Date</span>
                    <span class="info-value" id="popEnd"></span>
                </div>
            </div>

            <!-- Row 4: Applied On & Attachment -->
            <div class="info-grid">
                <div class="info-item">
                    <span class="info-label">Applied On</span>
                    <span class="info-value text-slate-500" id="popApplied"></span>
                </div>
                <div class="info-item" id="attachBoxContainer">
                    <span class="info-label">Supportive Attachment</span>
                    <div id="attachBox" class="hidden">
                        <a id="modalAttachLink" href="#" target="_blank" class="btn-view-file">
                            <%= FilePlusIcon("w-4 h-4 text-red-500") %> VIEW FILE
                        </a>
                    </div>
                    <div id="noAttachLabel" class="text-xs text-slate-300 font-bold italic">No document attached</div>
                </div>
            </div>

            <!-- Full Width: Justification -->
            <div class="info-item mb-8">
                <span class="info-label">Staff Justification</span>
                <div class="bg-slate-50 p-5 rounded-2xl border border-slate-100 text-sm text-slate-600 italic leading-relaxed" id="popReason"></div>
            </div>

            <!-- Full Width: Meta Attributes -->
            <div id="dynamicBox" class="hidden">
                <div class="flex items-center gap-2 mb-3">
                    <%= ClipboardListIcon("w-3 h-3 text-blue-500") %>
                    <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Metadata Attributes</span>
                </div>
                <div class="grid grid-cols-2 gap-4 bg-slate-50 p-5 rounded-2xl border border-slate-200 mb-8" id="dynamicGrid"></div>
            </div>

            <!-- Full Width: Manager Remarks -->
            <div class="info-item mb-8">
                <span class="info-label">Manager Remarks</span>
                <div class="info-value text-slate-600 font-semibold italic p-2 border-l-4 border-slate-200" id="popComment"></div>
            </div>
        </div>
    </div>
</div>

<script>
    const CTX = "<%=request.getContextPath()%>";

    function viewDetails(btn) {
        const d = btn.dataset;
        document.getElementById('popName').textContent = d.name;
        document.getElementById('popId').textContent = d.idcode;
        document.getElementById('popType').textContent = d.type;
        document.getElementById('popStart').textContent = d.start;
        document.getElementById('popEnd').textContent = d.end;
        document.getElementById('popDays').textContent = d.days + " Days (" + d.duration.replace(/_/g, ' ') + ")";
        document.getElementById('popReason').textContent = d.reason || "No specific reason provided.";
        document.getElementById('popComment').textContent = d.comment && d.comment !== "null" && d.comment !== "-" ? d.comment : "No remarks available.";
        document.getElementById('popApplied').textContent = d.applied;

        const abox = document.getElementById('attachBox');
        const noAttach = document.getElementById('noAttachLabel');
        if(d.attachment && d.attachment !== "" && d.attachment !== "null") {
            abox.classList.remove('hidden');
            noAttach.classList.add('hidden');
            document.getElementById('modalAttachLink').href = CTX + "/ViewAttachment?id=" + d.id;
        } else { 
            abox.classList.add('hidden'); 
            noAttach.classList.remove('hidden');
        }

        const dBox = document.getElementById('dynamicBox');
        const grid = document.getElementById('dynamicGrid');
        grid.innerHTML = "";
        let count = 0;
        const addAttr = (label, val) => {
            if(val && val !== "null" && val !== "" && val !== "undefined") {
                grid.innerHTML += `<div class="info-item"><span class="info-label text-[9px]">${label}</span><span class="info-value text-xs">${val}</span></div>`;
                count++;
            }
        };
        addAttr("Medical Facility", d.med);
        addAttr("Serial No", d.ref);
        addAttr("Event Date", d.evt);
        addAttr("Discharge Date", d.dis);
        addAttr("Emergency Cat", d.cat);
        addAttr("Contact Phone", d.cnt);
        addAttr("Spouse Name", d.spo);

        dBox.classList.toggle('hidden', count === 0);
        document.getElementById('detailModal').classList.add('show');
    }

    function closeModal() {
        document.getElementById('detailModal').classList.remove('show');
    }

    window.onclick = (e) => { if (e.target == document.getElementById('detailModal')) closeModal(); }
</script>

</body>
</html>