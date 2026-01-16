<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.time.*" %>
<%@ page import="java.time.format.TextStyle" %>
<%@ page import="bean.LeaveRecord" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ include file="icon.jsp" %>

<%
    // ADMIN GUARD
    HttpSession ses = request.getSession(false);
    if (ses == null || ses.getAttribute("empid") == null || !"ADMIN".equalsIgnoreCase(String.valueOf(ses.getAttribute("role")))) {
        response.sendRedirect("login.jsp"); return;
    }

    // DATA RETRIEVAL
    List<LeaveRecord> history = (List<LeaveRecord>) request.getAttribute("history");
    List<String> years = (List<String>) request.getAttribute("years");
    
    // Filtering Parameters
    String currentStatus = request.getParameter("status") != null ? request.getParameter("status") : "ALL";
    String currentMonth = request.getParameter("month") != null ? request.getParameter("month") : ""; // Empty = Full Year
    String currentYear = request.getParameter("year");
    if (currentYear == null || currentYear.isEmpty()) {
        currentYear = String.valueOf(LocalDate.now().getYear());
    }

    // =========================
    // PAGINATION LOGIC (10 Rows)
    // =========================
    int pageSize = 10;
    int totalRecords = (history != null) ? history.size() : 0;
    int currentPage = 1;
    try {
        if(request.getParameter("page") != null) currentPage = Integer.parseInt(request.getParameter("page"));
    } catch(NumberFormatException e) { currentPage = 1; }

    int totalPages = (int) Math.ceil((double) totalRecords / pageSize);
    if (currentPage > totalPages && totalPages > 0) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;
    
    int startIndex = (currentPage - 1) * pageSize;
    int endIndex = Math.min(startIndex + pageSize, totalRecords);
    
    List<LeaveRecord> paginatedList = new ArrayList<>();
    if (history != null && !history.isEmpty() && startIndex < totalRecords) {
        paginatedList = history.subList(startIndex, endIndex);
    }
    
    Calendar cal = Calendar.getInstance();
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin | Leave History Management</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">

    <style>
        :root {
            --bg: #f1f5f9;
            --card: #fff;
            --border: #cbd5e1;
            --text: #1e293b;
            --muted: #64748b;
            --blue-primary: #2563eb;
            --blue-light: #eff6ff;
            --radius: 20px;
            --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
        }

        * { box-sizing: border-box; font-family: 'Inter', sans-serif; }
        .fas, .fab, .far, .fa-solid, .fa { font-family: "Font Awesome 6 Free" !important; font-weight: 900; }
        
        body { background: var(--bg); color: var(--text); margin: 0; }
        .pageWrap { padding: 32px 40px; max-width: 1300px; margin: 0 auto; }

        .title { font-size: 26px; font-weight: 800; margin: 0; text-transform: uppercase; color: var(--text); }
        .sub-label { color: var(--blue-primary); font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.1em; margin-top: 4px; display: block; }

        .filter-bar { background: #fff; border: 1px solid var(--border); border-radius: 1.5rem; padding: 20px 24px; box-shadow: var(--shadow); margin-bottom: 24px; }
        .filter-group { display: flex; flex-direction: column; gap: 4px; }
        .filter-label { font-size: 10px; font-weight: 900; color: var(--muted); text-transform: uppercase; letter-spacing: 0.05em; margin-left: 4px; }
        
        /* UPDATED: Filter box styling 45px height and 20px padding */
        select {
            height: 45px !important;
            padding: 0 20px !important; 
            border-radius: 12px; 
            border: 1px solid var(--border); 
            outline: none; 
            font-size: 14px; 
            font-weight: 600; 
            cursor: pointer; 
            background: #fff;
            transition: all 0.2s;
            min-width: 180px;
        }
        select:focus { border-color: var(--blue-primary); box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1); }

        .card { background: var(--card); border: 1px solid var(--border); border-radius: var(--radius); box-shadow: var(--shadow); overflow: hidden; }
        
        table { width: 100%; border-collapse: collapse; }
        th, td { border-bottom: 1px solid #f1f5f9; padding: 18px 24px; text-align: left; vertical-align: middle; }
        th { background: #f8fafc; font-size: 11px; text-transform: uppercase; color: var(--muted); font-weight: 800; letter-spacing: 0.05em; }

        .badge { padding: 4px 12px; border-radius: 20px; font-size: 10px; font-weight: 800; text-transform: uppercase; display: inline-flex; align-items: center; gap: 6px; }
        .status-pending { background: #fffbeb; color: #b45309; border: 1px solid #fde68a; } 
        .status-approved { background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; } 
        .status-rejected { background: #fef2f2; color: #b91c1c; border: 1px solid #fecaca; } 
        .status-cancelled { background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0; } 
        .status-cancellation-requested { background: #fff7ed; color: #c2410c; border: 1px solid #fdba74; }

        /* Pagination Styles */
        .pagination-btn { padding: 8px 16px; border-radius: 10px; border: 1px solid var(--border); font-size: 12px; font-weight: 800; transition: 0.2s; color: var(--muted); background: white; }
        .pagination-btn:hover:not(:disabled) { border-color: var(--blue-primary); color: var(--blue-primary); background: var(--blue-light); }
        .pagination-btn.active { background: var(--blue-primary); color: #fff; border-color: var(--blue-primary); }
        .pagination-btn:disabled { opacity: 0.4; cursor: not-allowed; }

        .modal-overlay { position:fixed; inset:0; background:rgba(15,23,42,0.6); display:none; align-items:center; justify-content:center; z-index:9999; backdrop-filter:blur(4px); padding: 20px; }
        .modal-overlay.show { display:flex; }
        .modal-content { background:white; width: 100%; max-width: 750px; max-height: 90vh; border-radius: 32px; padding: 40px; position: relative; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); display: flex; flex-direction: column; overflow: hidden; animation: slideUp 0.3s ease; }
        @keyframes slideUp { from{opacity:0; transform:translateY(20px);} to{opacity:1; transform:translateY(0);} }
        .modal-body { overflow-y: auto; padding-right: 8px; flex: 1; }
        .info-label { font-size:10px; font-weight:800; color:#94a3b8; text-transform:uppercase; display:block; margin-bottom:4px; letter-spacing:0.05em; }
        .info-value { font-size:14px; font-weight:700; color:#1e293b; display:block; margin-bottom:18px; }
        .btn-close { position: absolute; top: 24px; right: 24px; width: 40px; height: 40px; border-radius: 12px; border: 1px solid var(--border); background: #fff; cursor: pointer; display: flex; align-items: center; justify-content: center; color: #94a3b8; transition: 0.2s; z-index: 10; }
        .btn-close:hover { background: #fef2f2; border-color: #fecaca; color: #ef4444; }
        .dynamic-meta-container { background: #f8fafc; border: 1px solid var(--border); border-radius: 16px; padding: 20px; margin-top: 10px; margin-bottom: 24px; }
    </style>
</head>
<body>

<div class="flex">
    <jsp:include page="sidebar.jsp" />
    
    <main class="ml-20 lg:ml-64 min-h-screen w-full transition-all duration-300">
        <jsp:include page="topbar.jsp" />
        
        <div class="pageWrap">
            <div class="flex justify-between items-end mb-8">
                <div>
                    <h2 class="title">LEAVE HISTORY</h2>
                    <span class="sub-label">Administrator Panel: Audit Log for <%= currentYear %></span>
                </div>
                <div class="bg-white border border-slate-200 px-4 py-2 rounded-xl text-xs font-black text-slate-500 shadow-sm uppercase tracking-tighter">
                    Total Records: <%= totalRecords %>
                </div>
            </div>

            <!-- Automatic Filter Form -->
            <form id="filterForm" action="leaveEmpHistory" method="get" class="filter-bar flex flex-wrap items-center gap-6">
                <input type="hidden" name="page" value="1">
                
                <div class="filter-group">
                    <span class="filter-label">Status</span>
                    <select name="status" onchange="this.form.submit()">
                        <option value="ALL" <%= "ALL".equals(currentStatus)?"selected":"" %>>All Statuses</option>
                        <option value="PENDING" <%= "PENDING".equals(currentStatus)?"selected":"" %>>Pending</option>
                        <option value="APPROVED" <%= "APPROVED".equals(currentStatus)?"selected":"" %>>Approved</option>
                        <option value="REJECTED" <%= "REJECTED".equals(currentStatus)?"selected":"" %>>Rejected</option>
                        <option value="CANCELLED" <%= "CANCELLED".equals(currentStatus)?"selected":"" %>>Cancelled</option>
                        <option value="CANCELLATION_REQUESTED" <%= "CANCELLATION_REQUESTED".equals(currentStatus)?"selected":"" %>>Request Cancellation</option>
                    </select>
                </div>

                <div class="filter-group">
                    <span class="filter-label">Month</span>
                    <select name="month" onchange="this.form.submit()">
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
                    <span class="filter-label">Year</span>
                    <select name="year" onchange="this.form.submit()">
                        <% if(years != null) { for(String yr : years) { %>
                            <option value="<%=yr%>" <%= yr.equals(currentYear)?"selected":"" %>><%=yr%></option>
                        <% } } %>
                    </select>
                </div>
            </form>

            <div class="card">
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
                            <% if (paginatedList.isEmpty()) { %>
                                <tr><td colspan="6" class="text-center py-24 text-slate-300 font-bold uppercase text-xs italic tracking-widest">No matching history records found.</td></tr>
                            <% } else { for (LeaveRecord r : paginatedList) { 
                                String status = r.getStatusCode();
                                String badgeClass = "status-pending";
                                if ("APPROVED".equalsIgnoreCase(status)) badgeClass = "status-approved";
                                else if ("REJECTED".equalsIgnoreCase(status)) badgeClass = "status-rejected";
                                else if ("CANCELLED".equalsIgnoreCase(status)) badgeClass = "status-cancelled";
                                else if ("CANCELLATION_REQUESTED".equalsIgnoreCase(status)) badgeClass = "status-cancellation-requested";

                                String joinYear = "0000";
                                if(r.getHireDate() != null) { cal.setTime(r.getHireDate()); joinYear = String.valueOf(cal.get(Calendar.YEAR)); }
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
                                                <div class="font-bold text-slate-800 text-sm uppercase"><%= r.getFullName() %></div>
                                                <div class="text-[10px] text-blue-600 font-bold uppercase tracking-tighter"><%= displayEmpId %></div>
                                            </div>
                                        </div>
                                    </td>
                                    <td><span class="bg-slate-100 text-slate-500 px-3 py-1 rounded-lg text-[9px] font-black uppercase border border-slate-200"><%= r.getTypeCode() %></span></td>
                                    <td class="text-xs font-semibold text-slate-600"><%= r.getStartDate() %> — <%= r.getEndDate() %></td>
                                    <td class="font-bold text-slate-800 text-sm"><%= r.getDurationDays() %></td>
                                    <td>
                                        <span class="badge <%= badgeClass %>">
                                            <span class="w-1.5 h-1.5 rounded-full bg-current"></span> <%= (status != null) ? status.replace("_", " ") : "UNKNOWN" %>
                                        </span>
                                    </td>
                                    <td style="text-align:right">
                                        <button onclick="viewDetails(this)" class="bg-white border border-slate-200 text-slate-600 px-5 py-2 rounded-xl text-[10px] font-black hover:bg-slate-900 hover:text-white transition-all uppercase tracking-widest shadow-sm flex items-center gap-2 ml-auto"
                                                data-id="<%= r.getLeaveId() %>"
                                                data-name="<%= r.getFullName() %>" 
                                                data-idcode="<%= displayEmpId %>"
                                                data-type="<%= r.getTypeCode() %>" 
                                                data-start="<%= r.getStartDate() %>" 
                                                data-end="<%= r.getEndDate() %>" 
                                                data-days="<%= r.getDurationDays() %>" 
                                                data-duration="<%= r.getDuration() %>" 
                                                data-applied="<%= r.getAppliedOn() %>" 
                                                data-reason="<%= r.getReason() %>" 
                                                data-attachment="<%= r.getAttachment() != null ? r.getAttachment() : "" %>"
                                                data-med="<%= r.getMedicalFacility() %>" 
                                                data-ref="<%= r.getRefSerialNo() %>"
                                                data-pre="<%= r.getWeekPregnancy() %>" 
                                                data-evt="<%= r.getEventDate() %>" 
                                                data-dis="<%= r.getDischargeDate() %>"
                                                data-cat="<%= r.getEmergencyCategory() %>" 
                                                data-cnt="<%= r.getEmergencyContact() %>"
                                                data-spo="<%= r.getSpouseName() %>" 
                                                data-comment="<%= r.getManagerComment() != null ? r.getManagerComment() : "-" %>">
                                            <%= EyeIcon("w-3.5 h-3.5") %> View
                                        </button>
                                    </td>
                                </tr>
                            <% } } %>
                        </tbody>
                    </table>
                </div>

                <!-- PAGINATION FOOTER -->
                <div class="px-6 py-5 bg-slate-50 border-t border-slate-100 flex items-center justify-between">
                    <div class="text-[11px] font-bold text-slate-400 uppercase tracking-widest">
                        Showing <%= totalRecords == 0 ? 0 : startIndex + 1 %> to <%= endIndex %> of <%= totalRecords %> entries
                    </div>
                    
                    <% if (totalPages > 1) { %>
                    <div class="flex items-center gap-2">
                        <button type="button" class="pagination-btn" onclick="goToPage(<%= currentPage - 1 %>)" <%= currentPage == 1 ? "disabled" : "" %>>
                            <i class="fas fa-chevron-left mr-1"></i> Prev
                        </button>
                        
                        <% for(int p=1; p<=totalPages; p++) { %>
                            <button type="button" class="pagination-btn <%= p == currentPage ? "active" : "" %>" onclick="goToPage(<%= p %>)">
                                <%= p %>
                            </button>
                        <% } %>
                        
                        <button type="button" class="pagination-btn" onclick="goToPage(<%= currentPage + 1 %>)" <%= currentPage == totalPages ? "disabled" : "" %>>
                            Next <i class="fas fa-chevron-right ml-1"></i>
                        </button>
                    </div>
                    <% } %>
                </div>
            </div>
        </div>
    </main>
</div>

<!-- POPUP MODAL (UNCHANGED LOGIC) -->
<div class="modal-overlay" id="detailModal">
    <div class="modal-content">
        <button type="button" class="btn-close" onclick="closeModal()"><i class="fas fa-times"></i></button>
        <div class="modal-body">
            <h3 class="text-2xl font-black text-slate-800 tracking-tight uppercase mb-8 pr-12 border-b border-slate-100 pb-4">Application Details</h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-x-12">
                <div class="info-item">
                    <span class="info-label">Staff Name</span>
                    <span class="info-value" id="popName"></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Staff ID</span>
                    <span class="info-value" id="popId"></span>
                </div>
            </div>

            <div class="info-item">
                <span class="info-label">Leave Category</span>
                <div class="flex items-center gap-3">
                    <span class="info-value text-blue-600 mb-0" id="popType"></span>
                </div>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-x-12 mt-4">
                <div class="info-item">
                    <span class="info-label">Start Date</span>
                    <span class="info-value" id="popStart"></span>
                </div>
                <div class="info-item">
                    <span class="info-label">End Date</span>
                    <span class="info-value" id="popEnd"></span>
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-x-12">
                <div class="info-item">
                    <span class="info-label">Duration Type</span>
                    <span class="info-value uppercase" id="popDuration"></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Total Days</span>
                    <span class="info-value font-black text-blue-600" id="popDays"></span>
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-x-12">
                <div class="info-item">
                    <span class="info-label">Submission Date</span>
                    <span class="info-value" id="popApplied"></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Supportive Attachment</span>
                    <div id="attachBox" class="hidden">
                        <a id="modalAttachLink" href="#" target="_blank" class="inline-flex items-center gap-3 bg-white border-2 border-slate-100 px-5 py-3 rounded-2xl text-[11px] font-black text-slate-600 hover:border-blue-200 hover:text-blue-600 transition-all">
                            <i class="fas fa-file-medical text-red-500 text-lg"></i> VIEW DOCUMENT <i class="fas fa-external-link-alt opacity-20 text-[9px]"></i>
                        </a>
                    </div>
                    <div id="noAttachLabel" class="text-xs text-slate-300 font-bold italic py-2">No document attached</div>
                </div>
            </div>

            <div class="info-item">
                <span class="info-label">Employee Reason</span>
                <p class="text-sm text-slate-500 mb-6 bg-slate-50 p-5 rounded-2xl border border-slate-100 font-medium leading-relaxed italic" id="popReason"></p>
            </div>

            <!-- Dynamic Metadata Section -->
            <div id="dynamicBox" class="hidden">
                <div class="flex items-center gap-3 mb-4">
                    <div class="w-1 h-4 bg-blue-600 rounded-full"></div>
                    <h4 class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Metadata Attributes (Specific To Type)</h4>
                </div>
                <div class="dynamic-meta-container space-y-4" id="dynamicGrid"></div>
            </div>

            <div class="info-item">
                <span class="info-label">Manager Remark</span>
                <p class="text-sm text-blue-600 italic font-semibold" id="popComment"></p>
            </div>
        </div>
    </div>
</div>

<script>
    const CTX = "<%=request.getContextPath()%>";

    // Auto-Dismiss Messages
    window.onload = function() {
        const msg = document.getElementById('statusAlert');
        if (msg) {
            setTimeout(() => {
                msg.style.opacity = '0';
                setTimeout(() => msg.remove(), 500);
            }, 3000);
        }
    };

    function goToPage(pageNum) {
        const urlParams = new URLSearchParams(window.location.search);
        urlParams.set('page', pageNum);
        window.location.search = urlParams.toString();
    }

    function viewDetails(btn) {
        const d = btn.dataset;
        document.getElementById('popName').textContent = d.name;
        document.getElementById('popId').textContent = d.idcode;
        document.getElementById('popType').textContent = d.type;
        document.getElementById('popStart').textContent = d.start;
        document.getElementById('popEnd').textContent = d.end;
        document.getElementById('popDuration').textContent = d.duration.replace(/_/g, ' ');
        document.getElementById('popDays').textContent = d.days;
        document.getElementById('popApplied').textContent = d.applied;
        document.getElementById('popReason').textContent = d.reason || "No reason provided.";
        document.getElementById('popComment').textContent = d.comment && d.comment !== "-" ? d.comment : "No remarks available.";

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
            if(val && val !== "null" && val !== "" && val !== "undefined" && val !== "N/A" && val !== "0") {
                grid.innerHTML += '<div class="info-item border-b border-slate-100 pb-2 flex justify-between items-center"><span class="info-label text-slate-400 mb-0">'+label+'</span><span class="info-value mb-0 text-slate-600 font-bold uppercase text-[11px]">'+val+'</span></div>';
                count++;
            }
        };

        const code = (d.type || "").toUpperCase();
        if (code.includes("SICK")) 
        { 
        	addAttr("Clinic Name ", d.med); 
       		addAttr("MC Serial No", d.ref); 
        }
        else if (code.includes("HOSPITAL")) 
        { 
        	addAttr("Hospital Name", d.med); 
        	addAttr("Admit Date", d.evt); 
        	addAttr("Discharge Date", d.dis); 
        	}
        else if (code.includes("MATERNITY")) 
        { 
        	addAttr("Consulation Clinic ", d.med); 
            addAttr("Expected Due Date", d.evt); 
            addAttr("Week Pregenancy", d.pre); 
        }
        else if (code.includes("PATERNITY")) 
        { 
        	addAttr("Spouse Name", d.spo); 
            addAttr("Medical Location ", d.med); 
            addAttr("Date of Birth", d.evt); 
        }
        else if (code.includes("EMERGENCY")) 
        { 
        	addAttr("Emergency Category", d.cat); 
            addAttr("Emergency Contact", d.cnt); 
        }

        document.getElementById('dynamicBox').classList.toggle('hidden', count === 0);
        document.getElementById('detailModal').classList.add('show');
    }
    
    function closeModal() { document.getElementById('detailModal').classList.remove('show'); }
    window.onclick = (e) => { if (e.target == document.getElementById('detailModal')) closeModal(); }
</script>

</body>
</html>