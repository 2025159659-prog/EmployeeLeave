<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<%
    // =========================
    // SECURITY GUARD - MANAGER ONLY
    // =========================
    HttpSession ses = request.getSession(false);
    if (ses == null || ses.getAttribute("empid") == null || ses.getAttribute("role") == null) {
        response.sendRedirect("login.jsp"); 
        return;
    }

    String currentRole = String.valueOf(ses.getAttribute("role")).toUpperCase();
    
    if (!"MANAGER".equals(currentRole)) {
        response.sendRedirect("login.jsp?error=Access+Denied+Managers+Only"); 
        return;
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
    <title>Manager Dashboard</title>

    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/sidebar.css">
    <script src="https://cdn.tailwindcss.com"></script>

    <style>
        :root{
            --bg:#f8fafc;
            --card:#ffffff;
            --border:#e2e8f0;
            --text:#1e293b;
            --muted:#64748b;
            --primary:#2563eb;
            --shadow:0 10px 25px rgba(0,0,0,0.05);
            --radius:16px;
            --green:#10b981;
            --red:#ef4444;
        }

        *{box-sizing:border-box}
        body{margin:0;font-family: 'Inter', sans-serif;background:var(--bg);color:var(--text);}
        
        .content{ padding:0; transition: 0.3s; }
        .pageWrap { padding: 32px 24px; }
        .container{max-width: 1400px; margin:0 auto;}

        .pageHeader{margin-bottom:24px; display: flex; justify-content: space-between; align-items: flex-end;}
        .pageTitle{margin:0;font-size:24px;font-weight:800; color: var(--text);}
        .sub{color: var(--muted); font-size: 15px; margin-top: 4px;}

        .msgBox{ padding:12px 16px; border-radius:12px; font-size:13px; margin-bottom:16px; background:#ecfdf5; border:1px solid #10b981; color:#065f46; font-weight: 600; }

        .stats{ display:grid; grid-template-columns: repeat(2, 1fr); gap:16px; margin-bottom: 24px; }
        .stat{ background:var(--card); border:1px solid var(--border); border-radius:var(--radius); box-shadow:var(--shadow); padding:24px; display:flex; align-items:center; justify-content:space-between; border-left: 6px solid var(--primary); }
        .stat.orange{ border-left-color: #f97316; }
        .stat .num{font-size:32px;font-weight:900;}
        .stat .info-label { font-size: 10px; font-weight: 800; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }

        .card{ background:var(--card); border:1px solid var(--border); border-radius:var(--radius); box-shadow:var(--shadow); overflow:hidden; }
        .cardHead{ padding:18px 24px; border-bottom:1px solid #f1f5f9; display:flex; justify-content:space-between; font-weight:800; }

        table{width:100%;border-collapse:collapse;}
        th,td{border-bottom:1px solid #f1f5f9;padding:18px;text-align:left;vertical-align:middle;}
        th{background:#f8fafc;font-size:11px;text-transform:uppercase;color:#64748b; letter-spacing: 0.05em; font-weight: 800;}

        .badge{ display:inline-block; font-size:11px; font-weight:700; padding:4px 12px; border-radius:999px; background:#f1f5f9; color:#475569; text-transform: uppercase;}
        .badge.pending{background:#fff7ed; color:#9a3412; border: 1px solid #ffedd5;}
        .badge.cancel{background:#fef2f2; color:#991b1b; border: 1px solid #fee2e2;}

        .btn-review { background: var(--primary); color: white; border: none; padding: 8px 16px; border-radius: 8px; font-weight: 700; cursor: pointer; transition: 0.2s; font-size: 12px; }
        .btn-review:hover { background: #1d4ed8; transform: translateY(-1px); }

        .modal-overlay { position: fixed; inset: 0; background: rgba(15, 23, 42, 0.5); display: none; align-items: center; justify-content: center; z-index: 10000; backdrop-filter: blur(4px); }
        .modal-overlay.show { display: flex; }
        .modal-content { background: white; width: 650px; max-width: 95%; border-radius: 24px; padding: 32px; box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25); position: relative; animation: slideUp 0.3s ease; }
        @keyframes slideUp { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

        .modal-header { border-bottom: 1px solid #e2e8f0; padding-bottom: 16px; margin-bottom: 24px; display: flex; justify-content: space-between; align-items: center; }
        .modal-body { max-height: 65vh; overflow-y: auto; padding-right: 10px; }
        
        .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px; }
        .info-item { display: flex; flex-direction: column; gap: 4px; }
        .info-label { font-size: 10px; font-weight: 800; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.05em; }
        .info-value { font-size: 14px; font-weight: 600; color: #1e293b; }

        .attr-box { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 16px; margin-top: 10px; display: none; }
        .attr-title { font-size: 11px; font-weight: 800; color: var(--primary); margin-bottom: 12px; display: block; border-bottom: 1px solid #cbd5e1; padding-bottom: 4px; }

        .decision-footer { border-top: 1px solid #e2e8f0; padding-top: 24px; margin-top: 24px; display: flex; gap: 12px; }
        .btn-decision { flex: 1; padding: 12px; border-radius: 12px; border: none; font-weight: 800; cursor: pointer; text-transform: uppercase; font-size: 13px; color: white; transition: 0.2s; }
        .btn-approve { background: var(--green); }
        .btn-reject { background: var(--red); }
        .btn-circle { width: 36px; height: 36px; border-radius: 10px; border: 1px solid var(--border); background: #fff; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: 0.2s; color: var(--muted); }
    </style>
</head>

<body>
<div class="layout">
    <jsp:include page="sidebar.jsp" />

    <main class="ml-20 lg:ml-64 min-h-screen transition-all duration-300">
        <jsp:include page="topbar.jsp" />

        <div class="content">
            <div class="pageWrap">
                <div class="container">
                    <div class="pageHeader">
                        <div>
                            <h2 class="pageTitle">Review Dashboard</h2>
                            <p class="sub">Process pending employee leave applications.</p>
                        </div>
                        <div class="badge">MANAGER ACCOUNT</div>
                    </div>

                    <div class="stats">
                        <div class="stat">
                            <div>
                                <div class="info-label">Pending Approvals</div>
                                <div class="num"><%= (pendingCount==null?0:pendingCount) %></div>
                            </div>
                            <i class="fas fa-clock fa-2x opacity-10"></i>
                        </div>
                        <div class="stat orange">
                            <div>
                                <div class="info-label">Cancel Requests</div>
                                <div class="num"><%= (cancelReqCount==null?0:cancelReqCount) %></div>
                            </div>
                            <i class="fas fa-times-circle fa-2x opacity-10"></i>
                        </div>
                    </div>

                    <% if (msg != null && !msg.isBlank()) { %>
                        <div class="msgBox"><i class="fas fa-check-circle"></i> <%= msg %></div>
                    <% } %>

                    <div class="card">
                        <div class="cardHead">
                            <span>Applications Ready for Review</span>
                            <span style="color: var(--primary); font-size: 14px;"><%= (leaves==null?0:leaves.size()) %> items</span>
                        </div>

                        <div style="overflow-x:auto;">
                            <table>
                                <thead>
                                <tr>
                                    <th>Employee</th>
                                    <th>Leave Type</th>
                                    <th>Dates (Start - End)</th>
                                    <th>Duration</th>
                                    <th>Days</th>
                                    <th>Status</th>
                                    <th>Applied On</th>
                                    <th style="width:120px;">Action</th>
                                </tr>
                                </thead>
                                <tbody>
                                <%
                                    if (leaves == null || leaves.isEmpty()) {
                                %>
                                    <tr><td colspan="8" style="text-align:center; padding:50px; color:#94a3b8;">No tasks pending.</td></tr>
                                <%
                                    } else {
                                        for (Map<String, Object> r : leaves) {
                                            String status = String.valueOf(r.get("status"));
                                            boolean isCancelReq = "CANCELLATION_REQUESTED".equalsIgnoreCase(status);
                                            
                                            // FIX: Directly retrieve from keys defined in ManagerDashboardServlet.java
                                            Object daysVal = r.get("days");
                                            Object sessionVal = r.get("duration");
                                            String days = (daysVal != null) ? String.valueOf(daysVal) : "0";
                                            String sessionType = (sessionVal != null) ? String.valueOf(sessionVal) : "-";
                                            String appliedOn = (r.get("appliedOn") != null) ? String.valueOf(r.get("appliedOn")) : "-";
                                %>
                                    <tr>
                                        <td>
                                            <div style="font-weight: 700;"><%= r.get("fullname") %></div>
                                            <div style="font-size:11px; color:#64748b;">ID: <%= r.get("empid") %></div>
                                        </td>
                                        <td><span class="badge"><%= r.get("leaveType") %></span></td>
                                        <td style="font-size:13px; font-weight:600;">
                                            <%= r.get("startDate") %> - <%= r.get("endDate") %>
                                        </td>
                                        <td>
                                            <span style="font-size:11px; font-weight:700; color:#475569; text-transform:uppercase;"><%= sessionType %></span>
                                        </td>
                                        <td>
                                            <span style="font-size:13px; font-weight:700; color:var(--primary);"><%= days %></span>
                                        </td>
                                        <td>
                                            <span class="badge <%= isCancelReq ? "cancel" : "pending" %>">
                                                <%= isCancelReq ? "Cancel Req" : "Pending" %>
                                            </span>
                                        </td>
                                        <td style="font-size:11px; color:#64748b; white-space: nowrap;">
                                            <%= appliedOn %>
                                        </td>
                                        <td>
                                            <button class="btn-review" onclick='openReview(this)'
                                                    data-id="<%= r.get("leaveId") %>"
                                                    data-empid="<%= r.get("empid") %>"
                                                    data-name="<%= r.get("fullname") %>"
                                                    data-type="<%= r.get("leaveType") %>"
                                                    data-dates="<%= r.get("startDate") %> to <%= r.get("endDate") %>"
                                                    data-duration="<%= days %> Days (<%= sessionType %>)"
                                                    data-reason="<%= r.get("reason") %>"
                                                    data-status="<%= r.get("status") %>"
                                                    data-attachment="<%= r.get("attachment") != null ? r.get("attachment") : "" %>"
                                                    data-medical="<%= r.get("medicalFacility") != null ? r.get("medicalFacility") : "" %>"
                                                    data-ref="<%= r.get("refSerialNo") != null ? r.get("refSerialNo") : "" %>"
                                                    data-event="<%= r.get("eventDate") != null ? r.get("eventDate") : "" %>"
                                                    data-discharge="<%= r.get("dischargeDate") != null ? r.get("dischargeDate") : "" %>"
                                                    data-cat="<%= r.get("emergencyCategory") != null ? r.get("emergencyCategory") : "" %>"
                                                    data-contact="<%= r.get("emergencyContact") != null ? r.get("emergencyContact") : "" %>"
                                                    data-spouse="<%= r.get("spouseName") != null ? r.get("spouseName") : "" %>">
                                                <i class="fas fa-search"></i> Review
                                            </button>
                                        </td>
                                    </tr>
                                <% } } %>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </main>
</div>

<!-- MODALS -->
<div class="modal-overlay" id="reviewModal">
    <div class="modal-content">
        <div class="modal-header">
            <h3 style="margin:0; font-weight:800; font-size:20px;">Review Application</h3>
            <button class="btn-circle" onclick="closeReview()"><i class="fas fa-times"></i></button>
        </div>
        <form action="ManagerLeaveActionServlet" method="post">
            <input type="hidden" name="leaveId" id="modalLeaveId">
            <div class="modal-body">
                <div class="info-grid">
                    <div class="info-item"><span class="info-label">Employee</span><span class="info-value" id="modalName"></span></div>
                    <div class="info-item"><span class="info-label">Employee ID</span><span class="info-value" id="modalEmpId"></span></div>
                    <div class="info-item"><span class="info-label">Leave Type</span><span class="info-value" id="modalType"></span></div>
                    <div class="info-item"><span class="info-label">Duration</span><span class="info-value" id="modalDuration"></span></div>
                </div>
                <div class="info-item" style="margin-bottom:20px;"><span class="info-label">Dates</span><span class="info-value" id="modalDates"></span></div>
                <div class="info-item" style="margin-bottom:20px;"><span class="info-label">Reason</span><p id="modalReason" style="margin:0; font-size:14px; color:#475569;"></p></div>
                <div id="attachmentBox" style="margin-bottom:20px; display:none;">
                    <span class="info-label">Document</span><br/>
                    <button type="button" id="btnOpenDoc" class="btn-review" style="display:inline-block; margin-top:5px; background:#fff; color:var(--primary); border:1px solid var(--primary);"><i class="fas fa-eye"></i> View Attachment</button>
                </div>
                <div id="dynamicBox" class="attr-box">
                    <span class="attr-title">Specific Details</span>
                    <div class="info-grid" id="dynamicGrid"></div>
                </div>
                <div style="margin-top:24px;">
                    <label class="info-label">Decision Remark</label>
                    <textarea name="comment" placeholder="Optional remark..." style="width:100%; border:1px solid #e2e8f0; border-radius:12px; padding:12px; margin-top:8px; height:80px;"></textarea>
                </div>
            </div>
            <div class="decision-footer">
                <button type="submit" name="action" id="btnReject" class="btn-decision btn-reject">Reject</button>
                <button type="submit" name="action" id="btnApprove" class="btn-decision btn-approve">Approve</button>
            </div>
        </form>
    </div>
</div>

<div class="modal-overlay" id="docOverlay">
  <div class="modal-content" style="width: 900px; height: 90vh;">
    <div class="modal-header">
      <h3 id="docTitle" style="margin:0; font-weight:800; font-size:18px;">Preview</h3>
      <button class="btn-circle" onclick="closeOverlay('docOverlay')"><i class="fas fa-times"></i></button>
    </div>
    <div class="modal-body" style="padding:0; background:#525659; flex:1; border-radius:0 0 12px 12px; overflow:hidden;">
      <iframe id="docFrame" style="width:100%; height:100%; border:none; display:block;"></iframe>
    </div>
  </div>
</div>

<script>
    const CTX = "<%=request.getContextPath()%>";
    function closeOverlay(id) { 
        document.getElementById(id).classList.remove('show'); 
        if(id === 'docOverlay') document.getElementById('docFrame').src = "about:blank";
    }
    function openDoc(id, name) {
        document.getElementById('docTitle').innerText = "Preview: " + name;
        document.getElementById('docFrame').src = CTX + "/ViewAttachmentServlet?id=" + id;
        document.getElementById('docOverlay').classList.add('show');
    }
    function openReview(btn) {
        const d = btn.dataset;
        document.getElementById('modalLeaveId').value = d.id;
        document.getElementById('modalName').textContent = d.name;
        document.getElementById('modalEmpId').textContent = d.empid;
        document.getElementById('modalType').textContent = d.type;
        document.getElementById('modalDates').textContent = d.dates;
        document.getElementById('modalDuration').textContent = d.duration;
        document.getElementById('modalReason').textContent = d.reason || "No reason provided.";
        const abox = document.getElementById('attachmentBox');
        const btnDoc = document.getElementById('btnOpenDoc');
        if(d.attachment && d.attachment !== "") {
            abox.style.display = "block";
            btnDoc.onclick = function() { openDoc(d.id, d.attachment); };
        } else { abox.style.display = "none"; }
        const dGrid = document.getElementById('dynamicGrid');
        dGrid.innerHTML = "";
        let count = 0;
        const checkAttr = (label, val) => {
            if(val && val !== "" && val !== "null") {
                dGrid.innerHTML += '<div class="info-item"><span class="info-label">'+label+'</span><span class="info-value">'+val+'</span></div>';
                count++;
            }
        };
        checkAttr("Medical Facility", d.medical);
        checkAttr("Ref Serial No", d.ref);
        checkAttr("Event Date", d.event);
        checkAttr("Discharge Date", d.discharge);
        checkAttr("Category", d.cat);
        checkAttr("Contact", d.contact);
        checkAttr("Spouse Name", d.spouse);
        document.getElementById('dynamicBox').style.display = count > 0 ? "block" : "none";
        const isCancel = d.status === "CANCELLATION_REQUESTED";
        const app = document.getElementById('btnApprove');
        const rej = document.getElementById('btnReject');
        if(isCancel) {
            app.textContent = "Approve Cancel"; app.value = "APPROVE_CANCEL";
            rej.textContent = "Reject Cancel"; rej.value = "REJECT_CANCEL";
        } else {
            app.textContent = "Approve"; app.value = "APPROVE";
            rej.textContent = "Reject"; rej.value = "REJECT";
        }
        document.getElementById('reviewModal').classList.add('show');
    }
    function closeReview() { document.getElementById('reviewModal').classList.remove('show'); }
</script>
</body>
</html>