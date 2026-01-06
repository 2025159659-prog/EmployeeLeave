<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ include file="icon.jsp" %>

<%
    // ADMIN GUARD
    HttpSession ses = request.getSession(false);
    if (ses == null || ses.getAttribute("empid") == null || !"ADMIN".equalsIgnoreCase(String.valueOf(ses.getAttribute("role")))) {
        response.sendRedirect("login.jsp"); return;
    }

    List<Map<String, Object>> history = (List<Map<String, Object>>) request.getAttribute("history");
    List<String> years = (List<String>) request.getAttribute("years");
    
    String currentStatus = request.getParameter("status") != null ? request.getParameter("status") : "ALL";
    String currentYear = request.getParameter("year") != null ? request.getParameter("year") : "";
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Admin | All Leave History</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&display=swap" rel="stylesheet">

    <style>
        :root { --bg:#f8fafc; --card:#ffffff; --border:#e2e8f0; --text:#1e293b; --primary:#2563eb; }
        body { margin:0; font-family: 'Inter', sans-serif; background:var(--bg); color:var(--text); }
        
        .pageWrap { padding: 32px 40px; max-width: 1500px; margin: 0 auto; }
        
        /* Table Design */
        .card { background:var(--card); border:1px solid var(--border); border-radius:24px; box-shadow:0 4px 6px -1px rgba(0,0,0,0.05); overflow:hidden; }
        table { width:100%; border-collapse:collapse; }
        th, td { border-bottom:1px solid #f1f5f9; padding:18px; text-align:left; vertical-align:middle; }
        th { background:#f8fafc; font-size:11px; text-transform:uppercase; color:#64748b; font-weight:800; letter-spacing:0.05em; }

        /* Badges */
        .badge { padding: 5px 12px; border-radius: 20px; font-size: 10px; font-weight: 700; display: inline-flex; align-items: center; gap: 6px; text-transform: uppercase; }
        .status-pending { background: #fffbeb; color: #b45309; border: 1px solid #fde68a; } 
        .status-approved { background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; } 
        .status-rejected { background: #fef2f2; color: #b91c1c; border: 1px solid #fecaca; } 
        .status-cancelled { background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0; } 
        .status-cancellation-requested { background: #fff7ed; color: #c2410c; border: 1px solid #fdba74; }

        /* Modal */
        .modal-overlay { position:fixed; inset:0; background:rgba(15,23,42,0.6); display:none; align-items:center; justify-content:center; z-index:9999; backdrop-filter:blur(4px); padding: 20px; }
        .modal-overlay.show { display:flex; }
        .modal-content { background:white; width:100%; max-width:700px; border-radius:32px; padding:40px; position: relative; animation: slideUp 0.3s ease; }
        @keyframes slideUp { from{opacity:0; transform:translateY(20px);} to{opacity:1; transform:translateY(0);} }
        
        .modal-body { max-height: 80vh; overflow-y: auto; padding-right: 8px; }
        .modal-body::-webkit-scrollbar { width: 4px; }
        .modal-body::-webkit-scrollbar-thumb { background: #e2e8f0; border-radius: 10px; }

        .info-label { font-size:10px; font-weight:800; color:#94a3b8; text-transform:uppercase; display:block; margin-bottom:4px; letter-spacing:0.05em; }
        .info-value { font-size:14px; font-weight:700; color:#1e293b; display:block; margin-bottom:18px; }

        .btn-close { position: absolute; top: 24px; right: 24px; width: 40px; height: 40px; border-radius: 12px; border: 1px solid var(--border); background: #fff; cursor: pointer; display: flex; align-items: center; justify-content: center; color: #94a3b8; transition: 0.2s; }
        .btn-close:hover { background: #fef2f2; border-color: #fecaca; color: #ef4444; }

        .dynamic-meta-container { background: #f8fafc; border: 1px solid var(--border); border-radius: 16px; padding: 20px; margin-top: 10px; margin-bottom: 24px; }

        select { padding: 10px 16px; border-radius: 12px; border: 1px solid var(--border); outline: none; font-size: 14px; font-weight: 600; cursor: pointer; }
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
                    <h2 class="text-3xl font-black text-slate-800 tracking-tight uppercase">LEAVE HISTORY</h2>
                    <p class="text-slate-400 font-bold text-sm mt-1 uppercase tracking-widest">Global Workforce Records</p>
                </div>
                <div class="bg-slate-100 px-4 py-2 rounded-xl text-xs font-black text-slate-500">
                    Total Records: <%= (history != null ? history.size() : 0) %>
                </div>
            </div>

            <!-- Filter Section -->
            <form action="leaveEmpHistoryServlet" method="get" class="bg-white p-6 rounded-[2rem] border border-slate-200 mb-8 flex flex-wrap items-center gap-6 shadow-sm">
                <div class="flex flex-col gap-1">
                    <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Status Filter</label>
                    <select name="status">
                        <option value="ALL" <%= "ALL".equals(currentStatus)?"selected":"" %>>All Statuses</option>
                        <option value="PENDING" <%= "PENDING".equals(currentStatus)?"selected":"" %>>Pending</option>
                        <option value="APPROVED" <%= "APPROVED".equals(currentStatus)?"selected":"" %>>Approved</option>
                        <option value="REJECTED" <%= "REJECTED".equals(currentStatus)?"selected":"" %>>Rejected</option>
                        <option value="CANCELLED" <%= "CANCELLED".equals(currentStatus)?"selected":"" %>>Cancelled</option>
                        <option value="CANCELLATION_REQUESTED" <%= "CANCELLATION_REQUESTED".equals(currentStatus)?"selected":"" %>>Cancellation Requested</option>
                    </select>
                </div>

                <div class="flex flex-col gap-1">
                    <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Year</label>
                    <select name="year">
                        <option value="">All Years</option>
                        <% for(String yr : years) { %>
                            <option value="<%=yr%>" <%= yr.equals(currentYear)?"selected":"" %>><%=yr%></option>
                        <% } %>
                    </select>
                </div>

                <button type="submit" class="mt-5 bg-blue-600 text-white px-8 py-3 rounded-xl font-black text-xs uppercase tracking-widest hover:bg-blue-700 transition-all shadow-lg shadow-blue-100">
                    Apply Filter
                </button>
            </form>

            <!-- Table Section -->
            <div class="card">
                <div class="overflow-x-auto">
                    <table>
                        <thead>
                            <tr>
                                <th>Employee</th>
                                <th>Type</th>
                                <th>Dates</th>
                                <th>Days</th>
                                <th>Status</th>
                                <th style="text-align:right">Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (history == null || history.isEmpty()) { %>
                                <tr><td colspan="6" class="text-center py-20 text-slate-300 font-bold uppercase text-xs italic tracking-widest">No history records found.</td></tr>
                            <% } else { for (Map<String, Object> r : history) { 
                                String status = (String) r.get("status");
                                String badgeClass = "status-pending";
                                if ("APPROVED".equalsIgnoreCase(status)) badgeClass = "status-approved";
                                else if ("REJECTED".equalsIgnoreCase(status)) badgeClass = "status-rejected";
                                else if ("CANCELLED".equalsIgnoreCase(status)) badgeClass = "status-cancelled";
                                else if ("CANCELLATION_REQUESTED".equalsIgnoreCase(status)) badgeClass = "status-cancellation-requested";
                            %>
                                <tr class="hover:bg-slate-50 transition-colors">
                                    <td>
                                        <div class="font-black text-slate-800"><%= r.get("fullname") %></div>
                                        <div class="text-[10px] text-slate-400 font-bold uppercase tracking-tighter">ID: <%= r.get("empCode") %></div>
                                    </td>
                                    <td><span class="bg-slate-100 text-slate-500 px-3 py-1 rounded-lg text-[9px] font-black uppercase border border-slate-200"><%= r.get("type") %></span></td>
                                    <td class="text-xs font-bold text-slate-600"><%= r.get("start") %> — <%= r.get("end") %></td>
                                    <td class="font-black text-blue-600 text-sm"><%= r.get("days") %></td>
                                    <td>
                                        <span class="badge <%= badgeClass %>">
                                            <span class="w-1.5 h-1.5 rounded-full bg-current"></span> <%= status.replace("_", " ") %>
                                        </span>
                                    </td>
                                    <td style="text-align:right">
                                        <button onclick="viewDetails(this)" class="bg-white border border-slate-200 text-slate-600 px-5 py-2 rounded-xl text-[10px] font-black hover:bg-slate-900 hover:text-white transition-all uppercase tracking-widest shadow-sm"
                                                data-id="<%= r.get("id") %>"
                                                data-name="<%= r.get("fullname") %>" data-idcode="<%= r.get("empCode") %>"
                                                data-type="<%= r.get("type") %>" data-start="<%= r.get("start") %>"
                                                data-end="<%= r.get("end") %>" data-days="<%= r.get("days") %>"
                                                data-duration="<%= r.get("duration") %>" data-applied="<%= r.get("appliedOn") %>"
                                                data-reason="<%= r.get("reason") %>" data-status="<%= status %>"
                                                data-attachment="<%= r.get("attachment") != null ? r.get("attachment") : "" %>"
                                                data-med="<%= r.get("medicalFacility") %>" data-ref="<%= r.get("refSerialNo") %>"
                                                data-evt="<%= r.get("eventDate") %>" data-dis="<%= r.get("dischargeDate") %>"
                                                data-cat="<%= r.get("emergencyCategory") %>" data-cnt="<%= r.get("emergencyContact") %>"
                                                data-spo="<%= r.get("spouseName") %>"
                                                data-comment="<%= r.get("adminComment") != null ? r.get("adminComment") : "-" %>">
                                            View
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

<!-- DETAIL POPUP MODAL -->
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
                <span class="info-value text-blue-600" id="popType"></span>
            </div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-x-12">
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

            <div class="info-item">
                <span class="info-label">Submission Date</span>
                <span class="info-value" id="popApplied"></span>
            </div>

            <div class="info-item">
                <span class="info-label">Employee Reason</span>
                <p class="text-sm text-slate-500 mb-6 bg-slate-50 p-5 rounded-2xl border border-slate-100 font-medium leading-relaxed" id="popReason"></p>
            </div>

            <!-- Metadata Extraction Container -->
            <div id="dynamicBox" class="hidden">
                <div class="flex items-center gap-3 mb-4">
                    <div class="w-1 h-4 bg-blue-600 rounded-full"></div>
                    <h4 class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Additional Attributes</h4>
                </div>
                <div class="dynamic-meta-container space-y-4" id="dynamicGrid"></div>
            </div>

            <!-- Attachment Section -->
            <div id="attachBox" class="mb-8 hidden">
                <span class="info-label">Document</span>
                <a id="modalAttachLink" href="#" target="_blank" class="inline-flex items-center gap-3 bg-white border-2 border-slate-100 px-5 py-3 rounded-2xl text-[11px] font-black text-slate-600 hover:border-blue-200 hover:text-blue-600 transition-all">
                    <i class="fas fa-file-medical text-red-500 text-lg"></i> VIEW ATTACHMENT <i class="fas fa-external-link-alt opacity-20 text-[9px]"></i>
                </a>
            </div>

            <div class="info-item">
                <span class="info-label">Administrative Remark</span>
                <p class="text-sm text-blue-600 italic font-semibold" id="popComment"></p>
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
        document.getElementById('popDuration').textContent = d.duration.replace(/_/g, ' ');
        document.getElementById('popDays').textContent = d.days;
        document.getElementById('popApplied').textContent = d.applied;
        document.getElementById('popReason').textContent = d.reason || "No reason provided.";
        document.getElementById('popComment').textContent = d.comment;

        // Attachment link logic
        const abox = document.getElementById('attachBox');
        if(d.attachment && d.attachment !== "") {
            abox.classList.remove('hidden');
            // Assuming the ViewAttachment uses the same ID parameter as the employee view
            document.getElementById('modalAttachLink').href = CTX + "/ViewAttachment?id=" + d.id;
        } else { 
            abox.classList.add('hidden'); 
        }

        // Dynamic Attributes Logic
        const dBox = document.getElementById('dynamicBox');
        const grid = document.getElementById('dynamicGrid');
        grid.innerHTML = "";
        let count = 0;
        const addAttr = (label, val) => {
            if(val && val !== "null" && val !== "" && val !== "undefined") {
                grid.innerHTML += '<div class="info-item border-b border-slate-100 pb-2"><span class="info-label text-slate-400">'+label+'</span><span class="info-value mb-0 text-slate-600 font-bold">'+val+'</span></div>';
                count++;
            }
        };
        addAttr("Medical Facility Name", d.med);
        addAttr("MC Serial No", d.ref);
        addAttr("Event Date", d.evt);
        addAttr("Discharge Date", d.dis);
        addAttr("Emergency Category", d.cat);
        addAttr("Emergency Phone", d.cnt);
        addAttr("Spouse Name", d.spo);

        dBox.classList.toggle('hidden', count === 0);

        document.getElementById('detailModal').classList.add('show');
    }

    function closeModal() {
        document.getElementById('detailModal').classList.remove('show');
    }
</script>

</body>
</html>
