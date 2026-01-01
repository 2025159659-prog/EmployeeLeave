<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ include file="icon.jsp" %>

<%
  // =========================
  // SECURITY & GENDER CHECK
  // =========================
  HttpSession ses = request.getSession(false);
  if (ses == null || ses.getAttribute("empid") == null ||
      ses.getAttribute("role") == null ||
      !"EMPLOYEE".equalsIgnoreCase(String.valueOf(ses.getAttribute("role")))) {
    response.sendRedirect("login.jsp?error=Please+login+as+employee");
    return;
  }

  // Robust Gender Detection
  // We check the session attribute and normalize it
  Object genderObj = ses.getAttribute("gender");
  String rawGender = (genderObj != null) ? String.valueOf(genderObj).trim().toUpperCase() : "M"; 
  
  // Detection logic: check if it starts with 'F' or 'M' to catch "Female", "Male", "F", or "M"
  boolean isFemale = rawGender.startsWith("F");
  boolean isMale = !isFemale; // Default to Male logic if not explicitly Female

  // Data from Servlet
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
      --bg: #f8fafc;
      --card: #ffffff;
      --border: #e2e8f0;
      --text: #1e293b;
      --muted: #64748b;
      --primary: #2563eb;
      --primary-hover: #1d4ed8;
      --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
      --radius: 16px;
    }

    * { box-sizing: border-box; font-family: 'Inter', Arial, sans-serif !important; }
    
    body { margin: 0; background: var(--bg); color: var(--text); overflow-x: hidden; }

    .content { min-height: 100vh; padding: 0; }
    .pageWrap { max-width: 1000px; margin: 0 auto; padding: 32px 40px; }

    h2.title { font-size: 26px; font-weight: 800; margin: 10px 0 6px; color: var(--text); text-transform: uppercase; }
    .sub { color: var(--muted); margin: 0 0 32px; font-size: 15px; font-weight: 500; }

    .card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
      padding: 32px;
    }

    .form-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 24px;
      margin-bottom: 24px;
    }
    @media (max-width: 768px) { .form-grid { grid-template-columns: 1fr; } }

    label { 
      display: block; 
      font-size: 11px; 
      font-weight: 800; 
      color: var(--text); 
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
    }

    textarea { min-height: 100px; resize: vertical; }

    /* Duration Selector Styling */
    .duration-options {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 10px;
    }
    .duration-tile {
      border: 1px solid #cbd5e1;
      border-radius: 12px;
      padding: 12px;
      text-align: center;
      cursor: pointer;
      transition: 0.2s;
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
      border-width: 2px;
    }
    .duration-tile.selected span { color: var(--primary); }

    /* DYNAMIC AREA FIX */
    .dynamic-attributes {
        grid-column: span 2;
        background: #f1f5f9;
        border: 2px dashed var(--primary);
        padding: 24px;
        border-radius: 12px;
        display: none; 
        margin-bottom: 24px;
    }
    .dynamic-title { color: var(--primary); font-weight: 800; font-size: 12px; margin-bottom: 15px; display: block; text-transform: uppercase; border-bottom: 1px solid #cbd5e1; padding-bottom: 5px; }
    .dynamic-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
    @media (max-width: 640px) { .dynamic-grid { grid-template-columns: 1fr; } }

    .btn-submit {
      background: var(--primary);
      color: #fff;
      font-weight: 800;
      font-size: 14px;
      border: none;
      border-radius: 12px;
      padding: 14px 28px;
      cursor: pointer;
      width: 100%;
      transition: 0.2s;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      text-transform: uppercase;
    }
    .btn-submit:hover { background: var(--primary-hover); transform: translateY(-1px); }

    .errBox {
      background: #fef2f2; border: 1px solid #fee2e2; color: #991b1b;
      padding: 14px 16px; border-radius: 12px; margin-bottom: 24px; font-size: 13px;
      display: flex; align-items: center; gap: 10px; font-weight: 700;
    }

    .hint { color: var(--muted); font-size: 11px; margin-top: 6px; font-weight: 600; }
    .req-star { color: #ef4444; margin-left: 2px; }

    .overlay {
      position: fixed; inset: 0; background: rgba(15, 23, 42, 0.6);
      display: none; align-items: center; justify-content: center; z-index: 9999; backdrop-filter: blur(4px);
    }
    .overlay.show { display: flex; }
    .modal {
      width: 400px; background: #fff; border-radius: 24px; padding: 40px 32px; text-align: center;
      box-shadow: 0 25px 50px -12px rgba(0,0,0,0.25);
    }
    .modal-icon-box { margin-bottom: 20px; display: flex; justify-content: center; }
    .modal h3 { margin: 0 0 12px; font-size: 22px; font-weight: 800; color: #1e293b; }
    .modal p { color: var(--muted); margin-bottom: 32px; font-size: 15px; line-height: 1.6; }
  </style>
</head>
<body>

  <jsp:include page="sidebar.jsp" />

  <main class="ml-20 lg:ml-64 min-h-screen transition-all duration-300">
    <div class="content">
      <jsp:include page="topbar.jsp" />

      <div class="pageWrap">
        
        <div class="title-area flex justify-between items-start">
          <div>
            <h2 class="title">APPLY FOR LEAVE</h2>
            <p class="sub">Submit your leave request below. Half-day requests deduct <b>0.5 days</b> from your balance.</p>
          </div>

        </div>

        <% if (typeError != null && !typeError.isEmpty()) { %>
          <div class="errBox">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            Error loading leave types: <%= typeError %>
          </div>
        <% } %>

        <div class="card">
          <form action="ApplyLeaveServlet" method="post" enctype="multipart/form-data" id="applyForm">
            
            <div class="form-grid">
              <div>
                <label for="leaveTypeId">Leave Type <span class="req-star">*</span></label>
                <select name="leaveTypeId" id="leaveTypeId" required onchange="handleTypeChange()">
                  <option value="" disabled selected>-- Select Leave Type --</option>
                  <%
                    for (Map<String,Object> t : leaveTypes) {
                      String id = String.valueOf(t.get("id"));
                      String code = String.valueOf(t.get("code")).toUpperCase();
                      String desc = String.valueOf(t.get("desc"));
                      
                      // GENDER FILTERING LOGIC
                      boolean canView = true;
                      // If user is Male, hide Maternity options
                      if (isMale && code.contains("MATERNITY")) {
                          canView = false;
                      }
                      // If user is Female, hide Paternity options
                      if (isFemale && code.contains("PATERNITY")) {
                          canView = false;
                      }
                      
                      if (canView) {
                  %>
                    <option value="<%= id %>" data-code="<%= code %>"><%= code %></option>
                  <% } } %>
                </select>
              </div>

              <div>
                <label>Duration <span class="req-star">*</span></label>
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
              
              <!-- DYNAMIC CONTAINER -->
              <div id="dynamicAttributes" class="dynamic-attributes">
                  <span class="dynamic-title"><i class="fas fa-list"></i> Additional Details Required</span>
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

            <div style="margin-bottom: 24px;">
              <label for="reason">Reason for Leave <span class="req-star">*</span></label>
              <textarea name="reason" id="reason" required placeholder="Briefly describe why you are taking this leave..."></textarea>
            </div>

            <div style="margin-bottom: 32px;">
              <label id="docLabel">Supporting Document <span id="docRequired" style="display:none;" class="req-star">(Required *)</span></label>
              <div class="relative">
                 <input type="file" name="attachment" id="attachment" accept=".pdf,.png,.jpg,.jpeg" 
                        class="bg-slate-50 border-dashed border-2 border-slate-300 p-8 cursor-pointer text-center w-full rounded-xl hover:bg-slate-100 transition-all text-sm font-semibold text-slate-500" />
              </div>
              <div class="hint">Recommended for all leaves. <b>Mandatory for Sick/Hospitalization/Maternity</b>. (Max 5MB)</div>
            </div>

            <button type="submit" class="btn-submit shadow-md shadow-blue-200">
              <%= SendIcon("w-4 h-4") %> Submit Leave Application
            </button>
          </form>
        </div>

        <div class="mt-12 text-center opacity-30 text-[10px] font-bold uppercase tracking-widest">
            v1.2.5 © 2024 Klinik Dr Mohamad
        </div>
      </div>
    </div>
  </main>

  <!-- Success Modal -->
  <div class="overlay" id="overlay">
    <div class="modal">
      <div class="modal-icon-box">
          <%= CheckCircleIcon("w-16 h-16 text-emerald-500") %>
      </div>
      <h3>Application Sent</h3>
      <p id="popupMsg">Your request has been submitted successfully.</p>
      <button class="btn-submit bg-slate-900 hover:bg-slate-800" onclick="closePopup()">OK, Noted!</button>
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
    }

    function syncDates() {
      const duration = document.querySelector('input[name="duration"]:checked').value;
      if (duration !== 'FULL_DAY') {
        endEl.value = startEl.value;
        endEl.readOnly = true;
        endEl.style.background = '#f8fafc';
        endEl.style.color = '#94a3b8';
      } else {
        endEl.readOnly = false;
        endEl.style.background = '#fff';
        endEl.style.color = 'var(--text)';
      }
    }

    function handleTypeChange() {
      const selectedOption = typeEl.options[typeEl.selectedIndex];
      if (!selectedOption) return;
      
      const code = (selectedOption.getAttribute('data-code') || "").toUpperCase();
      
      // Reset Dynamic UI
      dynamicFields.innerHTML = ""; 
      dynamicAttr.style.display = "none";
      docReqLabel.style.display = "none";
      attachmentEl.required = false;

      // Conditional Logic for dynamic attributes
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
          addInput("spouseIC", "Spouse IC Number", "text", true, "e.g. XXXXXX-XX-XXXX");
          addInput("hospitalLocation", "Hospital Location", "text", true, "City Name");
          addInput("deliveryDate", "Date of Delivery", "date", true, "");
          setRequired(false);
      }
      else if (code.includes("EMERGENCY") || code === "EL") {
          addInput("emergencyCategory", "Category", "text", true, "e.g. Natural Disaster");
          addInput("emergencyContact", "Emergency Phone", "tel", true, "01X-XXXXXXX");
          setRequired(false);
      }
    }

    function addInput(name, labelText, type, req, ph) {
        dynamicAttr.style.display = "block"; 
        
        var div = document.createElement('div');
        div.style.marginBottom = "12px";
        
        var label = document.createElement('label');
        label.style.display = "block";
        label.style.fontSize = "11px";
        label.style.fontWeight = "800";
        label.style.color = "var(--text)";
        label.style.textTransform = "uppercase";
        label.textContent = labelText; 
        
        if (req) {
            var star = document.createElement('span');
            star.className = "req-star";
            star.textContent = " *";
            label.appendChild(star);
        }
        
        var input = document.createElement('input');
        input.type = type;
        input.name = name;
        input.placeholder = ph;
        if (req) input.required = true;
        
        div.appendChild(label);
        div.appendChild(input);
        dynamicFields.appendChild(div);
    }

    function setRequired(val) {
        docReqLabel.style.display = val ? "inline" : "none";
        attachmentEl.required = val;
    }

    form.onsubmit = function(e) {
      const selectedOption = typeEl.options[typeEl.selectedIndex];
      if (!selectedOption) return true;
      const code = selectedOption.getAttribute('data-code') || "";
      const isMandatory = code.includes("SICK") || code.includes("HOSPITAL") || code.includes("MATERNITY");

      if (isMandatory && attachmentEl.files.length === 0) {
        e.preventDefault();
        alert("Supporting document is REQUIRED for Sick, Hospitalization or Maternity leave.");
        return false;
      }
      return true;
    };

    const params = new URLSearchParams(window.location.search);
    if(params.get("msg")) {
      document.getElementById("popupMsg").textContent = params.get("msg");
      document.getElementById("overlay").classList.add("show");
    }

    function closePopup() {
      document.getElementById("overlay").classList.remove("show");
      const url = new URL(window.location.href);
      url.searchParams.delete("msg");
      window.history.replaceState({}, "", url.toString());
    }
  </script>
</body>
</html>