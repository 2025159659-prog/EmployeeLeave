<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.time.*" %>
<%@ page import="bean.LeaveRecord" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ include file="icon.jsp" %>

<%! 
    public String RotateCcwIcon(String cls) {
        return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><path d='M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8'/><path d='M3 3v5h5'/></svg>";
    }
%>

<%
    // MANAGER GUARD
    HttpSession ses = request.getSession(false);
    if (ses == null || ses.getAttribute("empid") == null || !"MANAGER".equalsIgnoreCase(String.valueOf(ses.getAttribute("role")))) {
        response.sendRedirect("login.jsp?error=AccessDenied"); return;
    }

    // DATA CASTING
    List<LeaveRecord> leaves = (List<LeaveRecord>) request.getAttribute("leaves");
    Integer pendingCount = (Integer) request.getAttribute("pendingCount") != null ? (Integer) request.getAttribute("pendingCount") : 0;
    Integer cancelReqCount = (Integer) request.getAttribute("cancelReqCount") != null ? (Integer) request.getAttribute("cancelReqCount") : 0;
    String msg = request.getParameter("msg");
    String error = request.getParameter("error");
    
    Calendar cal = Calendar.getInstance();
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manager | Review Applications</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
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
            --radius: 20px;
            --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
        }

        * { box-sizing: border-box; font-family: 'Inter', sans-serif; }
        .fas, .fab, .far, .fa-solid, .fa { font-family: "Font Awesome 6 Free" !important; font-weight: 900; }
        
        body { background: var(--bg); color: var(--text); margin: 0; }
        .pageWrap { padding: 32px 40px; max-width: 1300px; margin: 0 auto; }

        .title { font-size: 26px; font-weight: 800; margin: 0; text-transform: uppercase; color: var(--text); }
        .sub-label { color: var(--blue-primary); font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.1em; margin-top: 4px; display: block; }

        .stat-grid { display: grid; grid-template-cols: repeat(2, 1fr); gap: 20px; margin-bottom: 32px; }
        .stat-card { background: var(--card); border: 1px solid var(--border); border-radius: 16px; padding: 18px 24px; display: flex; align-items: center; justify-content: space-between; border-left: 5px solid var(--blue-primary); box-shadow: var(--shadow); }
        .stat-card.orange { border-left-color: #f97316; }

        .card { background: var(--card); border: 1px solid var(--border); border-radius: var(--radius); box-shadow: var(--shadow); overflow: hidden; }
        
        table { width: 100%; border-collapse: collapse; }
        th, td { border-bottom: 1px solid #f1f5f9; padding: 16px 20px; text-align: left; vertical-align: middle; }
        th { background: #f8fafc; font-size: 10px; text-transform: uppercase; color: var(--muted); font-weight: 800; letter-spacing: 0.05em; }

        .badge { padding: 4px 12px; border-radius: 20px; font-size: 9px; font-weight: 800; text-transform: uppercase; display: inline-flex; align-items: center; gap: 6px; }
        .status-pending { background: #fffbeb; color: #b45309; border: 1px solid #fde68a; } 
        .status-cancellation-requested { background: #fff7ed; color: #c2410c; border: 1px solid #fdba74; }

        .modal-overlay { position:fixed; inset:0; background:rgba(15,23,42,0.6); display:none; align-items:center; justify-content:center; z-index:9999; backdrop-filter:blur(4px); padding: 20px; }
        .modal-overlay.show { display:flex; }
        .modal-content { background:white; width: 100%; max-width: 750px; max-height: 90vh; border-radius: 28px; position: relative; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); display: flex; flex-direction: column; overflow: hidden; animation: slideUp 0.3s ease; }
        @keyframes slideUp { from{opacity:0; transform:translateY(20px);} to{opacity:1; transform:translateY(0);} }
        .modal-body { overflow-y: auto; padding: 40px; flex: 1; }
        
        .info-label { font-size:10px; font-weight:800; color:#94a3b8; text-transform:uppercase; display:block; margin-bottom:4px; letter-spacing:0.05em; }
        .info-value { font-size:14px; font-weight:700; color:#1e293b; display:block; margin-bottom:18px; }
        
        .btn-close { position: absolute; top: 24px; right: 24px; width: 40px; height: 40px; border-radius: 12px; border: 1px solid var(--border); background: #fff; cursor: pointer; display: flex; align-items: center; justify-content: center; color: #94a3b8; transition: 0.2s; z-index: 10; }

        .decision-box { background: #f8fafc; border: 1px solid var(--border); border-radius: 24px; padding: 28px; margin-top: 24px; }
        select, textarea { width: 100%; padding: 12px 16px; border-radius: 12px; border: 1px solid var(--border); outline: none; font-size: 13px; font-weight: 600; background: #fff; margin-top: 8px; }

       /* Container to hold both buttons */
.button-group {
    display: flex;
    gap: 12px; /* Space between buttons */
    width: 100%;
    margin-top: 20px;
}

/* Base styles for both buttons to ensure same size */
.btn-submit, .btn-cancel {
    flex: 1; /* This makes them exactly the same width */
    padding: 16px;
    border-radius: 14px;
    font-weight: 800;
    text-transform: uppercase;
    cursor: pointer;
    border: none;
    font-size: 11px;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
    transition: 0.2s;
    letter-spacing: 0.1em;
}

/* Submit specific color */
.btn-submit {
    background: var(--blue-primary);
    color: white;
}

/* Cancel specific color (Gray/Light) */
.btn-cancel {
    background: #f1f5f9;
    color: #64748b;
}

.btn-submit:hover {
    opacity: 0.9;
    transform: translateY(-1px);
}

.btn-cancel:hover {
    background: #e2e8f0;
    color: #0f172a;
}
        
.dynamic-meta-container { background: #f8fafc; border: 1px solid var(--border); border-radius: 16px; padding: 20px; margin-top: 10px; margin-bottom: 10px; }    </style>
</head>
<body>

<div class="flex">
    <jsp:include page="sidebar.jsp" />
    
    <main class="ml-20 lg:ml-64 min-h-screen w-full transition-all duration-300">
        <jsp:include page="topbar.jsp" />
        
        <div class="pageWrap">
            <div class="flex justify-between items-end mb-8">
                <div>
                    <h2 class="title">REVIEW APPLICATIONS</h2>
                    <span class="sub-label">Manage pending staff absences and evaluate cancellation appeals</span>
                </div>
            </div>
            
                       <%-- Success Alert with Auto-hide ID --%>
            <% if (msg != null) { %>
                <div id="statusAlert" class="bg-emerald-50 border-2 border-emerald-100 text-emerald-700 p-5 rounded-2xl mb-8 flex items-center gap-4 font-black text-sm transition-all duration-500">
                    <i class="fas fa-check-circle text-lg"></i>
                    <%= msg %>
                </div>
            <% } %>

            <%-- Error Alert with Auto-hide ID --%>
            <% if (error != null) { %>
                <div id="statusAlert" class="bg-red-50 border-2 border-red-100 text-red-700 p-5 rounded-2xl mb-8 flex items-center gap-4 font-black text-sm transition-all duration-500">
                    <i class="fas fa-exclamation-circle text-lg"></i>
                    <%= error %>
                </div>
            <% } %>
            
                    
<div class="grid grid-cols-1 md:grid-cols-2 gap-x-10">
    <div class="stat-card flex justify-between items-center">
        <div>
            <span class="info-label">Pending Approval</span>
            <div class="text-2xl font-black text-slate-800 mt-1"><%= pendingCount %></div>
        </div>
        <div class="bg-blue-50 p-3 rounded-2xl text-blue-600">
            <%= ClipboardListIcon("w-6 h-6") %>
        </div>
    </div>

    <div class="stat-card orange flex justify-between items-center">
        <div>
            <span class="info-label">Cancellation Requested</span>
            <div class="text-2xl font-black text-slate-800 mt-1"><%= cancelReqCount %></div>
        </div>
        <div class="bg-orange-50 p-3 rounded-2xl text-orange-600">
            <%= RotateCcwIcon("w-6 h-6") %>
        </div>
    </div>
</div>
<br>
<br>

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
                            <% if (leaves == null || leaves.isEmpty()) { %>
                                <tr><td colspan="6" class="text-center py-24 text-slate-300 font-bold uppercase text-xs italic tracking-widest">No pending applications in your queue.</td></tr>
                            <% } else { for (LeaveRecord r : leaves) { 
                                String status = r.getStatusCode();
                                boolean isCancel = "CANCELLATION_REQUESTED".equalsIgnoreCase(status);
                                String badgeClass = isCancel ? "status-cancellation-requested" : "status-pending";
                                String joinYear = (r.getHireDate() != null) ? String.valueOf(LocalDate.parse(r.getHireDate().toString()).getYear()) : "0000";
                                String displayEmpId = "EMP-" + joinYear + "-" + String.format("%02d", r.getEmpId());
                            %>
                                <tr class="hover:bg-slate-50/50 transition-colors">
                                    <td>
                                        <div class="flex items-center gap-3">
                                            <div class="w-10 h-10 rounded-lg bg-slate-100 overflow-hidden flex-shrink-0 border border-slate-200 flex items-center justify-center">
                                                <% if (r.getProfilePic() != null && !r.getProfilePic().isEmpty()) { %>
                                                    <img src="<%= request.getContextPath() + "/" + r.getProfilePic() %>" class="w-full h-full object-cover">
                                                <% } else { %>
                                                    <div class="text-slate-400 font-bold text-xs uppercase"><%= (r.getFullName() != null) ? r.getFullName().substring(0,1) : "?" %></div>
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
                                    <td class="font-bold text-slate-800 text-sm"><%= r.getDurationDays() %></td>
                                    <td>
                                        <span class="badge <%= badgeClass %>">
                                            <span class="w-1.5 h-1.5 rounded-full bg-current"></span> <%= status.replace("_", " ") %>
                                        </span>
                                    </td>
                                    <td style="text-align:right">
                                        <button onclick="openReview(this)" class="bg-white border border-slate-200 text-slate-600 px-5 py-2 rounded-xl text-[10px] font-black hover:bg-slate-900 hover:text-white transition-all uppercase tracking-widest shadow-sm flex items-center gap-2 ml-auto"
                                                data-id="<%= r.getLeaveId() %>"
                                                data-name="<%= r.getFullName() %>" data-idcode="<%= displayEmpId %>"
                                                data-type="<%= r.getTypeCode() %>" data-typeid="<%= r.getLeaveTypeId() %>"
                                                data-start="<%= r.getStartDate() %>" data-end="<%= r.getEndDate() %>" 
                                                data-days="<%= r.getDurationDays() %>" data-duration="<%= r.getDuration() %>" 
                                                data-applied="<%= r.getAppliedOn() %>" data-reason="<%= (r.getReason() != null) ? r.getReason() : "" %>" 
                                                data-status="<%= status %>" data-attachment="<%= r.getAttachment() != null ? r.getAttachment() : "" %>"
                                                data-med="<%= r.getMedicalFacility() %>" data-ref="<%= r.getRefSerialNo() %>"
                                                data-pre="<%= r.getWeekPregnancy() %>" 
                                                data-evt="<%= r.getEventDate() %>" data-dis="<%= r.getDischargeDate() %>"
                                                data-cat="<%= r.getEmergencyCategory() %>" data-cnt="<%= r.getEmergencyContact() %>"
                                                data-spo="<%= r.getSpouseName() %>"
                                                data-popcomm="<%= (r.getManagerComment() != null) ? r.getManagerComment() : "" %>">
                                            <%= EyeIcon("w-3 h-3") %> Review
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

<div class="modal-overlay" id="detailModal">
    <div class="modal-content">
        <button type="button" class="btn-close" onclick="closeModal()"><i class="fas fa-times"></i></button>
        <div class="modal-body">
            <h3 class="text-2xl font-black text-slate-800 tracking-tight uppercase mb-8 border-b border-slate-100 pb-4">Application Details</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-x-10">
                <div><span class="info-label">Staff Name</span><span class="info-value" id="popName"></span></div>
                <div><span class="info-label">Staff ID</span><span class="info-value" id="popId"></span></div>
            </div>
            <div>
                <span class="info-label">Leave Category</span>
                <div class="flex items-center gap-3">
                    <span class="info-value text-blue-600 mb-0" id="popType"></span>
                 </div>
            </div>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-x-10 mt-4">
                <div><span class="info-label">Start Date</span><span class="info-value" id="popStart"></span></div>
                <div><span class="info-label">End Date</span><span class="info-value" id="popEnd"></span></div>
            </div>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-x-10">
                <div><span class="info-label">Duration Type</span><span class="info-value uppercase" id="popDuration"></span></div>
                <div><span class="info-label">Total Days</span><span class="info-value font-black text-blue-600" id="popDays"></span></div>
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
            <div class="mt-2">
                <span class="info-label">Employee Reason</span>
                <p class="text-sm text-slate-500 bg-slate-50 p-5 rounded-2xl border border-slate-100 italic" id="popReason"></p>
            </div>
            <div id="dynamicBox" class="hidden mt-6">
                <div class="flex items-center gap-3 mb-4">
                <div class="w-1 h-4 bg-blue-600 rounded-full">
                </div><h4 class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Metadata Attributes</h4>
                </div>
                <div class="dynamic-meta-container space-y-4" id="dynamicGrid"></div>
            </div>
            <div id="popCommentBox" class="hidden mt-4"><span class="info-label">Previous Remark</span><p class="text-sm text-blue-600 font-semibold italic" id="popComment"></p></div>
            <form action="ReviewLeave" method="post" class="decision-box">
                <input type="hidden" name="leaveId" id="formLeaveId">
                <div class="flex items-center gap-3 mb-6"><i class="fas fa-gavel text-blue-600"></i><h4 class="text-[11px] font-black text-blue-600 uppercase tracking-widest">Decision Console</h4></div>
                <div class="grid grid-cols-1 gap-5">
                    <div><span class="info-label">Select Action</span><select name="action" id="decisionSelect" required></select></div>
                    <div><span class="info-label">Decision Remark</span><textarea name="comment" rows="3" placeholder="State reason..."></textarea></div>
                </div>
                <div class="flex items-center gap-3 mt-6">
    <button type="submit" class="btn-submit flex items-center gap-2">
        <i class="fas fa-check-circle"></i> 
        Confirm Decision
    </button>

    <button type="button" class="btn-cancel flex items-center gap-2" onclick="window.history.back()">
        <i class="fas fa-times-circle"></i> 
        Cancel
    </button>
</div>
            </form>
        </div>
    </div>
</div>

<script>
    const CTX = "<%=request.getContextPath()%>";
    
    // AUTO-HIDE ALERT Logic
    window.addEventListener('DOMContentLoaded', () => {
        const alert = document.getElementById('statusAlert');
        if (alert) {
            setTimeout(() => {
                alert.style.opacity = '0';
                setTimeout(() => {
                    alert.style.display = 'none';
                }, 500); // Wait for transition
            }, 3000); // 3 seconds
        }
    });

    
    function openReview(btn) {
        const d = btn.dataset;
        document.getElementById('formLeaveId').value = d.id || "";
        document.getElementById('popName').textContent = d.name || "";
        document.getElementById('popId').textContent = d.idcode || "";
        document.getElementById('popType').textContent = d.type || "";
        document.getElementById('popStart').textContent = d.start || "";
        document.getElementById('popEnd').textContent = d.end || "";
        document.getElementById('popDuration').textContent = (d.duration || "").replace(/_/g, ' ');
        document.getElementById('popDays').textContent = d.days || "0";
        document.getElementById('popApplied').textContent = d.applied || "";
        document.getElementById('popReason').textContent = d.reason || "No reason provided.";

        const pComm = document.getElementById('popComment');
        if(d.popcomm && d.popcomm !== "null" && d.popcomm !== "") {
            pComm.textContent = d.popcomm;
            document.getElementById('popCommentBox').classList.remove('hidden');
        } else document.getElementById('popCommentBox').classList.add('hidden');

        

        const abox = document.getElementById('attachBox');
        const noLab = document.getElementById('noAttachLabel');
        if(d.attachment && d.attachment !== "" && d.attachment !== "null") {
            abox.classList.remove('hidden');
            noLab.classList.add('hidden');
            document.getElementById('modalAttachLink').href = CTX + "/ViewAttachment?id=" + d.id;
        } else {
            abox.classList.add('hidden');
            noLab.classList.remove('hidden');
        }

        const sel = document.getElementById('decisionSelect');
        if (d.status === "CANCELLATION_REQUESTED") {
            sel.innerHTML = '<option value="APPROVE_CANCEL">Approve Cancellation</option><option value="REJECT_CANCEL">Maintain Leave</option>';
        } else {
            sel.innerHTML = '<option value="APPROVE">Approve Request</option><option value="REJECT">Reject Request</option>';
        }

        const grid = document.getElementById('dynamicGrid');
        grid.innerHTML = "";
        let count = 0;
        const addAttr = (label, val) => {
            if(val && val !== "null" && val !== "" && val !== "0") {
                grid.innerHTML += '<div class="flex justify-between items-center border-b border-slate-100 pb-2"><span class="info-label text-slate-400 mb-0">'+label+'</span><span class="info-value mb-0 text-slate-600 font-bold text-xs">'+val+'</span></div>';
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