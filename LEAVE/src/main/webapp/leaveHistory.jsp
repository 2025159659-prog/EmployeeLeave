<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ include file="icon.jsp" %>

<%
// =========================
// SECURITY CHECK
// =========================
HttpSession ses = request.getSession(false);
String role = (ses != null) ? String.valueOf(ses.getAttribute("role")) : "";

if (ses == null || ses.getAttribute("empid") == null ||
(!"EMPLOYEE".equalsIgnoreCase(role) && !"MANAGER".equalsIgnoreCase(role))) {
response.sendRedirect(request.getContextPath() + "/login.jsp?error=Please+login+as+employee+or+manager");
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
}

* { box-sizing: border-box; font-family: 'Inter', Arial, sans-serif !important; }
body { background: var(--bg); color: var(--text-main); margin: 0; overflow-x: hidden; }

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

select, input, textarea { padding: 8px 12px; border-radius: 10px; border: 1px solid var(--border); background: #fff; font-size: 14px; outline: none; transition: 0.2s; }
select:focus, input:focus, textarea:focus { border-color: var(--primary); box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1); }

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

.btn-circle { width: 36px; height: 36px; border-radius: 10px; border: 1px solid var(--border); background: #fff; color: var(--text-muted); cursor: pointer; display: flex; align-items: center; justify-content: center; transition: 0.2s; }
.btn-circle:hover { background: #eff6ff; color: var(--primary); border-color: var(--primary); }
.btn-danger:hover { background: #fef2f2; color: #ef4444; border-color: #ef4444; }

.overlay { position: fixed; inset: 0; background: rgba(15, 23, 42, 0.6); display: none; align-items: center; justify-content: center; z-index: 2000; backdrop-filter: blur(4px); padding: 20px; }
.overlay.show { display: flex; }
.modal { background: #fff; border-radius: 20px; box-shadow: 0 20px 50px rgba(0,0,0,0.2); overflow: hidden; display: flex; flex-direction: column; max-height: 90vh; }
.modal-header { padding: 16px 24px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; background: #f8fafc; }
.modal-body { padding: 24px; overflow-y: auto; flex: 1; }

.edit-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
.field-full { grid-column: 1 / -1; }
.form-group label { display: block; font-size: 11px; font-weight: 800; color: var(--text-muted); text-transform: uppercase; margin-bottom: 6px; }

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
        <p>View and manage your previous leave applications.</p>
      </div>

      <% if (dbError != null) { %><div class="err-banner"><i class="fas fa-exclamation-circle"></i> <%= dbError %></div><% } %>

      <!-- Filter Card -->
      <form action="<%=request.getContextPath()%>/LeaveHistory" method="get" class="filter-card">
        <div class="filter-group">
          <label>Status</label>
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
              <th style="text-align:center">File</th>
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
              <td style="max-width: 150px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" title="<%= l.get("reason") %>"><%= l.get("reason") %></td>
              <td style="text-align:center">
                <% if (Boolean.TRUE.equals(l.get("hasFile"))) { %>
                  <button class="btn-circle" title="View Document" onclick="openDoc('<%= l.get("id") %>', '<%= safeFile %>')"><%= EyeIcon("w-4 h-4") %></button>
                <% } else { %> - <% } %>
              </td>
              <td><span class="badge <%= badgeClass %>"><span class="w-1.5 h-1.5 rounded-full bg-current"></span> <%= l.get("status") %></span></td>
              <td style="font-size: 12px; color: var(--text-muted); font-style: italic;"><%= (l.get("adminComment") != null && !l.get("adminComment").toString().isBlank()) ? l.get("adminComment") : "-" %></td>
              <td style="color: var(--text-muted); font-size: 12px;"><%= l.get("appliedOn") %></td>
              <td style="text-align:right">
                <div class="flex gap-2 justify-end">
                  <% if ("PENDING".equalsIgnoreCase(code)) { %>
                    <button class="btn-circle" title="Edit" onclick="openEditModal('<%= l.get("id") %>')"><%= EditIcon("w-4 h-4") %></button>
                    <button class="btn-circle btn-danger" title="Delete" onclick="askConfirm('DELETE', '<%= l.get("id") %>')"><%= TrashIcon("w-4 h-4") %></button>
                  <% } else if ("APPROVED".equalsIgnoreCase(code)) { %>
                    <button class="btn-circle" style="color:#ea580c" title="Request Cancellation" onclick="askConfirm('REQ_CANCEL', '<%= l.get("id") %>')"><%= RotateCcwIcon("w-4 h-4") %></button>
                  <% } else { %><span class="text-[10px] text-slate-400 font-bold uppercase">Locked</span><% } %>
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

<!-- Doc Overlay -->
<div class="overlay" id="docOverlay">
  <div class="modal" style="width: 800px; height: 85vh;">
    <div class="modal-header">
      <h3 id="docTitle" class="font-bold">Document View</h3>
      <button class="btn-circle" onclick="closeOverlay('docOverlay')">✕</button>
    </div>
    <div class="modal-body p-0 bg-slate-800"><iframe id="docFrame" class="w-full h-full border-none block"></iframe></div>
  </div>
</div>

<!-- Basic Edit Modal -->
<div class="overlay" id="editOverlay">
  <div class="modal" style="width: 500px;">
    <div class="modal-header">
      <h3 class="font-bold">Edit Leave Application</h3>
      <button class="btn-circle" onclick="closeOverlay('editOverlay')">✕</button>
    </div>
    <form id="editForm">
      <div class="modal-body">
        <div id="editModalErr" class="err-banner" style="display:none"></div>
        <input type="hidden" name="leaveId" id="editLeaveId">
        <div class="edit-grid">
          <div class="form-group field-full">
            <label>Leave Type</label>
            <select name="leaveType" id="editType" required class="w-full"></select>
          </div>
          <div class="form-group">
            <label>Start Date</label>
            <input type="date" name="startDate" id="editStart" required class="w-full">
          </div>
          <div class="form-group">
            <label>End Date</label>
            <input type="date" name="endDate" id="editEnd" required class="w-full">
          </div>
          <div class="form-group field-full">
            <label>Duration</label>
            <select name="duration" id="editDuration" class="w-full">
                <option value="FULL_DAY">Full Day</option>
                <option value="HALF_DAY_AM">Half Day (AM)</option>
                <option value="HALF_DAY_PM">Half Day (PM)</option>
            </select>
          </div>
          <div class="form-group field-full">
            <label>Reason</label>
            <textarea name="reason" id="editReason" required class="w-full h-24"></textarea>
          </div>
        </div>
      </div>
      <div class="modal-footer p-4 border-t flex justify-end gap-3">
        <button type="button" class="btn-modal btn-gray" onclick="closeOverlay('editOverlay')">Cancel</button>
        <button type="submit" class="btn-modal btn-blue" id="editSubmitBtn">Update Application</button>
      </div>
    </form>
  </div>
</div>

<div class="overlay" id="confirmOverlay">
  <div class="modal" style="width: 400px; text-align: center; padding: 30px;">
    <div id="confIconContainer" class="mb-4 flex justify-center"></div>
    <h3 id="confTitle" class="font-bold text-lg">Confirm Action</h3>
    <p id="confMsg" class="text-slate-500 text-sm mb-6"></p>
    <div id="confModalErr" class="err-banner hidden text-xs text-left"></div>
    <form id="confForm">
      <input type="hidden" name="id" id="confId">
      <div class="flex gap-3">
        <button type="button" class="btn-modal btn-gray flex-1" onclick="closeOverlay('confirmOverlay')">No</button>
        <button type="submit" class="btn-modal btn-blue flex-1" id="confBtn">Yes, Proceed</button>
      </div>
    </form>
  </div>
</div>

<script>
const CTX = "<%=request.getContextPath()%>";
function closeOverlay(id) { document.getElementById(id).classList.remove('show'); }

function openDoc(id, name) {
    document.getElementById('docTitle').innerText = name;
    document.getElementById('docFrame').src = CTX + "/ViewAttachment?id=" + id;
    document.getElementById('docOverlay').classList.add('show');
}

async function openEditModal(id) {
    document.getElementById('editOverlay').classList.add('show');
    document.getElementById('editModalErr').style.display = 'none';
    try {
        const response = await fetch(CTX + "/EditLeave?id=" + id, { headers: {'Accept': 'application/json'} });
        if(!response.ok) throw new Error("Could not load application data.");
        const data = await response.json();
        
        document.getElementById('editLeaveId').value = data.leaveId;
        document.getElementById('editStart').value = data.startDate;
        document.getElementById('editEnd').value = data.endDate;
        document.getElementById('editReason').value = data.reason || "";
        
        // Combine duration and halfSession for the UI
        let durValue = data.duration || "FULL_DAY";
        if(durValue === 'HALF_DAY') {
            durValue = data.halfSession === 'PM' ? 'HALF_DAY_PM' : 'HALF_DAY_AM';
        }
        document.getElementById('editDuration').value = durValue;

        const typeSelect = document.getElementById('editType');
        typeSelect.innerHTML = "";
        
        if (data.leaveTypes && Array.isArray(data.leaveTypes)) {
            data.leaveTypes.forEach(t => {
                const label = t.label || (t.code);
                const value = t.value || t.id;
                
                let opt = new Option(label, value);
                if(value == data.leaveTypeId) opt.selected = true;
                typeSelect.add(opt);
            });
        }
    } catch (e) { 
        console.error("Fetch Error:", e);
        alert("Failed to load data. Please ensure the backend is sending valid JSON."); 
        closeOverlay('editOverlay'); 
    }
}

document.getElementById('editForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    const btn = document.getElementById('editSubmitBtn');
    const errBox = document.getElementById('editModalErr');
    btn.disabled = true; btn.innerText = "Saving...";

    const formData = new URLSearchParams(new FormData(this));
    
    // Split combined duration value back into two parameters for the Servlet
    const dur = formData.get('duration');
    if (dur && dur.startsWith('HALF_DAY')) {
        formData.set('duration', 'HALF_DAY');
        formData.set('halfSession', dur.includes('AM') ? 'AM' : 'PM');
    } else {
        formData.set('halfSession', '');
    }

    try {
        const res = await fetch(CTX + "/EditLeave", { method: 'POST', body: formData, headers: {'Content-Type': 'application/x-www-form-urlencoded'} });
        const text = await res.text();
        if (res.ok && text.trim() === "OK") window.location.reload();
        else throw new Error(text || "Update failed.");
    } catch (err) {
        errBox.innerText = err.message; errBox.style.display = 'block';
        btn.disabled = false; btn.innerText = "Update";
    }
});

function askConfirm(action, id) {
    const title = document.getElementById('confTitle');
    const msg = document.getElementById('confMsg');
    const form = document.getElementById('confForm');
    const btn = document.getElementById('confBtn');
    const iconContainer = document.getElementById('confIconContainer');
    document.getElementById('confId').value = id;
    document.getElementById('confModalErr').classList.add('hidden');

    if(action === 'DELETE') {
        title.innerText = "Delete Application?";
        msg.innerText = "This pending request will be permanently deleted.";
        form.dataset.action = CTX + "/DeleteLeave";
        btn.className = "btn-modal bg-red-600 text-white flex-1";
        iconContainer.innerHTML = `<div class="p-4 bg-red-50 rounded-full text-red-600"><svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/></svg></div>`;
    } else {
        title.innerText = "Request Cancellation?";
        msg.innerText = "Submit a request to cancel this approved leave.";
        form.dataset.action = CTX + "/CancelLeave";
        btn.className = "btn-modal bg-orange-600 text-white flex-1";
        iconContainer.innerHTML = `<div class="p-4 bg-orange-50 rounded-full text-orange-600"><svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-width="2" d="M3 12a9 9 0 109-9 9.75 9.75 0 00-6.74 2.74L3 8m0-5v5h5"/></svg></div>`;
    }
    document.getElementById('confirmOverlay').classList.add('show');
}

document.getElementById('confForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    const btn = document.getElementById('confBtn');
    const errBox = document.getElementById('confModalErr');
    btn.disabled = true; btn.innerText = "Processing...";
    try {
        const res = await fetch(this.dataset.action, { method: 'POST', body: new URLSearchParams(new FormData(this)), headers: {'Content-Type': 'application/x-www-form-urlencoded'} });
        if (res.ok && (await res.text()).trim() === "OK") window.location.reload();
        else throw new Error("Operation failed.");
    } catch (err) {
        errBox.innerText = err.message; errBox.classList.remove('hidden');
        btn.disabled = false; btn.innerText = "Yes, Proceed";
    }
});
</script>
</body>
</html>