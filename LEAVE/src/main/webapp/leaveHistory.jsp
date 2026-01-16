<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.text.SimpleDateFormat" %>
<%@ include file="icon.jsp" %>

<%
// =========================
// SECURITY CHECK
// =========================
HttpSession ses = request.getSession(false);
String role = (ses != null) ? String.valueOf(ses.getAttribute("role")) : "";
String userFullName = (ses != null) ? String.valueOf(ses.getAttribute("fullname")) : "User";
String userEmpId = (ses != null) ? String.valueOf(ses.getAttribute("empid")) : "0";

if (ses == null || ses.getAttribute("empid") == null ||
(!"EMPLOYEE".equalsIgnoreCase(role) && !"MANAGER".equalsIgnoreCase(role))) {
    response.sendRedirect(request.getContextPath() + "/login.jsp?error=Please+login+as+employee+or+manager");
    return;
}

// =========================
// DATA RETRIEVAL
// =========================
List<Map<String, Object>> allLeaves = (List<Map<String, Object>>) request.getAttribute("leaves");
List<String> years = (List<String>) request.getAttribute("years");
String dbError = (String) request.getAttribute("error");

if (allLeaves == null) allLeaves = new ArrayList<>();
if (years == null) years = new ArrayList<>();

String currentStatus = request.getParameter("status") != null ? request.getParameter("status") : "ALL";
String currentYear = request.getParameter("year") != null ? request.getParameter("year") : "";

// =========================
// PAGINATION LOGIC (10 entries)
// =========================
int pageSize = 10;
int totalRecords = allLeaves.size();
int currentPage = 1;
try {
    if(request.getParameter("p") != null) currentPage = Integer.parseInt(request.getParameter("p"));
} catch(Exception e) { currentPage = 1; }

int totalPages = (int) Math.ceil((double) totalRecords / pageSize);
if (currentPage < 1) currentPage = 1;
if (totalPages > 0 && currentPage > totalPages) currentPage = totalPages;

int startIdx = (currentPage - 1) * pageSize;
int endIdx = Math.min(startIdx + pageSize, totalRecords);

List<Map<String, Object>> leaves = (totalRecords > 0) ? allLeaves.subList(startIdx, endIdx) : new ArrayList<>();

// Formatting setup - STRICT DD/MM/YYYY
SimpleDateFormat sdfDb = new SimpleDateFormat("yyyy-MM-dd");
SimpleDateFormat sdfDisplay = new SimpleDateFormat("dd/MM/yyyy");
SimpleDateFormat sdfTimeDb = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
SimpleDateFormat sdfTimeDisplay = new SimpleDateFormat("dd/MM/yyyy HH:mm");

Calendar calToday = Calendar.getInstance();
calToday.set(Calendar.HOUR_OF_DAY, 0); calToday.set(Calendar.MINUTE, 0); calToday.set(Calendar.SECOND, 0); calToday.set(Calendar.MILLISECOND, 0);
Date todayMidnight = calToday.getTime();
%>

<%! 
    public String RotateCcwIcon(String cls) {
        return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><path d='M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8'/><path d='M3 3v5h5'/></svg>";
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>LMS | My Leave History</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<script src="https://cdn.tailwindcss.com"></script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">

<style>
:root {
  --bg: #f1f5f9;
  --card: #ffffff;
  --primary: #2563eb;
  --text-main: #1e293b;
  --text-muted: #475569;
  --border: #e2e8f0;
  --radius: 20px;
}

* { box-sizing: border-box; font-family: 'Inter', Arial, sans-serif !important; }
body { background: var(--bg); color: var(--text-main); margin: 0; overflow-x: hidden; -webkit-font-smoothing: antialiased; }

.pageWrap { padding: 32px 40px; max-width: 1400px; margin: 0 auto; }

/* Consistent Header Styling */
.title { font-size: 26px; font-weight: 800; margin: 0; text-transform: uppercase; color: #000; letter-spacing: -0.02em; }
.sub-label { color: var(--primary); font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.1em; margin-top: 4px; display: block; }

/* Filter Styling - 45px height and 20px padding */
.filter-card {
  background: var(--card); border: 1px solid var(--border); border-radius: var(--radius);
  padding: 14px 24px; display: flex; justify-content: space-between; align-items: center;
  margin-bottom: 24px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05);
}
.filter-group { display: flex; align-items: center; gap: 12px; }
.filter-group label { font-size: 11px; font-weight: 900; color: #233f66; text-transform: uppercase; letter-spacing: 0.05em; }

/* Standard styling for dropdowns */
.filter-card select { 
    height: 45px !important; 
    padding: 0 20px !important; 
    border-radius: 12px; 
    border: 2.1px solid var(--border); 
    background: #fff; 
    font-size: 14px; 
    font-weight: 600; 
    outline: none; 
    transition: 0.2s; 
    cursor: pointer;
}
.filter-card select:focus { border-color: var(--primary); box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.05); }

select, input[type="date"], textarea { padding: 10px 16px; border-radius: 12px; border: 2.1px solid var(--border); background: #fff; font-size: 14px; font-weight: 600; outline: none; transition: 0.2s; }

/* UPDATED: Modal Input Specific Styling */
.modal-body select, 
.modal-body input[type="date"] { 
    height: 45px !important; 
    padding: 0 20px !important; 
    border: 2px solid var(--border);
}
.modal-body textarea { 
    padding: 20px !important; 
    border: 2px solid var(--border);
}

/* Table Optimization */
.table-card { background: var(--card); border: 1px solid var(--border); border-radius: var(--radius); box-shadow: 0 10px 15px -3px rgba(0,0,0,0.04); overflow: hidden; }
table { width: 100%; border-collapse: collapse; }
th { background: #f8fafc; padding: 16px 20px; font-size: 11px; font-weight: 850; color: #64748b; text-transform: uppercase; border-bottom: 2px solid var(--border); text-align: left; letter-spacing: 0.05em; }
td { padding: 18px 20px; border-bottom: 1px solid #f1f5f9; font-size: 15px; vertical-align: middle; }

.badge { padding: 4px 12px; border-radius: 12px; font-size: 10px; font-weight: 800; text-transform: uppercase; display: inline-flex; align-items: center; gap: 6px; }
.status-pending { background: #fffbeb; color: #b45309; border: 1px solid #fde68a; } 
.status-approved { background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; } 
.status-rejected { background: #fef2f2; color: #b91c1c; border: 1px solid #fecaca; } 
.status-cancelled { background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0; } 
.status-cancellation-requested { background: #fff7ed; color: #c2410c; border: 1px solid #fdba74; } 

/* Pagination UI */
.pagination-container { padding: 16px 24px; background: #fcfcfd; border-top: 1px solid #f1f5f9; display: flex; justify-content: space-between; align-items: center; }
.pagination-info { font-size: 11px; font-weight: 800; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
.pagination-nav { display: flex; gap: 6px; }
.nav-btn { padding: 6px 12px; border-radius: 8px; border: 1px solid #e2e8f0; background: #fff; font-size: 11px; font-weight: 800; color: #64748b; transition: 0.2s; text-decoration: none; }
.nav-btn:hover:not(.disabled) { border-color: var(--primary); color: var(--primary); background: #eff6ff; }
.nav-btn.active { background: var(--primary); color: #fff; border-color: var(--primary); }
.nav-btn.disabled { opacity: 0.4; cursor: not-allowed; pointer-events: none; }

.lr-id { color: var(--primary); font-weight: 900; font-family: monospace; font-size: 14px; text-decoration: none; border-bottom: 1px dashed transparent; }
.lr-id:hover { border-bottom-color: var(--primary); }

.btn-action { width: 36px; height: 36px; border-radius: 10px; border: 1.5px solid var(--border); background: #fff; color: var(--text-muted); display: flex; align-items: center; justify-content: center; transition: 0.2s; }
.btn-action:hover { background: #eff6ff; color: var(--primary); border-color: var(--primary); transform: translateY(-1px); }
.btn-danger:hover { background: #fef2f2; color: #ef4444; border-color: #ef4444; }

/* Premium Modal Styles */
.modal-overlay { position:fixed; inset:0; background:rgba(15,23,42,0.6); display:none; align-items:center; justify-content:center; z-index:9999; backdrop-filter:blur(4px); padding: 20px; }
.modal-overlay.show { display:flex; }
.modal-content { background:white; width: 100%; max-width: 750px; max-height: 90vh; border-radius: 32px; padding: 40px; position: relative; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); display: flex; flex-direction: column; overflow: hidden; animation: slideUp 0.3s ease; }
@keyframes slideUp { from{opacity:0; transform:translateY(20px);} to{opacity:1; transform:translateY(0);} }
.modal-body { overflow-y: auto; padding-right: 8px; flex: 1; }

.info-label { font-size:10px; font-weight:800; color:#94a3b8; text-transform:uppercase; display:block; margin-bottom:4px; letter-spacing:0.05em; }
.info-value { font-size:14px; font-weight:700; color:#1e293b; display:block; margin-bottom:18px; }

.btn-close { position: absolute; top: 24px; right: 24px; width: 40px; height: 40px; border-radius: 12px; border: 1px solid var(--border); background: #fff; cursor: pointer; display: flex; align-items: center; justify-content: center; color: #94a3b8; transition: 0.2s; z-index: 10; }
.btn-close:hover { background: #fef2f2; border-color: #fecaca; color: #ef4444; }

.type-id-tag { background: #eff6ff; color: #2563eb; padding: 2px 8px; border-radius: 6px; font-size: 10px; font-family: monospace; font-weight: 800; border: 1px solid #dbeafe; }

.btn-modal-primary { background: #000; color: white; padding: 14px 24px; border-radius: 16px; font-weight: 900; font-size: 14px; transition: 0.2s; text-align: center; display: block; width: 100%; text-transform: uppercase; letter-spacing: 0.05em; border: none; cursor: pointer; }
.btn-modal-primary:hover:not(:disabled) { background: var(--primary); transform: translateY(-1px); box-shadow: 0 4px 12px rgba(37, 99, 235, 0.2); }
.btn-modal-primary:disabled { opacity: 0.3; cursor: not-allowed; filter: grayscale(1); }

/* Updated: Standard Light Button for Cancel as per Directory style */
.btn-modal-secondary { background: #f1f5f9; color: #64748b; padding: 14px 24px; border-radius: 16px; font-weight: 800; font-size: 14px; transition: 0.2s; text-align: center; display: block; width: 100%; text-transform: uppercase; border: none; cursor: pointer; }
.btn-modal-secondary:hover { background: #e2e8f0; color: #1e293b; }

.dynamic-meta-container { background: #f8fafc; border: 1px solid var(--border); border-radius: 16px; padding: 20px; margin-top: 10px; margin-bottom: 24px; }
</style>
</head>

<body class="flex">
<jsp:include page="sidebar.jsp" />

<main class="ml-20 lg:ml-64 min-h-screen flex-1 transition-all duration-300">
    <jsp:include page="topbar.jsp" />

    <div class="pageWrap">
        <div class="flex justify-between items-end mb-6">
            <div class="title-area">
                <h2 class="title">My Leave History</h2>
                <span class="sub-label">View and audit your previous leave applications.</span>
            </div>
        </div>

        <% if (dbError != null) { %><div id="statusAlert" class="bg-red-50 text-red-600 p-4 rounded-2xl mb-6 text-sm font-bold border border-red-100 uppercase transition-opacity duration-500"><i class="fas fa-exclamation-circle mr-2"></i> <%= dbError %></div><% } %>

        <form action="<%=request.getContextPath()%>/LeaveHistory" method="get" class="filter-card">
            <input type="hidden" name="p" value="1">
            <div class="filter-group">
                <label>Status</label>
                <%-- Automatic submit on change + all 5 status --%>
                <select name="status" onchange="this.form.submit()">
                    <option value="ALL" <%= currentStatus.equals("ALL")?"selected":"" %>>All Statuses</option>
                    <option value="PENDING" <%= currentStatus.equals("PENDING")?"selected":"" %>>Pending Approval</option>
                    <option value="APPROVED" <%= currentStatus.equals("APPROVED")?"selected":"" %>>Approved</option>
                    <option value="REJECTED" <%= currentStatus.equals("REJECTED")?"selected":"" %>>Rejected</option>
                    <option value="CANCELLED" <%= currentStatus.equals("CANCELLED")?"selected":"" %>>Cancelled</option>
                    <option value="CANCELLATION_REQUESTED" <%= currentStatus.equals("CANCELLATION_REQUESTED")?"selected":"" %>>Cancellation Requested</option>
                </select>
                <label class="ml-4">Year</label>
                <select name="year" onchange="this.form.submit()">
                    <option value="">All Years</option>
                    <% for(String yr : years) { %><option value="<%=yr%>" <%= yr.equals(currentYear)?"selected":"" %>><%=yr%></option><% } %>
                </select>
            </div>
            <div class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Total Records: <%= totalRecords %></div>
        </form>

        <div class="table-card">
            <table>
                <thead>
                    <tr>
                        <th>Record ID</th>
                        <th>Leave Category</th>
                        <th>Inclusive Dates</th>
                        <th>Days</th>
                        <th>Status</th>
                        <th>Applied On</th>
                        <th style="text-align:right">Action</th>
                    </tr>
                </thead>
                <tbody>
                <% if (leaves.isEmpty()) { %>
                    <tr><td colspan="7" class="py-24 text-center text-slate-300 font-bold uppercase text-xs italic tracking-widest">No matching history records found.</td></tr>
                <% } else {
                    for (Map<String, Object> l : leaves) {
                        String code = (String) l.get("status"); 
                        String badgeCls = "status-pending";
                        if ("APPROVED".equalsIgnoreCase(code)) badgeCls = "status-approved";
                        else if ("REJECTED".equalsIgnoreCase(code)) badgeCls = "status-rejected";
                        else if ("CANCELLED".equalsIgnoreCase(code)) badgeCls = "status-cancelled";
                        else if ("CANCELLATION_REQUESTED".equalsIgnoreCase(code)) badgeCls = "status-cancellation-requested";

                        String startDisplay = "-", endDisplay = "-", appliedDisplay = "-";
                        String evtDisp = "N/A", disDisp = "N/A";
                        boolean isStartedOrPassed = false;
                        try {
                            Date sD = (String.valueOf(l.get("start")).contains("-")) ? sdfDb.parse(String.valueOf(l.get("start"))) : sdfDisplay.parse(String.valueOf(l.get("start")));
                            Date eD = (String.valueOf(l.get("end")).contains("-")) ? sdfDb.parse(String.valueOf(l.get("end"))) : sdfDisplay.parse(String.valueOf(l.get("end")));
                            Date aD = (String.valueOf(l.get("appliedOn")).contains("-")) ? sdfTimeDb.parse(String.valueOf(l.get("appliedOn"))) : sdfTimeDisplay.parse(String.valueOf(l.get("appliedOn")));
                            
                            startDisplay = sdfDisplay.format(sD);
                            endDisplay = sdfDisplay.format(eD);
                            appliedDisplay = sdfTimeDisplay.format(aD);
                            
                            // FORMAT METADATA DATES TO DD/MM/YYYY
                            Object evtRaw = l.get("eventDate");
                            if (evtRaw != null && !String.valueOf(evtRaw).isEmpty()) {
                                Date eDt = (String.valueOf(evtRaw).contains("-")) ? sdfDb.parse(String.valueOf(evtRaw)) : sdfDisplay.parse(String.valueOf(evtRaw));
                                evtDisp = sdfDisplay.format(eDt);
                            }
                            
                            Object disRaw = l.get("dischargeDate");
                            if (disRaw != null && !String.valueOf(disRaw).isEmpty()) {
                                Date dDt = (String.valueOf(disRaw).contains("-")) ? sdfDb.parse(String.valueOf(disRaw)) : sdfDisplay.parse(String.valueOf(disRaw));
                                disDisp = sdfDisplay.format(dDt);
                            }

                            if (!todayMidnight.before(sD)) isStartedOrPassed = true;
                        } catch(Exception e) {}
                %>
                    <tr class="hover:bg-slate-50/50 transition-colors">
                        <td>
                            <a href="javascript:void(0)" class="lr-id" onclick="viewDetails(this)" 
                               data-id="<%= l.get("id") %>" 
                               data-idcode="#LR-<%= l.get("id") %>"
                               data-name="<%= userFullName %>" 
                               data-type="<%= l.get("type") %>"
                               data-start="<%= startDisplay %>" 
                               data-end="<%= endDisplay %>"
                               data-duration="<%= l.get("duration") %>" 
                               data-days="<%= l.get("totalDays") %>"
                               data-applied="<%= appliedDisplay %>" 
                               data-reason="<%= l.get("reason") %>"
                               data-comment="<%= (l.get("managerComment") != null) ? l.get("managerComment") : "-" %>"
                               data-attachment="<%= (Boolean.TRUE.equals(l.get("hasFile"))) ? "YES" : "" %>"
                               data-typeid="<%= l.get("leaveTypeId") %>"
                               data-med="<%= l.get("medicalFacility") %>"
                               data-ref="<%= l.get("refSerialNo") %>"
                               data-pre="<%= l.get("weekPregnancy") %>"
                               data-evt="<%= evtDisp %>"
                               data-dis="<%= disDisp %>"
                               data-cat="<%= l.get("emergencyCategory") %>"
                               data-cnt="<%= l.get("emergencyContact") %>"
                               data-spo="<%= l.get("spouseName") %>">
                                LR-<%= l.get("id") %>
                            </a>
                        </td>
                        <td class="font-black text-slate-700 uppercase"><%= l.get("type") %></td>
                        <td>
                            <span class="font-bold text-slate-700"><%= startDisplay %></span>
                            <% if(!startDisplay.equals(endDisplay)) { %><span class="text-[11px] text-slate-500 block font-bold uppercase tracking-tight">to <%= endDisplay %></span><% } %>
                        </td>
                        <td class="font-black text-blue-600 text-base"><%= l.get("totalDays") %></td>
                        <td><span class="badge <%= badgeCls %>"><span class="w-1.5 h-1.5 rounded-full bg-current"></span> <%= code.replace("_", " ") %></span></td>
                        <td class="text-slate-600 text-[12px] font-bold"><%= appliedDisplay %></td>
                        <td>
                            <div class="flex gap-2 justify-end">
                                <% if ("PENDING".equalsIgnoreCase(code)) { %>
                                    <button class="btn-action" onclick="openEditModal('<%= l.get("id") %>')"><%= EditIcon("w-4 h-4") %></button>
                                    <button class="btn-action btn-danger" onclick="askConfirm('DELETE', '<%= l.get("id") %>', '#LR-<%= l.get("id") %>')"><%= TrashIcon("w-4 h-4") %></button>
                                <% } else if ("APPROVED".equalsIgnoreCase(code)) { %>
                                    <% if (!isStartedOrPassed) { %>
                                        <button class="btn-action text-orange-500" onclick="askConfirm('REQ_CANCEL', '<%= l.get("id") %>', '#LR-<%= l.get("id") %>')"><%= RotateCcwIcon("w-4 h-4") %></button>
                                    <% } else { %>
                                        <span class="text-[11px] font-black text-slate-500 uppercase tracking-widest">Locked</span>
                                    <% } %>
                                <% } else { %>
                                    <span class="text-[11px] font-black text-slate-500 uppercase tracking-widest">Archive</span>
                                <% } %>
                            </div>
                        </td>
                    </tr>
                <% } } %>
                </tbody>
            </table>

            <!-- PAGINATION FOOTER -->
            <div class="pagination-container">
                <div class="pagination-info">
                    Showing <%= totalRecords == 0 ? 0 : startIdx + 1 %> to <%= endIdx %> of <%= totalRecords %> entries
                </div>
                <div class="pagination-nav">
                    <% 
                       String baseUrl = request.getContextPath() + "/LeaveHistory?status=" + currentStatus + "&year=" + currentYear;
                    %>
                    <a href="<%= baseUrl %>&p=<%= currentPage - 1 %>" class="nav-btn <%= currentPage == 1 ? "disabled" : "" %>">Previous</a>
                    <% for(int i=1; i<=totalPages; i++) { %>
                        <a href="<%= baseUrl %>&p=<%= i %>" class="nav-btn <%= currentPage == i ? "active" : "" %>"><%= i %></a>
                    <% } %>
                    <a href="<%= baseUrl %>&p=<%= currentPage + 1 %>" class="nav-btn <%= currentPage == totalPages || totalPages == 0 ? "disabled" : "" %>">Next</a>
                </div>
            </div>
        </div>
    </div>
</main>

<!-- DETAIL POPUP MODAL -->
<div class="modal-overlay" id="detailModal">
    <div class="modal-content">
        <button type="button" class="btn-close" onclick="closeModal('detailModal')"><%= XCircleIcon("w-6 h-6") %></button>
        <div class="modal-body">
            <h3 class="text-2xl font-black text-slate-800 tracking-tight uppercase mb-8 pr-12 border-b border-slate-100 pb-4">Application Details</h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-x-12">
                <div class="info-item">
                    <span class="info-label">Staff Name</span>
                    <span class="info-value" id="popName"></span>
                </div>
                <div class="info-item">
                    <span class="info-label">Record ID</span>
                    <span class="info-value" id="popId"></span>
                </div>
            </div>

            <div class="info-item">
                <span class="info-label">Leave Category</span>
                <div class="flex items-center gap-3">
                    <span class="info-value text-blue-600 mb-0" id="popType"></span>
                    <span id="popTypeIdTag" class="type-id-tag"></span>
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
                            <span class="text-red-500"><%= FilePlusIcon("w-5 h-5") %> </span>
                            VIEW DOCUMENT 
                            <span class="opacity-20"><%= ExternalLinkIcon("w-3 h-3") %></span>
                        </a>
                    </div>
                    <div id="noAttachLabel" class="text-xs text-slate-300 font-bold italic py-2">No document attached</div>
                </div>
            </div>

            <div class="info-item">
                <span class="info-label">Employee Reason</span>
                <p class="text-sm text-slate-500 mb-6 bg-slate-50 p-5 rounded-2xl border border-slate-100 font-medium leading-relaxed italic" id="popReason"></p>
            </div>

            <div id="dynamicBox" class="hidden">
                <div class="flex items-center gap-3 mb-4">
                    <div class="w-1 h-4 bg-blue-600 rounded-full"></div>
                    <h4 class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Metadata Attributes (Specific To Type)</h4>
                </div>
                <div class="dynamic-meta-container space-y-4" id="dynamicGrid"></div>
            </div>

            <div class="info-item">
                <span class="info-label">Administrative Remark</span>
                <p class="text-sm text-blue-600 italic font-semibold" id="popComment"></p>
            </div>
        </div>
    </div>
</div>

<!-- EDIT MODAL -->
<div class="modal-overlay" id="editOverlay">
    <div class="modal-content" style="max-width: 550px;">
        <button type="button" class="btn-close" onclick="closeModal('editOverlay')"><%= XCircleIcon("w-6 h-6") %></button>
        <div class="modal-body">
            <h3 class="text-2xl font-black text-slate-800 tracking-tight uppercase mb-8 pr-12 border-b border-slate-100 pb-4">Edit Application</h3>
            
            <form id="editForm" class="space-y-6">
                <input type="hidden" name="leaveId" id="editLeaveId">
                
                <div class="form-group">
                    <label class="info-label">Leave Category</label>
                    <select name="leaveType" id="editType" class="w-full pointer-events-none bg-slate-50 text-slate-400"></select>
                </div>

                <div class="grid grid-cols-2 gap-6">
                    <div class="form-group">
                        <label class="info-label">Start Date</label>
                        <input type="date" name="startDate" id="editStart" class="w-full p-2 border rounded-xl" onchange="validateEdit()">
                    </div>
                    <div class="form-group">
                        <label class="info-label">End Date</label>
                        <input type="date" name="endDate" id="editEnd" class="w-full p-2 border rounded-xl" onchange="validateEdit()">
                    </div>
                </div>

                <div class="form-group">
                    <label class="info-label">Duration Type</label>
                    <select name="duration" id="editDuration" class="w-full" onchange="validateEdit()">
                        <option value="FULL_DAY">Full Day</option>
                        <option value="HALF_DAY_AM">Half Day (AM)</option>
                        <option value="HALF_DAY_PM">Half Day (PM)</option>
                    </select>
                </div>

                <div class="form-group">
                    <label class="info-label">Personal Reason</label>
                    <textarea name="reason" id="editReason" class="w-full h-24 border rounded-xl p-3" placeholder="Briefly explain the reason for leave..."></textarea>
                </div>
                
                <div id="editValidationError" class="text-[10px] font-black text-red-500 uppercase tracking-widest hidden"></div>

                <div class="flex gap-4 mt-8">
                    <button type="button" class="btn-modal-secondary flex-1" onclick="closeModal('editOverlay')">Discard</button>
                    <button type="submit" id="editSubmitBtn" class="btn-modal-primary flex-1">Update Application</button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- CONFIRMATION MODAL -->
<div class="modal-overlay" id="confirmOverlay">
    <div class="modal-content" style="max-width: 450px; text-align: center;">
        <button type="button" class="btn-close" onclick="closeModal('confirmOverlay')"><%= XCircleIcon("w-6 h-6") %></button>
        <div class="modal-body">
            <div id="confIcon" class="mx-auto mb-6"></div>
            <h3 id="confTitle" class="text-xl font-black text-slate-800 tracking-tight uppercase mb-2">Confirm Action</h3>
            <p id="confMsg" class="text-slate-500 font-medium mb-10 text-sm leading-relaxed"></p>
            
            <form id="confForm">
                <input type="hidden" name="id" id="confId">
                <div class="flex gap-4">
                    <button type="button" class="btn-modal-secondary flex-1" onclick="closeModal('confirmOverlay')">Cancel</button>
                    <button type="submit" id="confBtn" class="btn-modal-primary flex-1">Confirm</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
const CTX = "<%=request.getContextPath()%>";
let activeBalance = 0; 
let originalDays = 0; // Added: Track the original duration to recalculate allowed balance

window.addEventListener('DOMContentLoaded', () => {
    // Auto-dismiss alert messages
    const alert = document.getElementById('statusAlert');
    if (alert) {
        setTimeout(() => {
            alert.style.opacity = '0';
            setTimeout(() => alert.remove(), 500);
        }, 3000);
    }
});

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
    document.getElementById('popComment').textContent = d.comment && d.comment !== "-" ? d.comment : "Pending Review.";

    const tag = document.getElementById('popTypeIdTag');
    if(d.typeid && d.typeid !== "null") {
        tag.textContent = "ID: " + d.typeid;
        tag.style.display = 'inline-block';
    } else {
        tag.style.display = 'none';
    }

    const abox = document.getElementById('attachBox');
    const noAttach = document.getElementById('noAttachLabel');
    if(d.attachment === "YES") {
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
        if(val && val !== "null" && val !== "" && val !== "undefined" && val !== "N/A") {
            grid.innerHTML += '<div class="info-item border-b border-slate-100 pb-2 flex justify-between items-center"><span class="info-label text-slate-400 mb-0 font-bold uppercase">'+label+'</span><span class="info-value mb-0 text-slate-600 font-black text-xs">'+val+'</span></div>';
            count++;
        }
    };

    const typeCode = (d.type || "").toUpperCase();
    let facilityLabel = "Facility Name";
    let eventLabel = "Date of Event";

    if (typeCode.includes("SICK")) facilityLabel = "Clinic / Hospital Name";
    else if (typeCode.includes("HOSPITAL")) { facilityLabel = "Hospital Facility"; eventLabel = "Admission Date"; }
    else if (typeCode.includes("MATERNITY")) { facilityLabel = "Consultation Clinic"; eventLabel = "Expected Due Date"; }
    else if (typeCode.includes("PATERNITY")) { facilityLabel = "Hospital Location"; eventLabel = "Delivery Date"; }

    addAttr(facilityLabel, d.med);
    addAttr("MC Serial No", d.ref);
    addAttr(eventLabel, d.evt);
    addAttr("Discharge Date", d.dis);
    addAttr("Pregnancy Weeks", d.pre);
    addAttr("Emergency Category", d.cat);
    addAttr("Emergency Contact", d.cnt);
    addAttr("Spouse Name", d.spo);

    dBox.classList.toggle('hidden', count === 0);
    document.getElementById('detailModal').classList.add('show');
}

function closeModal(id) { document.getElementById(id).classList.remove('show'); }

async function openEditModal(id) {
    document.getElementById('editOverlay').classList.add('show');
    try {
        const res = await fetch(CTX + "/EditLeave?id=" + id, { headers: {'Accept': 'application/json'} });
        const data = await res.json();
        
        activeBalance = parseFloat(data.balance) || 0; 
        const oStart = new Date(data.startDate);
        const oEnd = new Date(data.endDate);
        if (data.duration.startsWith('HALF_DAY')) {
            originalDays = 0.5;
        } else {
            originalDays = estimateWorkingDays(oStart, oEnd);
        }

        document.getElementById('editLeaveId').value = data.leaveId;
        document.getElementById('editStart').value = data.startDate;
        document.getElementById('editEnd').value = data.endDate;
        document.getElementById('editReason').value = data.reason || "";
        
        let dur = data.duration || "FULL_DAY";
        if(dur === 'HALF_DAY') dur = data.halfSession === 'PM' ? 'HALF_DAY_PM' : 'HALF_DAY_AM';
        document.getElementById('editDuration').value = dur;
        
        const ts = document.getElementById('editType');
        ts.innerHTML = "";
        data.leaveTypes.forEach(t => {
            let o = new Option(t.label || t.code, t.value || t.id);
            if(o.value == data.leaveTypeId) o.selected = true;
            ts.add(o);
        });

        validateEdit(); 
    } catch (e) { closeModal('editOverlay'); }
}

function estimateWorkingDays(start, end) {
    if (end < start) return 0;
    let count = 0;
    let cur = new Date(start);
    while (cur <= end) {
        const day = cur.getDay();
        if (day !== 0 && day !== 6) count++;
        cur.setDate(cur.getDate() + 1);
    }
    return count;
}

function validateEdit() {
    const sStr = document.getElementById('editStart').value;
    const eStr = document.getElementById('editEnd').value;
    const durType = document.getElementById('editDuration').value;
    const btn = document.getElementById('editSubmitBtn');
    const err = document.getElementById('editValidationError');
    
    if (!sStr || !eStr) return;

    const start = new Date(sStr);
    const end = new Date(eStr);
    
    let newDays = 0;
    if (durType.startsWith('HALF_DAY')) {
        newDays = 0.5;
    } else {
        newDays = estimateWorkingDays(start, end);
    }

    let errorMsg = "";
    let isInvalid = false;
    const maxAllowed = activeBalance + originalDays;

    if (end < start) {
        errorMsg = "End date cannot be earlier than start date.";
        isInvalid = true;
    } else if (newDays === 0) {
        errorMsg = "Selected dates fall on weekends.";
        isInvalid = true;
    } else if (newDays > maxAllowed) {
        errorMsg = "Insufficient balance. Allowed (including this record): " + maxAllowed + " days. Requested: " + newDays;
        isInvalid = true;
    }

    if (isInvalid) {
        err.textContent = errorMsg;
        err.classList.remove('hidden');
        btn.disabled = true;
    } else {
        err.classList.add('hidden');
        btn.disabled = false;
    }
}

document.getElementById('editForm').onsubmit = async function(e) {
    e.preventDefault();
    const btn = document.getElementById('editSubmitBtn');
    btn.disabled = true;
    btn.textContent = "WAIT...";
    const fd = new URLSearchParams(new FormData(this));
    const d = fd.get('duration');
    if (d.startsWith('HALF_DAY')) { fd.set('duration', 'HALF_DAY'); fd.set('halfSession', d.includes('AM') ? 'AM' : 'PM'); }
    try {
        const res = await fetch(CTX + "/EditLeave", { method: 'POST', body: fd, headers: {'Content-Type': 'application/x-www-form-urlencoded'} });
        const txt = await res.text();
        if (txt.trim() === "OK") {
            window.location.reload();
        } else {
            const err = document.getElementById('editValidationError');
            err.textContent = txt;
            err.classList.remove('hidden');
            btn.disabled = false;
            btn.textContent = "UPDATE APPLICATION";
        }
    } catch (err) {
        btn.disabled = false;
        btn.textContent = "UPDATE APPLICATION";
    }
};

function askConfirm(action, id, recordId) {
    const t = document.getElementById('confTitle');
    const m = document.getElementById('confMsg');
    const f = document.getElementById('confForm');
    const b = document.getElementById('confBtn');
    const ic = document.getElementById('confIcon');
    document.getElementById('confId').value = id;

    if(action === 'DELETE') {
        t.innerText = "DELETE RECORD?";
        m.innerHTML = "Are you sure you want to delete <b class='text-slate-900'>" + recordId + "</b>? This pending leave application will be removed permanently.";
        f.dataset.action = CTX + "/DeleteLeave";
        b.className = "btn-modal-primary flex-1 bg-red-600 hover:bg-red-700 shadow-red-100";
        ic.innerHTML = `<div class='w-20 h-20 bg-red-50 rounded-full flex items-center justify-center text-red-500 text-3xl mx-auto shadow-inner'><%= TrashIcon("w-10 h-10") %></div>`;
    } else {
        t.innerText = "REQUEST CANCELLATION?";
        m.innerHTML = "Are you sure you want to request cancellation for <b class='text-slate-900'>" + recordId + "</b>? This will require manager approval.";
        f.dataset.action = CTX + "/CancelLeave";
        b.className = "btn-modal-primary flex-1 bg-orange-600 hover:bg-orange-700 shadow-orange-100";
        ic.innerHTML = `<div class='w-20 h-20 bg-orange-50 rounded-full flex items-center justify-center text-orange-500 text-3xl mx-auto shadow-inner'><%= RotateCcwIcon("w-10 h-10") %></div>`;
    }
    document.getElementById('confirmOverlay').classList.add('show');
}

document.getElementById('confForm').onsubmit = async function(e) {
    e.preventDefault();
    const btn = document.getElementById('confBtn');
    btn.disabled = true;
    btn.textContent = "WAIT...";
    try {
        const res = await fetch(this.dataset.action, { method: 'POST', body: new URLSearchParams(new FormData(this)), headers: {'Content-Type': 'application/x-www-form-urlencoded'} });
        if (res.ok && (await res.text()).trim() === "OK") window.location.reload();
    } catch (err) {
        btn.disabled = false;
        btn.textContent = "CONFIRM";
    }
};

window.onclick = (e) => { 
    if (e.target.classList.contains('modal-overlay')) {
        closeModal(e.target.id);
    }
}

document.addEventListener('input', function(e) {
    if(e.target.tagName === 'TEXTAREA' || (e.target.tagName === 'INPUT' && e.target.type === 'text')) {
        e.target.value = e.target.value.toUpperCase();
    }
});
</script>
</body>
</html>