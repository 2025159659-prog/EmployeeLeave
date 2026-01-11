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
  // ROBUST GENDER LOGIC (Aligned with CHAR(1 BYTE))
  // =========================
  Object genderObj = ses.getAttribute("gender");
  if (genderObj == null) genderObj = ses.getAttribute("GENDER"); // Check uppercase variant
  
  // Trim is essential for CHAR(1) fields which might contain trailing spaces in some DBs
  String gen = (genderObj != null) ? String.valueOf(genderObj).trim().toUpperCase() : ""; 
  
  // Logic for Female: F (Female) or P (Perempuan)
  boolean isFemale = gen.startsWith("F") || gen.startsWith("P") || gen.contains("FEMALE") || gen.contains("PEREMPUAN");
  
  // Binary fallback: If not explicitly female, treat as male to ensure one option always shows
  boolean isMale = !isFemale;

  // =========================
  // DATA RETRIEVAL
  // =========================
  List<Map<String,Object>> leaveTypes = (List<Map<String,Object>>) request.getAttribute("leaveTypes");
  if (leaveTypes == null) leaveTypes = new ArrayList<>();

  String typeError = (String) request.getAttribute("typeError");
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Apply Leave | Klinik Dr Mohamad</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  <script src="https://cdn.tailwindcss.com"></script>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  
  <style>
    :root {
      --bg: #f1f5f9;
      --card: #ffffff;
      --border: #e2e8f0;
      --text: #0f172a;
      --muted: #64748b;
      --primary: #2563eb;
      --primary-hover: #1d4ed8;
      --shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
      --radius: 20px;
    }

    * { box-sizing: border-box; font-family: 'Inter', Arial, sans-serif !important; }
    body { margin: 0; background: var(--bg); color: var(--text); overflow-x: hidden; }

    .content { min-height: 100vh; padding: 0; }
    .pageWrap { max-width: 900px; margin: 0 auto; padding: 40px 20px; }

    h2.title { font-size: 28px; font-weight: 800; margin: 0 0 8px; color: var(--text); letter-spacing: -0.02em; }
    .sub { color: var(--muted); margin: 0 0 32px; font-size: 15px; }

    .card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
      padding: 40px;
    }

    .form-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 28px;
      margin-bottom: 28px;
    }
    @media (max-width: 768px) { .form-grid { grid-template-columns: 1fr; } }

    label { 
      display: block; 
      font-size: 11px; 
      font-weight: 700; 
      color: var(--muted); 
      margin-bottom: 8px;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }

    input, select, textarea {
      width: 100%;
      border: 1px solid #cbd5e1;
      border-radius: 12px;
      padding: 12px 16px;
      font-size: 14px;
      background: #fff;
      color: var(--text);
      transition: all 0.2s;
    }
    input:focus, select:focus, textarea:focus {
      outline: none;
      border-color: var(--primary);
      box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.1);
      transform: translateY(-1px);
    }

    textarea { min-height: 120px; resize: none; }

    .duration-options {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 12px;
    }
    .duration-tile {
      border: 1px solid #e2e8f0;
      border-radius: 14px;
      padding: 14px;
      text-align: center;
      cursor: pointer;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      background: #fff;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      gap: 4px;
    }
    .duration-tile:hover { border-color: var(--primary); background: #f8fafc; }
    .duration-tile input { display: none; }
    .duration-tile span { font-size: 10px; font-weight: 800; color: var(--muted); text-transform: uppercase; }
    
    .duration-tile.selected {
      border-color: var(--primary);
      background: #eff6ff;
      box-shadow: 0 0 0 2px var(--primary);
    }
    .duration-tile.selected span { color: var(--primary); }

    .dynamic-attributes {
        grid-column: span 2;
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        padding: 28px;
        border-radius: 16px;
        display: none; 
        margin-bottom: 28px;
        animation: slideDown 0.3s ease-out;
    }
    @keyframes slideDown { from { opacity: 0; transform: translateY(-10px); } to { opacity: 1; transform: translateY(0); } }
    
    .dynamic-title { color: var(--text); font-weight: 800; font-size: 13px; margin-bottom: 20px; display: flex; align-items: center; gap: 8px; text-transform: uppercase; }
    .dynamic-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }
    @media (max-width: 640px) { .dynamic-grid { grid-template-columns: 1fr; } }

    .btn-submit {
      background: var(--primary);
      color: #fff;
      font-weight: 700;
      font-size: 15px;
      border: none;
      border-radius: 14px;
      padding: 16px 32px;
      cursor: pointer;
      width: 100%;
      transition: all 0.2s;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 12px;
    }
    .btn-submit:hover { background: var(--primary-hover); box-shadow: 0 10px 15px -3px rgba(37, 99, 235, 0.3); }

    .overlay {
      position: fixed; inset: 0; background: rgba(15, 23, 42, 0.7);
      display: none; align-items: center; justify-content: center; z-index: 9999; backdrop-filter: blur(8px);
    }
    .overlay.show { display: flex; }
    .modal {
      width: 440px; background: #fff; border-radius: 28px; padding: 48px 32px; text-align: center;
      box-shadow: 0 25px 50px -12px rgba(0,0,0,0.5);
    }
    .modal h3 { font-size: 24px; font-weight: 800; color: #0f172a; margin: 20px 0 12px; }
    .modal p { color: #64748b; margin-bottom: 32px; font-size: 15px; line-height: 1.6; }

    .req-star { color: #ef4444; margin-left: 2px; }
    .hint { color: var(--muted); font-size: 12px; margin-top: 8px; }
  </style>
</head>
<body>

  <jsp:include page="sidebar.jsp" />

  <main class="ml-20 lg:ml-64 min-h-screen transition-all duration-300">
    <div class="content">
      <jsp:include page="topbar.jsp" />

      <div class="pageWrap">
        
        <div class="title-area">
          <h2 class="title">LEAVE APPLICATION</h2>
          <p class="sub">Please fill in the details below to submit your request.</p>
        </div>

        <div class="card">
          <form action="ApplyLeave" method="post" enctype="multipart/form-data" id="applyForm">
            
            <div class="form-grid">
              <div>
                <label for="leaveTypeId">Type of Leave <span class="req-star">*</span></label>
                <select name="leaveTypeId" id="leaveTypeId" required onchange="handleTypeChange()">
                  <option value="" disabled selected>-- Select Type --</option>
                  <%
                    for (Map<String,Object> t : leaveTypes) {
                      String id = String.valueOf(t.get("id"));
                      String code = String.valueOf(t.get("code")).trim().toUpperCase();
                      String desc = (t.get("desc") != null) ? String.valueOf(t.get("desc")).trim().toUpperCase() : "";
                      
                      // Match against both code (ML, PL) and description for eligibility filtering.
                      boolean isMaternityType = code.contains("MATERNITY") || code.equals("ML") || desc.contains("MATERNITY");
                      boolean isPaternityType = code.contains("PATERNITY") || code.equals("PL") || desc.contains("PATERNITY");

                      boolean canView = true;
                      
                      // EXCLUSIVE FILTERING LOGIC:
                      // If it is a Maternity Type, it is only visible to Females.
                      if (isMaternityType && !isFemale) canView = false;
                      // If it is a Paternity Type, it is only visible to Males.
                      if (isPaternityType && !isMale) canView = false;
                      
                      if (canView) {
                  %>
                    <option value="<%= id %>" data-code="<%= code %>"><%= code %> <%= (t.get("desc") != null ? "- " + t.get("desc") : "") %></option>
                  <% } } %>
                </select>
              </div>

              <div>
                <label>Period <span class="req-star">*</span></label>
                <div class="duration-options">
                  <label class="duration-tile selected" onclick="selectDuration(this)">
                    <input type="radio" name="duration" value="FULL_DAY" checked onchange="syncDates()">
                    <span>Full Day</span>
                  </label>
                  <label class="duration-tile" onclick="selectDuration(this)">
                    <input type="radio" name="duration" value="HALF_DAY_AM" onchange="syncDates()">
                    <span>Half (AM)</span>
                  </label>
                  <label class="duration-tile" onclick="selectDuration(this)">
                    <input type="radio" name="duration" value="HALF_DAY_PM" onchange="syncDates()">
                    <span>Half (PM)</span>
                  </label>
                </div>
              </div>
              
              <div id="dynamicAttributes" class="dynamic-attributes">
                  <span class="dynamic-title">
                      <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24"><path d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                      Additional Information Required
                  </span>
                  <div id="dynamicFields" class="dynamic-grid"></div>
              </div>
            </div>

            <div class="form-grid">
              <div>
                <label for="startDate">Start Date <span class="req-star">*</span></label>
                <input type="date" name="startDate" id="startDate" required onchange="syncDates()" />
              </div>
              <div>
                <label for="endDate">End Date <span class="req-star">*</span></label>
                <input type="date" name="endDate" id="endDate" required />
              </div>
            </div>

            <div style="margin-bottom: 28px;">
              <label for="reason">Reason for Leave <span class="req-star">*</span></label>
              <textarea name="reason" id="reason" required placeholder="Provide a detailed reason for your application..."></textarea>
            </div>

            <div style="margin-bottom: 40px;">
              <label>Supporting Document <span id="docRequired" style="display:none;" class="req-star">(Required *)</span></label>
              <input type="file" name="attachment" id="attachment" accept=".pdf,.png,.jpg,.jpeg" 
                     class="bg-slate-50 border-dashed border-2 border-slate-300 p-6 cursor-pointer text-center w-full rounded-xl hover:bg-slate-100 transition-all text-sm font-semibold text-slate-500" />
              <div class="hint">Upload medical certificates or relevant letters. Max file size: 5MB.</div>
            </div>

            <button type="submit" class="btn-submit">
              <%= SendIcon("w-4 h-4") %> Submit Application
            </button>
          </form>
        </div>
      </div>
    </div>
  </main>

  <!-- Success Modal -->
  <div class="overlay" id="overlay">
    <div class="modal">
      <div class="flex justify-center">
          <div class="bg-emerald-100 p-5 rounded-full">
            <%= CheckCircleIcon("w-12 h-12 text-emerald-600") %>
          </div>
      </div>
      <h3>Application Submitted</h3>
      <p id="popupMsg">Your request has been successfully recorded and is awaiting administrative review.</p>
      <div class="flex flex-col gap-3">
          <button class="btn-submit" onclick="goToHistory()">View Leave History</button>
          <button class="text-slate-400 font-bold text-xs uppercase tracking-widest hover:text-slate-600 transition-colors" onclick="closePopup()">Close</button>
      </div>
    </div>
  </div>

  <script>
    const form = document.getElementById('applyForm');
    const startEl = document.getElementById('startDate');
    const endEl = document.getElementById('endDate');
    const typeEl = document.getElementById('leaveTypeId');
    const attachmentEl = document.getElementById('attachment');
    const dynamicAttr = document.getElementById('dynamicAttributes');
    const dynamicFields = document.getElementById('dynamicFields');
    const docReqLabel = document.getElementById('docRequired');

    function selectDuration(element) {
      document.querySelectorAll('.duration-tile').forEach(t => t.classList.remove('selected'));
      element.classList.add('selected');
      const radio = element.querySelector('input[type="radio"]');
      if (radio) {
          radio.checked = true;
          syncDates();
      }
    }

    function syncDates() {
      const durationInput = document.querySelector('input[name="duration"]:checked');
      const duration = durationInput ? durationInput.value : 'FULL_DAY';
      if (duration !== 'FULL_DAY') {
        endEl.value = startEl.value;
        endEl.readOnly = true;
        endEl.style.background = '#f8fafc';
        endEl.style.opacity = '0.6';
      } else {
        endEl.readOnly = false;
        endEl.style.background = '#fff';
        endEl.style.opacity = '1';
      }
    }

    function handleTypeChange() {
      const selectedOption = typeEl.options[typeEl.selectedIndex];
      if (!selectedOption) return;
      
      const code = (selectedOption.getAttribute('data-code') || "").toUpperCase();
      
      dynamicFields.innerHTML = ""; 
      dynamicAttr.style.display = "none";
      docReqLabel.style.display = "none";
      attachmentEl.required = false;

      if (code.includes("SICK") || code === "SL") {
          addInput("clinicName", "Clinic / Hospital Name", "text", true, "e.g. Klinik Kesihatan Merlimau");
          addInput("mcSerialNumber", "MC Serial Number", "text", true, "e.g. MC12345678");
          setRequired(true);
      } 
      else if (code.includes("HOSPITAL") || code === "HL") {
          addInput("hospitalName", "Hospital Facility", "text", true, "e.g. Hospital Melaka");
          addInput("admissionDate", "Admission Date", "date", true, "");
          addInput("dischargeDate", "Discharge Date", "date", true, "");
          setRequired(true);
      }
      else if (code.includes("MATERNITY") || code === "ML") {
          addInput("maternityClinic", "Consultation Clinic", "text", true, "Clinic name");
          addInput("expectedDueDate", "Expected Due Date", "date", true, "");
          setRequired(true);
      }
      else if (code.includes("PATERNITY") || code === "PL") {
          addInput("spouseName", "Spouse Full Name", "text", true, "Name of partner");
          addInput("hospitalLocation", "Hospital Location", "text", true, "e.g. Melaka Gateway Hospital");
          addInput("deliveryDate", "Date of Delivery", "date", true, "");
          setRequired(false);
      }
      else if (code.includes("EMERGENCY") || code === "EL") {
          addSelect("emergencyCategory", "Emergency Category", true, [
              {v: "ACCIDENT", l: "Accident / Kemalangan"},
              {v: "DEATH", l: "Death / Kematian (Family)"},
              {v: "DISASTER", l: "Natural Disaster / Bencana Alam"},
              {v: "MEDICAL_FAMILY", l: "Medical Emergency (Family Member)"},
              {v: "URGENT_REPAIR", l: "Urgent Home Repair (Fire/Flood/Burst Pipe)"},
              {v: "OTHER", l: "Others / Lain-lain"}
          ]);
          addInput("emergencyContact", "Emergency Contact Number", "tel", true, "01X-XXXXXXX");
          setRequired(false);
      }
    }

    function addInput(name, labelText, type, req, ph) {
        dynamicAttr.style.display = "block"; 
        const div = createFieldContainer(labelText, req);
        const input = document.createElement('input');
        input.type = type;
        input.name = name;
        input.placeholder = ph;
        if (req) input.required = true;
        div.appendChild(input);
        dynamicFields.appendChild(div);
    }

    function addSelect(name, labelText, req, options) {
        dynamicAttr.style.display = "block";
        const div = createFieldContainer(labelText, req);
        const select = document.createElement('select');
        select.name = name;
        if (req) select.required = true;
        
        const def = new Option("-- Select Category --", "");
        def.disabled = true; def.selected = true;
        select.add(def);
        
        options.forEach(opt => {
            select.add(new Option(opt.l, opt.v));
        });
        
        div.appendChild(select);
        dynamicFields.appendChild(div);
    }

    function createFieldContainer(labelText, req) {
        const div = document.createElement('div');
        const label = document.createElement('label');
        label.textContent = labelText; 
        if (req) {
            const star = document.createElement('span');
            star.className = "req-star"; star.textContent = " *";
            label.appendChild(star);
        }
        div.appendChild(label);
        return div;
    }

    function setRequired(val) {
        docReqLabel.style.display = val ? "inline" : "none";
        attachmentEl.required = val;
    }

    function goToHistory() {
        window.location.href = "LeaveHistory";
    }

    function closePopup() {
        document.getElementById("overlay").classList.remove("show");
        const url = new URL(window.location.href);
        url.searchParams.delete("msg");
        window.history.replaceState({}, "", url.toString());
    }

    const params = new URLSearchParams(window.location.search);
    if(params.get("msg")) {
      document.getElementById("overlay").classList.add("show");
    }
  </script>
</body>
</html>