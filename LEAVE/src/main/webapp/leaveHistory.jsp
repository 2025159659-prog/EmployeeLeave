<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ include file="icon.jsp" %>

<%
    // =========================
    // SECURITY CHECK
    // =========================
    HttpSession ses = request.getSession(false);
    if (ses == null || ses.getAttribute("empid") == null ||
        ses.getAttribute("role") == null ||
        !"EMPLOYEE".equalsIgnoreCase(String.valueOf(ses.getAttribute("role")))) {
      response.sendRedirect(request.getContextPath() + "/login.jsp?error=Please+login+as+employee");
      return;
    }

    // =========================
    // DATA RETRIEVAL
    // =========================
    List<Map<String, Object>> leaves = (List<Map<String, Object>>) request.getAttribute("leaves");
    List<String> years = (List<String>) request.getAttribute("years");
    String dbError = (String) request.getAttribute("error");

    if (leaves == null) leaves = new ArrayList<>();
    if (years == null) years = new ArrayList<>();

    String currentStatus = request.getParameter("status") != null ? request.getParameter("status") : "ALL";
    String currentYear = request.getParameter("year") != null ? request.getParameter("year") : "";
%>

<%! 
    // Menambah ikon tambahan jika belum ada dalam icon.jsp asal anda
    public String RotateCcwIcon(String cls) {
        return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><path d='M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8'/><path d='M3 3v5h5'/></svg>";
    }
    public String FileTextIcon(String cls) {
        return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><path d='M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z'/><path d='M14 2v4a2 2 0 0 0 2 2h4'/><path d='M10 9H8'/><path d='M16 13H8'/><path d='M16 17H8'/></svg>";
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>LMS | My Leave History</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<script src="https://cdn.tailwindcss.com"></script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">

<style>
:root {
  --bg: #f8fafc;
  --card: #ffffff;
  --primary: #2563eb;
  --primary-hover: #1d4ed8;
  --text-main: #1e293b;
  --text-muted: #64748b;
  --border: #e2e8f0;
  --radius: 16px;
  --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
  --sb-w: 300px;
}

* { box-sizing: border-box; font-family: 'Inter', Arial, sans-serif !important; }
body { background: var(--bg); color: var(--text-main); margin: 0; overflow-x: hidden; }

.content {
  min-height:100vh;
  padding: 0;
}

.pageWrap { max-width: 1400px; margin: 0 auto; padding: 32px 40px; }

.title-area { margin-bottom: 24px; }
h2.title { font-size: 26px; font-weight: 800; margin: 10px 0 6px; color: var(--text-main); text-transform: uppercase; }
.title-area p { color: var(--text-muted); font-size: 15px; margin-top: 4px; }

/* Filter Card */
.filter-card {
  background: var(--card); border: 1px solid var(--border); border-radius: var(--radius);
  padding: 16px 24px; display: flex; justify-content: space-between; align-items: center;
  margin-bottom: 24px; box-shadow: var(--shadow);
}
.filter-group { display: flex; align-items: center; gap: 12px; }
.filter-group label { font-size: 11px; font-weight: 800; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.05em; }

select { padding: 8px 12px; border-radius: 10px; border: 1px solid var(--border); background: #fff; font-size: 14px; outline: none; cursor: pointer; min-width: 140px; }
.btn-filter { background: var(--primary); color: #fff; border: none; padding: 9px 18px; border-radius: 10px; font-weight: 700; cursor: pointer; transition: 0.2s; }
.btn-filter:hover { background: var(--primary-hover); }

/* Table Design */
.table-card { background: var(--card); border: 1px solid var(--border); border-radius: var(--radius); box-shadow: var(--shadow); overflow-x: auto; }
table { width: 100%; border-collapse: collapse; text-align: left; min-width: 1200px; }
th { background: #f8fafc; padding: 16px 15px; font-size: 11px; font-weight: 800; color: var(--text-muted); text-transform: uppercase; border-bottom: 1px solid var(--border); }
td { padding: 16px 15px; border-bottom: 1px solid #f1f5f9; font-size: 13.5px; vertical-align: middle; }

/* Badges */
.badge { padding: 5px 12px; border-radius: 20px; font-size: 10px; font-weight: 700; display: inline-flex; align-items: center; gap: 6px; text-transform: uppercase; }
.status-pending { background: #fffbeb; color: #b45309; border: 1px solid #fde68a; } 
.status-approved { background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; } 
.status-rejected { background: #fef2f2; color: #b91c1c; border: 1px solid #fecaca; } 
.status-cancelled { background: #f1f5f9; color: #475569; border: 1px solid #e2e8f0; } 
.status-cancellation-requested { background: #fff7ed; color: #c2410c; border: 1px solid #fdba74; } 

/* Actions */
.action-group { display: flex; gap: 8px; justify-content: flex-end; }
.btn-circle { width: 36px; height: 36px; border-radius: 10px; border: 1px solid var(--border); background: #fff; color: var(--text-muted); cursor: pointer; display: flex; align-items: center; justify-content: center; transition: 0.2s; }
.btn-circle:hover { background: #eff6ff; color: var(--primary); border-color: var(--primary); }
.btn-danger:hover { background: #fef2f2; color: #ef4444; border-color: #ef4444; }
.btn-warning:hover { background: #fff7ed; color: #ea580c; border-color: #ea580c; }

.overlay { position: fixed; inset: 0; background: rgba(15, 23, 42, 0.6); display: none; align-items: center; justify-content: center; z-index: 2000; backdrop-filter: blur(4px); }
.overlay.show { display: flex; }
.modal { background: #fff; border-radius: 20px; box-shadow: 0 20px 50px rgba(0,0,0,0.2); overflow: hidden; display: flex; flex-direction: column; }
.modal-header { padding: 16px 24px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; background: #f8fafc; }
.modal-header h3 { margin: 0; font-size: 16px; font-weight: 700; color: var(--text-main); }
.modal-body { padding: 24px; overflow-y: auto; flex: 1; }

/* Edit Form */
.edit-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
.field-full { grid-column: 1 / -1; }
.form-group label { display: block; font-size: 11px; font-weight: 800; color: var(--text-muted); text-transform: uppercase; margin-bottom: 6px; }
.form-group input, .form-group select, .form-group textarea { width: 100%; padding: 10px 12px; border: 1px solid var(--border); border-radius: 10px; font-size: 14px; outline: none; }
.form-group input:focus, .form-group select:focus, .form-group textarea:focus { border-color: var(--primary); box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1); }
.form-group textarea { height: 80px; resize: none; }

.modal-footer { padding: 16px 24px; border-top: 1px solid var(--border); display: flex; justify-content: flex-end; gap: 10px; }
.btn-modal { padding: 10px 20px; border-radius: 10px; font-weight: 700; border: none; cursor: pointer; transition: 0.2s; }
.btn-gray { background: #f1f5f9; color: var(--text-muted); }
.btn-blue { background: var(--primary); color: #fff; }

.err-banner { background: #fef2f2; color: #b91c1c; padding: 12px 20px; border-radius: 12px; margin-bottom: 20px; font-size: 14px; font-weight: 600; }
</style>
</head>

<body>
<jsp:include page="sidebar.jsp" />

<main class="ml-20 lg:ml-64 min-h-screen transition-all duration-300">
  <div class="content">
    <jsp:include page="topbar.jsp" />

    <div class="pageWrap">
      <div class="title-area">
        <h2 class="title">My Leave History</h2>
        <p>View and manage all your previous leave applications.</p>
      </div>

      <% if (dbError != null) { %><div class="err-banner"><i class="fas fa-exclamation-circle"></i> <%= dbError %></div><% } %>

      <!-- Filter Card -->
      <form action="<%=request.getContextPath()%>/LeaveHistoryServlet" method="get" class="filter-card">
        <div class="filter-group">
          <label>Filter Status</label>
          <select name="status">
            <option value="ALL" <%= currentStatus.equals("ALL")?"selected":"" %>>All Statuses</option>
            <option value="PENDING" <%= currentStatus.equals("PENDING")?"selected":"" %>>Pending</option>
            <option value="APPROVED" <%= currentStatus.equals("APPROVED")?"selected":"" %>>Approved</option>
            <option value="CANCELLATION_REQUESTED" <%= currentStatus.equals("CANCELLATION_REQUESTED")?"selected":"" %>>Cancellation Requested</option>
            <option value="REJECTED" <%= currentStatus.equals("REJECTED")?"selected":"" %>>Rejected</option>
            <option value="CANCELLED" <%= currentStatus.equals("CANCELLED")?"selected":"" %>>Cancelled</option>
          </select>
          
          <label style="margin-left:10px">Year</label>
          <select name="year">
            <option value="">All Years</option>
            <% for(String yr : years) { %>
              <option value="<%=yr%>" <%= yr.equals(currentYear)?"selected":"" %>><%=yr%></option>
            <% } %>
          </select>
          <button type="submit" class="btn-filter">Apply Filter</button>
        </div>
        <div style="font-size: 13px; color: var(--text-muted);">Records Found: <b><%= leaves.size() %></b></div>
      </form>

      <div class="table-card">
        <table>
          <thead>
            <tr>
              <th>Leave Type</th>
              <th>Dates</th>
              <th>Duration</th>
              <th>Days</th>
              <th>Reason</th>
              <th style="text-align:center">Document</th>
              <th>Status</th>
              <th>Admin Comment</th>
              <th>Applied On</th>
              <th style="text-align:right">Actions</th>
            </tr>
          </thead>
          <tbody>
          <% if (leaves.isEmpty()) { %>
            <tr><td colspan="10" style="text-align:center; padding: 60px; color: var(--text-muted);">No records found.</td></tr>
          <% } else {
              for (Map<String, Object> l : leaves) {
                String code = (String) l.get("status"); 
                
                String badgeClass = "status-pending";
                if ("APPROVED".equalsIgnoreCase(code)) badgeClass = "status-approved";
                else if ("REJECTED".equalsIgnoreCase(code)) badgeClass = "status-rejected";
                else if ("CANCELLED".equalsIgnoreCase(code)) badgeClass = "status-cancelled";
                else if ("CANCELLATION_REQUESTED".equalsIgnoreCase(code)) badgeClass = "status-cancellation-requested";

                String safeFile = String.valueOf(l.get("fileName")).replace("'", "\\'");
          %>
            <tr>
              <td style="font-weight: 700; color: var(--primary);"><%= l.get("type") %></td>
              <td>
                  <div style="font-weight: 600; font-size: 13px;"><%= l.get("start") %></div>
                  <% if(!l.get("start").equals(l.get("end"))) { %>
                      <div style="font-size: 11px; color: var(--text-muted);">to <%= l.get("end") %></div>
                  <% } %>
              </td>
              <td><span style="font-size: 11px; font-weight: 700; text-transform: uppercase;"><%= l.get("duration") %></span></td>
              <td style="font-weight: 800;"><%= l.get("totalDays") %></td>
              <td style="max-width: 150px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" title="<%= l.get("reason") %>">
                  <%= l.get("reason") %>
              </td>
              <td style="text-align:center">
                <% if (Boolean.TRUE.equals(l.get("hasFile"))) { %>
                  <button class="btn-circle" title="View Document" onclick="openDoc('<%= l.get("id") %>', '<%= safeFile %>')">
                    <%= EyeIcon("w-4 h-4") %>
                  </button>
                <% } else { %> - <% } %>
              </td>
              <td>
                <span class="badge <%= badgeClass %>">
                  <span class="w-1.5 h-1.5 rounded-full bg-current"></span> <%= l.get("status") %>
                </span>
              </td>
              <td style="font-size: 12px; color: var(--text-muted); font-style: italic;">
                  <%= (l.get("adminComment") != null && !l.get("adminComment").toString().isBlank()) ? l.get("adminComment") : "-" %>
              </td>
              <td style="color: var(--text-muted); font-size: 12px;"><%= l.get("appliedOn") %></td>
              <td style="text-align:right">
                <div class="action-group">
                  <% if ("PENDING".equalsIgnoreCase(code)) { %>
                    <button class="btn-circle" title="Edit" onclick="openEditModal('<%= l.get("id") %>')">
                        <%= EditIcon("w-4 h-4") %>
                    </button>
                    <button class="btn-circle btn-danger" title="Delete" onclick="askConfirm('DELETE', '<%= l.get("id") %>')">
                        <%= TrashIcon("w-4 h-4 text-red-500 hover:text-white") %>
                    </button>
                  <% } else if ("APPROVED".equalsIgnoreCase(code)) { %>
                    <button class="btn-circle btn-warning" title="Request Cancellation" onclick="askConfirm('REQ_CANCEL', '<%= l.get("id") %>')">
                        <%= RotateCcwIcon("w-4 h-4 text-orange-500 hover:text-white") %>
                    </button>
                  <% } else { %>
                    <span style="color: #ccc; font-size: 11px;">Locked</span>
                  <% } %>
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

<!-- Modals -->
<div class="overlay" id="docOverlay">
  <div class="modal" style="width: 800px; height: 85vh;">
    <div class="modal-header">
      <h3 id="docTitle">Document View</h3>
      <button class="btn-circle" onclick="closeOverlay('docOverlay')">
        <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M18 6 6 18M6 6l12 12"/></svg>
      </button>
    </div>
    <div class="modal-body" style="padding: 0; background: #525659; flex: 1;">
      <iframe id="docFrame" style="width:100%; height:100%; border:none; display: block;"></iframe>
    </div>
  </div>
</div>

<div class="overlay" id="editOverlay">
  <div class="modal" style="width: 500px;">
    <div class="modal-header">
      <h3>Edit Application</h3>
      <button class="btn-circle" onclick="closeOverlay('editOverlay')">
        <svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M18 6 6 18M6 6l12 12"/></svg>
      </button>
    </div>
    <form id="editForm" method="post">
      <div class="modal-body">
        <div id="editModalErr" class="err-banner" style="display:none; padding: 10px;"></div>
        <input type="hidden" name="leaveId" id="editLeaveId">
        <div class="edit-grid">
          <div class="form-group field-full">
            <label>Leave Type</label><select name="leaveType" id="editType" required></select>
          </div>
          <div class="form-group"><label>Start Date</label><input type="date" name="startDate" id="editStart" required></div>
          <div class="form-group"><label>End Date</label><input type="date" name="endDate" id="editEnd" required></div>
          <div class="form-group field-full">
            <label>Duration</label>
            <select name="duration" id="editDuration">
                <option value="FULL_DAY">Full Day</option>
                <option value="HALF_DAY_AM">Half Day (AM)</option>
                <option value="HALF_DAY_PM">Half Day (PM)</option>
            </select>
          </div>
          <div class="form-group field-full"><label>Reason</label><textarea name="reason" id="editReason" required></textarea></div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn-modal btn-gray" onclick="closeOverlay('editOverlay')">Cancel</button>
        <button type="submit" class="btn-modal btn-blue" id="editSubmitBtn">Update</button>
      </div>
    </form>
  </div>
</div>

<div class="overlay" id="confirmOverlay">
  <div class="modal" style="width: 400px; text-align: center; padding: 30px;">
    <div style="font-size: 40px; margin-bottom: 15px; display: flex; justify-content: center;">
        <span id="confIconContainer" class="p-4 rounded-full bg-slate-100"></span>
    </div>
    <h3 id="confTitle">Confirm Action</h3>
    <p id="confMsg" style="color: var(--text-muted); font-size: 14px; margin-bottom: 25px;"></p>
    <div id="confModalErr" class="err-banner" style="display:none; padding: 10px; font-size: 12px; text-align: left;"></div>
    <form id="confForm">
      <input type="hidden" name="id" id="confId">
      <div style="display: flex; gap: 10px;">
        <button type="button" class="btn-modal btn-gray" style="flex:1" onclick="closeOverlay('confirmOverlay')">No</button>
        <button type="submit" class="btn-modal btn-blue" style="flex:1" id="confBtn">Yes, Proceed</button>
      </div>
    </form>
  </div>
</div>

<script>
const CTX = "<%=request.getContextPath()%>";
function closeOverlay(id) { document.getElementById(id).classList.remove('show'); }

function openDoc(id, name) {
    document.getElementById('docTitle').innerText = name;
    document.getElementById('docFrame').src = CTX + "/ViewAttachmentServlet?id=" + id;
    document.getElementById('docOverlay').classList.add('show');
}

async function openEditModal(id) {
    document.getElementById('editOverlay').classList.add('show');
    document.getElementById('editModalErr').style.display = 'none';
    try {
        const response = await fetch(CTX + "/EditLeaveServlet?id=" + id, { headers: {'Accept': 'application/json'} });
        if(!response.ok) throw new Error("Could not load data.");
        const data = await response.json();
        document.getElementById('editLeaveId').value = data.leaveId;
        document.getElementById('editStart').value = data.startDate;
        document.getElementById('editEnd').value = data.endDate;
        document.getElementById('editReason').value = data.reason;
        document.getElementById('editDuration').value = data.duration;
        const typeSelect = document.getElementById('editType');
        typeSelect.innerHTML = "";
        data.leaveTypes.forEach(t => {
            let opt = new Option(t.label, t.value);
            if(t.value == data.leaveTypeId) opt.selected = true;
            typeSelect.add(opt);
        });
    } catch (e) { alert(e.message); closeOverlay('editOverlay'); }
}

document.getElementById('editForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    const btn = document.getElementById('editSubmitBtn');
    btn.disabled = true;
    const formData = new URLSearchParams(new FormData(this));
    try {
        const res = await fetch(CTX + "/EditLeaveServlet", { method: 'POST', body: formData, headers: {'Content-Type': 'application/x-www-form-urlencoded'} });
        const text = await res.text();
        if (res.ok && text.trim() === "OK") window.location.href = CTX + "/LeaveHistoryServlet";
        else throw new Error(text || "Update failed");
    } catch (err) {
        const errBox = document.getElementById('editModalErr');
        errBox.innerText = err.message; errBox.style.display = 'block';
        btn.disabled = false;
    }
});

function askConfirm(action, id) {
    const title = document.getElementById('confTitle');
    const msg = document.getElementById('confMsg');
    const form = document.getElementById('confForm');
    const btn = document.getElementById('confBtn');
    const iconContainer = document.getElementById('confIconContainer');
    
    document.getElementById('confId').value = id;
    document.getElementById('confModalErr').style.display = 'none';

    if(action === 'DELETE') {
        title.innerText = "Delete Application?";
        msg.innerText = "This pending leave request will be permanently removed. Proceed?";
        form.dataset.action = CTX + "/DeleteLeaveServlet";
        btn.style.background = "#ef4444";
        iconContainer.innerHTML = `<svg class="w-10 h-10 text-red-500" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M3 6h18m-2 0v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6m3 0V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2m-6 5v6m4-6v6"/></svg>`;
    } else {
        title.innerText = "Request Cancellation?";
        msg.innerText = "This leave is approved. Submit a request to cancel it?";
        form.dataset.action = CTX + "/CancelLeaveServlet";
        btn.style.background = "#ea580c";
        iconContainer.innerHTML = `<svg class="w-10 h-10 text-orange-500" xmlns="http://www.w3.org/2000/svg" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8m0-5v5h5"/></svg>`;
    }
    document.getElementById('confirmOverlay').classList.add('show');
}

document.getElementById('confForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    const btn = document.getElementById('confBtn');
    const errBox = document.getElementById('confModalErr');
    const url = this.dataset.action;
    
    btn.disabled = true;
    btn.innerText = "Processing...";
    errBox.style.display = 'none';

    const formData = new URLSearchParams(new FormData(this));
    try {
        const res = await fetch(url, { method: 'POST', body: formData, headers: {'Content-Type': 'application/x-www-form-urlencoded'} });
        
        if (res.ok) {
            const text = await res.text();
            if (text.trim() === "OK") {
                window.location.href = CTX + "/LeaveHistoryServlet";
                return;
            }
        }
        
        const errorHtml = await res.text();
        const match = errorHtml.match(/<b>Message<\/b>\s*(.*?)<\/p>/);
        const errorMsg = match ? match[1] : "Server Error: Operation failed.";
        throw new Error(errorMsg);

    } catch (err) {
        errBox.innerHTML = "<i class='fas fa-exclamation-circle'></i> " + err.message; 
        errBox.style.display = 'block';
        btn.disabled = false;
        btn.innerText = "Yes, Proceed";
    }
});
</script>
</body>
</html>