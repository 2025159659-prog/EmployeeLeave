<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<%
    // =========================
    // SECURITY GUARD - MANAGER ONLY
    // =========================
    HttpSession ses = request.getSession(false);
    if (ses == null || ses.getAttribute("empid") == null || !"MANAGER".equalsIgnoreCase(String.valueOf(ses.getAttribute("role")))) {
        response.sendRedirect("login.jsp?error=Access+Denied"); return;
    }

    List<Map<String, Object>> leaves = (List<Map<String, Object>>) request.getAttribute("leaves");
    Integer pendingCount = (Integer) request.getAttribute("pendingCount");
    Integer cancelReqCount = (Integer) request.getAttribute("cancelReqCount");
    String msg = request.getParameter("msg");
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manager Dashboard | Review Console</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        :root { --bg:#f8fafc; --card:#ffffff; --border:#e2e8f0; --text:#1e293b; --primary:#2563eb; --green:#10b981; --red:#ef4444; }
        body { margin:0; font-family: 'Inter', sans-serif; background:var(--bg); color:var(--text); overflow-x: hidden; }
        
        .content { padding:0; transition: 0.3s; }
        .pageWrap { padding: 32px 24px; }
        
        /* Stats Badges */
        .stat { background:var(--card); border:1px solid var(--border); border-radius:16px; padding:24px; display:flex; align-items:center; justify-content:space-between; border-left: 6px solid var(--primary); box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); }
        .stat.orange { border-left-color: #f97316; }
        
        /* Main Table Layout */
        .card { background:var(--card); border:1px solid var(--border); border-radius:24px; box-shadow:0 10px 15px -3px rgba(0,0,0,0.05); overflow:hidden; }
        table { width:100%; border-collapse:collapse; }
        th, td { border-bottom:1px solid #f1f5f9; padding:18px; text-align:left; vertical-align:middle; }
        th { background:#f8fafc; font-size:11px; text-transform:uppercase; color:#64748b; font-weight:800; letter-spacing:0.05em; }

        .badge { display:inline-block; font-size:10px; font-weight:700; padding:4px 12px; border-radius:999px; text-transform:uppercase; }
        .badge.pending { background:#fff7ed; color:#9a3412; border: 1px solid #fed7aa; }
        .badge.cancel { background:#fef2f2; color:#991b1b; border: 1px solid #fecaca; }

        /* MODAL FLOW: Updated to 800px */
        .modal-overlay { position:fixed; inset:0; background:rgba(15,23,42,0.6); display:none; align-items:center; justify-content:center; z-index:9999; backdrop-filter:blur(4px); padding: 20px; }
        .modal-overlay.show { display:flex; }
        .modal-content { background:white; width:100%; max-width:800px; border-radius:32px; padding:0; overflow:hidden; animation:slideUp 0.3s ease; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); position: relative; }
        @keyframes slideUp { from{opacity:0; transform:translateY(20px);} to{opacity:1; transform:translateY(0);} }
        
        .modal-body { padding: 40px; max-height: 85vh; overflow-y: auto; }
        
        .info-label { font-size:10px; font-weight:800; color:#94a3b8; text-transform:uppercase; display:block; margin-bottom:4px; letter-spacing:0.05em; }
        .info-value { font-size:14px; font-weight:700; color:#1e293b; display:block; margin-bottom:18px; }
        
        select, textarea { width:100%; border:1px solid #cbd5e1; border-radius:12px; padding:12px; font-size:14px; margin-top:8px; background:#fff; outline:none; transition:0.2s; }
        select:focus, textarea:focus { border-color: var(--primary); box-shadow: 0 0 0 4px rgba(37,99,235,0.1); }

        .btn-submit { width:100%; background:var(--primary); color:white; padding:16px; border-radius:14px; font-weight:800; margin-top:24px; text-transform:uppercase; cursor:pointer; border:none; transition:0.2s; letter-spacing: 0.1em; }
        .btn-submit:hover { background:#1d4ed8; transform:translateY(-1px); box-shadow: 0 10px 15px -3px rgba(37,99,235,0.3); }

        /* Close Button */
        .btn-close { position: absolute; top: 24px; right: 24px; width: 40px; height: 40px; border-radius: 12px; border: 1px solid var(--border); background: #fff; cursor: pointer; display: flex; align-items: center; justify-content: center; color: #94a3b8; transition: 0.2s; z-index: 10; }
        .btn-close:hover { background: #fef2f2; border-color: #fecaca; color: var(--red); }

        /* Metadata Container: Single column list */
        .dynamic-meta-container { background: #f8fafc; border: 1px solid var(--border); border-radius: 16px; padding: 20px; margin-top: 10px; margin-bottom: 24px; }
        
        /* Auto-hide Message box */
        #statusAlert { transition: opacity 0.5s ease-out, transform 0.5s ease-out; }
        #statusAlert.hide { opacity: 0; transform: translateY(-10px); pointer-events: none; }
    </style>
</head>
<body>
<div class="flex">
    <jsp:include page="sidebar.jsp" />
    <main class="ml-20 lg:ml-64 min-h-screen w-full transition-all duration-300">
        <jsp:include page="topbar.jsp" />
        
        <div class="pageWrap">
            <div class="flex justify-between items-center mb-10">
                <div>
                    <h2 class="text-3xl font-black text-slate-800 tracking-tight uppercase">REVIEW DASHBOARD</h2>
                    <p class="text-slate-400 font-bold text-sm mt-1 uppercase tracking-widest">Management Approval Console</p>
                </div>
                <span class="bg-blue-600 text-white px-5 py-2 rounded-2xl text-[11px] font-black uppercase tracking-widest shadow-lg shadow-blue-200">
                    <i class="fas fa-shield-alt mr-2"></i> Manager Access
                </span>
            </div>

            <!-- Success Message (Auto-dismisses) -->
            <% if (msg != null && !msg.isBlank()) { %>
                <div id="statusAlert" class="bg-emerald-50 border-2 border-emerald-100 text-emerald-700 p-5 rounded-2xl mb-8 flex items-center gap-4 font-black text-sm">
                    <div class="w-8 h-8 bg-emerald-500 text-white rounded-full flex items-center justify-center shrink-0"><i class="fas fa-check"></i></div>
                    <%= msg %>
                </div>
            <% } %>

            <!-- Dashboard Stats -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-8 mb-10">
                <div class="stat">
                    <div>
                        <span class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em]">New Applications</span>
                        <div class="text-4xl font-black text-slate-800 mt-2"><%= pendingCount %></div>
                    </div>
                    <div class="w-16 h-16 bg-blue-50 text-blue-500 rounded-2xl flex items-center justify-center shadow-inner"><i class="fas fa-file-signature fa-2x"></i></div>
                </div>
                <div class="stat orange">
                    <div>
                        <span class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em]">Cancellation Requests</span>
                        <div class="text-4xl font-black text-slate-800 mt-2"><%= cancelReqCount %></div>
                    </div>
                    <div class="w-16 h-16 bg-orange-50 text-orange-500 rounded-2xl flex items-center justify-center shadow-inner"><i class="fas fa-undo-alt fa-2x"></i></div>
                </div>
            </div>

            <!-- Task List Table -->
            <div class="card">
                <div class="p-6 border-b border-slate-100 flex justify-between items-center">
                    <span class="font-black text-slate-700 uppercase text-xs tracking-[0.15em]">Pending Workforce Requests</span>
                    <span class="text-[10px] font-bold text-slate-400"><%= (leaves!=null?leaves.size():0) %> ITEMS QUEUED</span>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full">
                        <thead>
                            <tr>
                                <th>Employee</th><th>Leave Type</th><th>Dates (Start - End)</th><th>Duration</th><th>Days</th><th>Status</th><th>Applied On</th><th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (leaves == null || leaves.isEmpty()) { %>
                                <tr><td colspan="8" class="text-center py-24 text-slate-300 font-bold tracking-widest uppercase text-xs italic">All Clear! No pending tasks in queue.</td></tr>
                            <% } else { for (Map<String, Object> r : leaves) { 
                                boolean isCancel = "CANCELLATION_REQUESTED".equals(r.get("status"));
                            %>
                                <tr class="hover:bg-slate-50/80 transition-colors">
                                    <td><div class="font-black text-slate-800"><%= r.get("fullname") %></div><div class="text-[10px] text-slate-400 font-bold uppercase tracking-tighter">ID: <%= r.get("empid") %></div></td>
                                    <td><span class="bg-slate-100 text-slate-500 px-3 py-1 rounded-lg text-[9px] font-black uppercase border border-slate-200"><%= r.get("leaveType") %></span></td>
                                    <td class="text-xs font-bold text-slate-600"><%= r.get("startDate") %> — <%= r.get("endDate") %></td>
                                    <td class="text-[9px] font-black uppercase text-slate-400 tracking-tighter"><%= r.get("duration") %></td>
                                    <td class="font-black text-blue-600 text-sm"><%= r.get("days") %></td>
                                    <td><span class="badge <%= isCancel ? "cancel" : "pending" %>"><%= r.get("status").toString().replace("_", " ") %></span></td>
                                    <td class="text-[10px] text-slate-400 font-bold"><%= r.get("appliedOn") %></td>
                                    <td>
                                        <button onclick="openReview(this)" class="bg-slate-900 text-white px-5 py-2.5 rounded-xl text-[10px] font-black hover:bg-blue-600 transition-all shadow-md shadow-slate-100 uppercase"
                                                data-id="<%= r.get("leaveId") %>" 
                                                data-name="<%= r.get("fullname") %>" 
                                                data-empid="<%= r.get("empid") %>"
                                                data-type="<%= r.get("leaveType") %>" 
                                                data-start="<%= r.get("startDate") %>"
                                                data-end="<%= r.get("endDate") %>"
                                                data-days="<%= r.get("days") %>" 
                                                data-duration="<%= r.get("duration") %>"
                                                data-applied="<%= r.get("appliedOn") %>"
                                                data-reason="<%= r.get("reason") %>" 
                                                data-status="<%= r.get("status") %>"
                                                data-attachment="<%= r.get("attachment") != null ? r.get("attachment") : "" %>"
                                                data-med="<%= r.get("medicalFacility") %>" 
                                                data-ref="<%= r.get("refSerialNo") %>"
                                                data-evt="<%= r.get("eventDate") %>" 
                                                data-dis="<%= r.get("dischargeDate") %>"
                                                data-cat="<%= r.get("emergencyCategory") %>" 
                                                data-cnt="<%= r.get("emergencyContact") %>"
                                                data-spo="<%= r.get("spouseName") %>">Review</button>
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

<!-- REVIEW MODAL -->
<div class="modal-overlay" id="reviewModal">
    <div class="modal-content">
        <button type="button" class="btn-close" onclick="closeReview()"><i class="fas fa-times"></i></button>
        <form action="ManagerLeaveActionServlet" method="post">
            <input type="hidden" name="leaveId" id="modalLeaveId">
            <div class="modal-body">
                <h3 class="text-2xl font-black text-slate-800 tracking-tight uppercase mb-8 pr-12 border-b border-slate-100 pb-4">Review Application</h3>
                
                <div class="grid grid-cols-1 md:grid-cols-2 gap-x-12">
                    <div class="info-item">
                        <span class="info-label">Employee Name</span>
                        <span class="info-value" id="modalName"></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Employee ID</span>
                        <span class="info-value" id="modalEmpId"></span>
                    </div>
                </div>

                <div class="info-item">
                    <span class="info-label">Leave Type</span>
                    <span class="info-value text-blue-600" id="modalType"></span>
                </div>
                
                <div class="grid grid-cols-1 md:grid-cols-2 gap-x-12">
                    <div class="info-item">
                        <span class="info-label">Start Date</span>
                        <span class="info-value" id="modalStart"></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">End Date</span>
                        <span class="info-value" id="modalEnd"></span>
                    </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-x-12">
                    <div class="info-item">
                        <span class="info-label">Duration</span>
                        <span class="info-value" id="modalDuration"></span>
                    </div>
                    <div class="info-item">
                        <span class="info-label">Total Days</span>
                        <span class="info-value font-black text-blue-600" id="modalDays"></span>
                    </div>
                </div>

                <div class="info-item">
                    <span class="info-label">Applied On</span>
                    <span class="info-value" id="modalAppliedOn"></span>
                </div>

                <div class="info-item">
                    <span class="info-label">Reason</span>
                    <p class="text-sm text-slate-500 mb-6 bg-slate-50 p-5 rounded-2xl border border-slate-100 font-medium leading-relaxed" id="modalReason"></p>
                </div>

                <!-- Integrated Metadata Extraction Section - Single Column -->
                <div id="dynamicBox" class="hidden">
                    <div class="flex items-center gap-3 mb-4">
                        <div class="w-1 h-4 bg-blue-600 rounded-full"></div>
                        <h4 class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Additional Attributes</h4>
                    </div>
                    <div class="dynamic-meta-container space-y-4" id="dynamicGrid"></div>
                </div>

                <!-- ATTACHMENT ACTION -->
                <div id="attachBox" class="mb-8 hidden">
                    <span class="info-label">Supporting Document</span>
                    <a id="modalAttachLink" href="#" target="_blank" class="inline-flex items-center gap-3 bg-white border-2 border-slate-100 px-5 py-3 rounded-2xl text-[11px] font-black text-slate-600 hover:border-blue-200 hover:text-blue-600 transition-all">
                        <i class="fas fa-file-medical text-red-500 text-lg"></i> VIEW ATTACHMENT <i class="fas fa-external-link-alt opacity-20 text-[9px]"></i>
                    </a>
                </div>

                <!-- Decision Section -->
                <div class="bg-blue-50/60 p-8 rounded-[2.5rem] border border-blue-100 mt-6">
                    <label class="info-label text-blue-500">Decision Choice</label>
                    <select name="action" id="decisionSelect" required class="font-bold text-slate-700"></select>
                    
                    <label class="info-label text-blue-500 mt-6">Response Comment</label>
                    <textarea name="comment" placeholder="Provide feedback for the staff..." class="h-24 resize-none font-medium"></textarea>
                    
                    <button type="submit" class="btn-submit shadow-xl shadow-blue-200 uppercase tracking-widest">Submit Review</button>
                </div>
            </div>
        </form>
    </div>
</div>

<script>
    const CTX = "<%=request.getContextPath()%>";

    // Auto-dismiss the success message after 3 seconds
    window.onload = function() {
        const alert = document.getElementById('statusAlert');
        if (alert) {
            setTimeout(() => {
                alert.classList.add('hide');
                // Optional: Clean URL params after showing
                setTimeout(() => {
                    window.history.replaceState({}, document.title, window.location.pathname);
                }, 500);
            }, 3000);
        }
    }

    function openReview(btn) {
        const d = btn.dataset;
        document.getElementById('modalLeaveId').value = d.id;
        document.getElementById('modalName').textContent = d.name;
        document.getElementById('modalEmpId').textContent = d.empid;
        document.getElementById('modalType').textContent = d.type;
        document.getElementById('modalStart').textContent = d.start;
        document.getElementById('modalEnd').textContent = d.end;
        document.getElementById('modalDuration').textContent = d.duration.replace(/_/g, ' ');
        document.getElementById('modalDays').textContent = d.days;
        document.getElementById('modalAppliedOn').textContent = d.applied;
        document.getElementById('modalReason').textContent = d.reason || "Staff did not provide a detailed reason.";

        // Attachment link
        const abox = document.getElementById('attachBox');
        if(d.attachment && d.attachment !== "") {
            abox.classList.remove('hidden');
            document.getElementById('modalAttachLink').href = CTX + "/ViewAttachment?id=" + d.id;
        } else { abox.classList.add('hidden'); }

        // Dynamic Dropdown Logic
        const sel = document.getElementById('decisionSelect');
        sel.innerHTML = "";
        if(d.status === "PENDING") {
            sel.innerHTML = '<option value="APPROVE">Approve Request</option><option value="REJECT">Reject Request</option>';
        } else {
            sel.innerHTML = '<option value="APPROVE_CANCEL">Approve Cancellation</option><option value="REJECT_CANCEL">Maintain Approval (Reject Cancel)</option>';
        }

        // Dynamic Attributes Logic (Single Column)
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
        addAttr("Medical Facility", d.med);
        addAttr("MC / IC Ref Serial No", d.ref);
        addAttr("Event Date", d.evt);
        addAttr("Discharge Date", d.dis);
        addAttr("Emergency Category", d.cat);
        addAttr("Emergency Phone", d.cnt);
        addAttr("Spouse Name", d.spo);

        dBox.classList.toggle('hidden', count === 0);
        document.getElementById('reviewModal').classList.add('show');
    }

    function closeReview() { 
        document.getElementById('reviewModal').classList.remove('show'); 
    }
</script>
</body>
</html>