<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, bean.LeaveBalance"%>
<%@ include file="icon.jsp"%>

<%
// =========================
// SECURITY CHECK
// =========================
HttpSession ses = request.getSession(false);
String role = (ses != null) ? String.valueOf(ses.getAttribute("role")) : "";

if (ses == null || ses.getAttribute("empid") == null || (!"EMPLOYEE".equalsIgnoreCase(role))) {
	response.sendRedirect(request.getContextPath() + "/login.jsp?error=Please+login+as+employee");
	return;
}

// =========================
// ROBUST GENDER LOGIC
// =========================
Object genderObj = ses.getAttribute("gender");
if (genderObj == null)
	genderObj = ses.getAttribute("GENDER");

String gen = (genderObj != null) ? String.valueOf(genderObj).trim().toUpperCase() : "";
boolean isFemale = gen.startsWith("F") || gen.startsWith("P") || gen.contains("FEMALE") || gen.contains("PEREMPUAN");
boolean isMale = !isFemale;

// =========================
// DATA RETRIEVAL
// =========================
List<Map<String, Object>> leaveTypes = (List<Map<String, Object>>) request.getAttribute("leaveTypes");
List<LeaveBalance> balances = (List<LeaveBalance>) request.getAttribute("balances");
if (leaveTypes == null)
	leaveTypes = new ArrayList<>();
if (balances == null)
	balances = new ArrayList<>();

String typeError = (String) request.getAttribute("typeError");
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Apply Leave | Klinik Dr Mohamad</title>
<link rel="stylesheet"
	href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<script src="https://cdn.tailwindcss.com"></script>
<link
	href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap"
	rel="stylesheet">

<style>
:root {
	--bg: #f1f5f9;
	--card: #ffffff;
	--border: #e2e8f0;
	--text: #1e293b;
	--muted: #475569;
	--primary: #2563eb;
	--radius: 20px;
}

* {
	box-sizing: border-box;
	font-family: 'Inter', Arial, sans-serif !important;
}

body {
	margin: 0;
	background: var(--bg);
	color: var(--text);
	overflow-x: hidden;
	-webkit-font-smoothing: antialiased;
}

.pageWrap {
	max-width: 1000px;
	margin: 0 auto;
	padding: 32px 40px;
}

h2.title {
	font-size: 28px;
	font-weight: 900;
	margin: 0;
	text-transform: uppercase;
	color: #000;
	letter-spacing: -0.02em;
}

.sub-label {
	color: var(--primary);
	font-size: 11px;
	font-weight: 800;
	text-transform: uppercase;
	letter-spacing: 0.1em;
	margin-top: 4px;
	display: block;
}

.card {
	background: var(--card);
	border: 1px solid var(--border);
	border-radius: var(--radius);
	box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.04);
	padding: 40px;
	margin-top: 24px;
}

.form-grid {
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 24px;
	margin-bottom: 24px;
}

@media ( max-width : 768px) {
	.form-grid {
		grid-template-columns: 1fr;
	}
}

label {
	display: block;
	font-size: 13px;
	font-weight: 900;
	color: #233f66;
	margin-bottom: 8px;
	text-transform: uppercase;
	letter-spacing: 0.05em;
}

input, select, textarea {
	width: 100% !important;
	height: 54px !important;
	padding: 0 20px !important;
	border: 1px solid #cbd5e1 !important;
	border-radius: 14px !important;
	font-size: 14px !important;
	font-weight: 600 !important;
	background: #fff !important;
	transition: all 0.2s;
	outline: none !important;
	display: block !important;
	box-sizing: border-box !important;
	text-transform: uppercase;
}

textarea {
	height: 120px !important;
	padding: 18px 20px !important;
}

input:focus, select:focus, textarea:focus {
	border-color: var(--primary) !important;
	box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.08) !important;
}

input[type="date"] {
	text-transform: none;
}

.duration-options {
	display: grid;
	grid-template-columns: repeat(3, 1fr);
	gap: 10px;
	height: 54px;
}

.duration-tile {
	border: 2px solid #e2e8f0;
	border-radius: 14px;
	padding: 0;
	display: flex;
	align-items: center;
	justify-content: center;
	cursor: pointer;
	background: #fff;
	transition: 0.2s;
}

.duration-tile input {
	display: none !important;
}

.duration-tile span {
	font-size: 10px;
	font-weight: 900;
	color: #64748b;
	text-transform: uppercase;
	letter-spacing: 0.02em;
}

.duration-tile.selected {
	border-color: var(--primary);
	background: #eff6ff;
}

.duration-tile.selected span {
	color: var(--primary);
}

.dynamic-attributes {
	grid-column: span 2;
	background: #f8fafc;
	border: 1px solid #e2e8f0;
	padding: 32px;
	border-radius: 20px;
	display: none;
	margin-bottom: 24px;
}

.dynamic-grid {
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 24px;
}

.validation-error {
	background: #fef2f2;
	border: 1px solid #fecaca;
	color: #b91c1c;
	padding: 12px 16px;
	border-radius: 12px;
	font-size: 12px;
	font-weight: 800;
	margin-bottom: 20px;
	display: none;
	align-items: center;
	gap: 8px;
	text-transform: uppercase;
}

.btn-submit {
	background: var(--primary);
	color: #fff;
	font-weight: 900;
	font-size: 15px;
	text-transform: uppercase;
	letter-spacing: 0.05em;
	border: none;
	border-radius: 16px;
	height: 56px;
	width: 100%;
	cursor: pointer;
	transition: 0.2s;
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 12px;
}

.btn-submit:hover:not(:disabled) {
	transform: translateY(-1px);
	box-shadow: 0 8px 20px rgba(37, 99, 235, 0.3);
}

.btn-submit:disabled {
	background: #cbd5e1;
	cursor: not-allowed;
}

/* Modal Overlay & Consistency Styling */
.overlay {
	position: fixed;
	inset: 0;
	background: rgba(15, 23, 42, 0.7);
	display: none;
	align-items: center;
	justify-content: center;
	z-index: 9999;
	backdrop-filter: blur(8px);
	padding: 20px;
}

.overlay.show {
	display: flex;
}

.modal {
	width: 100%;
	max-width: 440px;
	background: #fff;
	border-radius: 32px;
	padding: 48px;
	text-align: center;
	box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
	animation: slideUp 0.3s ease;
}

@
keyframes slideUp {
	from {opacity: 0;
	transform: translateY(20px);
}

to {
	opacity: 1;
	transform: translateY(0);
}

}
.btn-modal-cancel {
	background: #f1f5f9;
	color: #64748b;
	font-weight: 800;
}

.btn-modal-cancel:hover {
	background: #e2e8f0;
	color: #1e293b;
}

.req-star {
	color: #ef4444;
}
</style>
</head>
<body class="flex">

	<jsp:include page="sidebar.jsp" />

	<main
		class="flex-1 ml-20 lg:ml-64 min-h-screen transition-all duration-300">
		<jsp:include page="topbar.jsp" />

		<div class="pageWrap">
			<div class="flex justify-between items-end mb-4">
				<div>
					<h2 class="title">Apply Leave</h2>
					<span class="sub-label">Submit your leave request for administrative approval</span>
				</div>
			</div>

			<div class="card">
				<div id="errorBox" class="validation-error">
					<%=AlertIcon("w-5 h-5")%>
					<span id="errorMessage"></span>
				</div>

				<form action="ApplyLeave" method="post"
					enctype="multipart/form-data" id="applyForm"
					onsubmit="return handleApplyForm(event)">

					<div class="form-grid">
						<div>
							<label>Type of Leave <span class="req-star">*</span></label> <select
								name="leaveTypeId" id="leaveTypeId" required
								onchange="handleTypeChange(); validateForm();">
								<option value="" disabled selected>-- SELECT TYPE --</option>
								<%
								for (Map<String, Object> t : leaveTypes) {
									String id = String.valueOf(t.get("id"));
									String code = String.valueOf(t.get("code")).trim().toUpperCase();
									String desc = (t.get("desc") != null) ? String.valueOf(t.get("desc")).trim().toUpperCase() : "";

									boolean canView = true;
									if ((code.contains("MATERNITY") || code.equals("ML")) && !isFemale)
										canView = false;
									if ((code.contains("PATERNITY") || code.equals("PL")) && !isMale)
										canView = false;

									if (canView) {
								%>
								<option value="<%=id%>" data-code="<%=code%>"><%=code%></option>
								<%
								}
								}
								%>
							</select>
							<div id="balanceHint"
								class="text-[10px] font-black text-blue-600 uppercase mt-2 hidden">
								Available Balance: <span id="hintDays">0</span> Days
							</div>
						</div>

						<div>
							<label>Leave Period <span class="req-star">*</span></label>
							<div class="duration-options">
								<label class="duration-tile selected"
									onclick="selectDuration(this)"> <input type="radio"
									name="duration" value="FULL_DAY" checked
									onchange="syncDates(); validateForm();"> <span>Full
										Day</span>
								</label> <label class="duration-tile" onclick="selectDuration(this)">
									<input type="radio" name="duration" value="HALF_DAY_AM"
									onchange="syncDates(); validateForm();"> <span>Half
										(AM)</span>
								</label> <label class="duration-tile" onclick="selectDuration(this)">
									<input type="radio" name="duration" value="HALF_DAY_PM"
									onchange="syncDates(); validateForm();"> <span>Half
										(PM)</span>
								</label>
							</div>
						</div>

						<div id="dynamicAttributes" class="dynamic-attributes">
							<div class="flex items-center gap-3 mb-6">
								<div class="w-1.5 h-5 bg-blue-600 rounded-full"></div>
								<span
									class="text-[11px] font-black text-blue-600 uppercase tracking-widest">Additional
									Details Required</span>
							</div>
							<div id="dynamicFields" class="dynamic-grid"></div>
						</div>
					</div>

					<div class="form-grid">
						<div>
							<label>Start Date <span class="req-star">*</span></label> <input
								type="date" name="startDate" id="startDate" required
								onchange="syncDates(); validateForm();" />
						</div>
						<div>
							<label>End Date <span class="req-star">*</span></label> <input
								type="date" name="endDate" id="endDate" required
								onchange="validateForm();" />
						</div>
					</div>

					<div class="mb-8">
						<label>Reason for Leave <span class="req-star">*</span></label>
						<textarea name="reason" id="reason" required
							placeholder="EXPLAIN WHY YOU ARE TAKING THIS LEAVE..."></textarea>
					</div>

					<div class="mb-10">
						<label>Supportive Attachment <span id="docRequired"
							style="display: none;" class="req-star">(REQUIRED *)</span></label> <input
							type="file" name="attachment" id="attachment"
							accept=".pdf,.png,.jpg,.jpeg"
							class="bg-slate-50 border-dashed border-2 border-slate-200 p-10 cursor-pointer text-center w-full rounded-2xl hover:bg-slate-100 transition-all text-xs font-bold text-slate-400" />
						<p
							class="text-[10px] text-slate-400 mt-3 font-bold uppercase tracking-tight text-center">Upload
							MC or verification letter. Max 5MB.</p>
					</div>

					<button type="submit" id="submitBtn" class="btn-submit">
						<%=SendIcon("w-5 h-5")%>
						Submit Application
					</button>
				</form>
			</div>
		</div>
	</main>

	<div class="overlay" id="confirmOverlay">
		<div class="modal">
			<div
				class="bg-blue-50 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6 text-blue-600">
				<%=SendIcon("w-10 h-10")%>
			</div>
			<h3
				class="text-xl font-black uppercase tracking-tight text-slate-900">Confirm
				Submission</h3>
			<p
				class="text-slate-500 text-sm mt-3 mb-10 leading-relaxed font-medium">
				Are you sure you want to submit this <b
					class="text-slate-900 uppercase" id="confirmTypeSpan"></b> request?
				Please ensure all details are accurate.
			</p>

			<div class="flex gap-3">
				<button type="button" onclick="closeConfirmModal()"
					class="btn-submit btn-modal-cancel flex-1">Cancel</button>
				<button type="button" onclick="submitFinalForm()"
					class="btn-submit flex-1 shadow-lg shadow-blue-100">Confirm</button>
			</div>
		</div>
	</div>

	<div class="overlay" id="successOverlay">
		<div class="modal">
			<div
				class="bg-emerald-50 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6 text-emerald-500">
				<%=CheckCircleIcon("w-10 h-10")%>
			</div>
			<h3
				class="text-xl font-black uppercase tracking-tight text-slate-900">Success!</h3>
			<p
				class="text-slate-500 text-sm mt-3 mb-10 leading-relaxed font-medium uppercase">Your
				leave application has been submitted and is pending review by your
				manager.</p>
			<button class="btn-submit" onclick="location.href='LeaveHistory'">Go
				to History</button>
		</div>
	</div>

	<script>
    const leaveBalances = {
        <%for (LeaveBalance b : balances) {%>
            "<%=b.getLeaveTypeId()%>": <%=b.getTotalAvailable()%>,
        <%}%>
    };

    const startEl = document.getElementById('startDate');
    const endEl = document.getElementById('endDate');
    const today = new Date().toLocaleDateString('en-CA'); 
    startEl.setAttribute('min', today);
    endEl.setAttribute('min', today);
    const typeEl = document.getElementById('leaveTypeId');
    const attachmentEl = document.getElementById('attachment');
    const dynamicAttr = document.getElementById('dynamicAttributes');
    const dynamicFields = document.getElementById('dynamicFields');
    const docReqLabel = document.getElementById('docRequired');
    const errorBox = document.getElementById('errorBox');
    const errorMessage = document.getElementById('errorMessage');
    const submitBtn = document.getElementById('submitBtn');
    const balanceHint = document.getElementById('balanceHint');
    const hintDays = document.getElementById('hintDays');

    // MODAL LOGIC
    function handleApplyForm(event) {
        event.preventDefault();
        const typeText = typeEl.options[typeEl.selectedIndex].text.split('-')[0].trim();
        document.getElementById('confirmTypeSpan').textContent = typeText;
        document.getElementById('confirmOverlay').classList.add('show');
        return false;
    }

    function closeConfirmModal() {
        document.getElementById('confirmOverlay').classList.remove('show');
    }

    function submitFinalForm() {
        document.getElementById('applyForm').submit();
    }

    function selectDuration(element) {
      document.querySelectorAll('.duration-tile').forEach(t => t.classList.remove('selected'));
      element.classList.add('selected');
      const radio = element.querySelector('input[type="radio"]');
      if (radio) { 
        radio.checked = true; 
        syncDates();
        validateForm();
      }
    }

    function syncDates() {
        if (startEl.value) {
          endEl.setAttribute('min', startEl.value);
        }

        const durationInput = document.querySelector('input[name="duration"]:checked');
        if (durationInput && durationInput.value !== 'FULL_DAY') {
          endEl.value = startEl.value;
          endEl.readOnly = true;
          endEl.style.setProperty('background-color', '#f8fafc', 'important'); 
          endEl.style.setProperty('color', '#94a3b8', 'important');
          endEl.style.cursor = 'not-allowed';
        } else {
          endEl.readOnly = false;
          endEl.style.setProperty('background-color', '#fff', 'important');
	      endEl.style.setProperty('color', 'inherit', 'important');
	      endEl.style.cursor = 'text';
      }
    }

    function calculateWorkingDaysJS(start, end) {
        if (!start || !end) return 0;
        let dStart = new Date(start);
        let dEnd = new Date(end);
        if (dEnd < dStart) return 0;
        let count = 0;
        let cur = new Date(dStart);
        while (cur <= dEnd) {
            let day = cur.getDay();
            if (day !== 0 && day !== 6) count++; 
            cur.setDate(cur.getDate() + 1);
        }
        return count;
    }

    function validateForm() {
        const startVal = startEl.value;
        const endVal = endEl.value;
        const typeId = typeEl.value;
        const duration = document.querySelector('input[name="duration"]:checked').value;

        let hasError = false;
        let msg = "";

        if (typeId) {
            const avail = leaveBalances[typeId] !== undefined ? leaveBalances[typeId] : 0;
            hintDays.textContent = avail;
            balanceHint.classList.remove('hidden');
        } else {
            balanceHint.classList.add('hidden');
        }

        if (startVal && endVal) {
            const d1 = new Date(startVal);
            const d2 = new Date(endVal);
            if (d2 < d1) {
                hasError = true;
                msg = "Conclusion date cannot be earlier than commencement date.";
            }
        }

        if (!hasError && startVal && endVal && typeId) {
            const available = leaveBalances[typeId] !== undefined ? parseFloat(leaveBalances[typeId]) : 0;
            let requested = (duration !== 'FULL_DAY') ? 0.5 : calculateWorkingDaysJS(startVal, endVal);

            if (requested > available) {
                hasError = true;
                msg = `Insufficient balance. Available: ${available} Days, Requested: ${requested} Days.`;
            }
            
            if (!hasError && requested === 0 && startVal && endVal) {
                hasError = true;
                msg = "You cannot apply for leave on weekends (Saturday/Sunday).";
            }
        }

        if (hasError) {
            errorMessage.textContent = msg;
            errorBox.style.display = 'flex';
            submitBtn.disabled = true;
        } else {
            errorBox.style.display = 'none';
            submitBtn.disabled = false;
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
          addInput("clinicName", "Clinic / Hospital Name", "text", true, "E.G. KLINIK KESIHATAN");
          addInput("mcSerialNumber", "MC Serial Number", "text", true, "E.G. MC88721");
          setRequired(true);
      } else if (code.includes("HOSPITAL") || code === "HL") {
          addInput("hospitalName", "Hospital Facility", "text", true, "HOSPITAL NAME");
          addInput("admissionDate", "Admission Date", "date", true, "");
          addInput("dischargeDate", "Discharge Date", "date", true, "");
          setRequired(true);
      } else if (code.includes("MATERNITY") || code === "ML") {
          addInput("maternityClinic", "Consultation Clinic", "text", true, "CLINIC NAME");
          addInput("expectedDueDate", "Expected Due Date", "date", true, "");
          addInput("weekPregnancy", "Week of Pregnancy", "number", true, "E.G. 32");
          setRequired(true);
      } else if (code.includes("PATERNITY") || code === "PL") {
          addInput("spouseName", "Spouse Full Name", "text", true, "FULL NAME");
          addInput("hospitalLocation", "Hospital Location", "text", true, "HOSPITAL NAME/CITY");
          addInput("deliveryDate", "Date of Delivery", "date", true, "");
          setRequired(false);
      } else if (code.includes("EMERGENCY") || code === "EL") {
          addSelect("emergencyCategory", "Emergency Category", true, [
              {v: "ACCIDENT", l: "ACCIDENT"}, {v: "DEATH", l: "DEATH (FAMILY)"}, {v: "DISASTER", l: "NATURAL DISASTER"}, {v: "MEDICAL_FAMILY", l: "FAMILY MEDICAL EMERGENCY"}, {v: "OTHER", l: "OTHERS"}
          ]);
          addInput("emergencyContact", "Emergency Contact No", "tel", true, "01X-XXXXXXX");
          setRequired(false);
      }
    }

    function addInput(name, labelText, type, req, ph) {
        dynamicAttr.style.display = "block"; 
        const div = createFieldContainer(labelText, req);
        const input = document.createElement('input');
        input.type = type; input.name = name; input.placeholder = ph;
        if (req) input.required = true;
        input.onchange = validateForm;
        div.appendChild(input);
        dynamicFields.appendChild(div);
    }

    function addSelect(name, labelText, req, options) {
        dynamicAttr.style.display = "block";
        const div = createFieldContainer(labelText, req);
        const select = document.createElement('select');
        select.name = name; if (req) select.required = true;
        select.add(new Option("-- SELECT --", ""));
        options.forEach(opt => select.add(new Option(opt.l, opt.v)));
        select.onchange = validateForm;
        div.appendChild(select);
        dynamicFields.appendChild(div);
    }

    function createFieldContainer(labelText, req) {
        const div = document.createElement('div'); div.className = "flex flex-col gap-2";
        const label = document.createElement('label'); label.textContent = labelText; 
        if (req) { const star = document.createElement('span'); star.className = "req-star"; star.textContent = " *"; label.appendChild(star); }
        div.appendChild(label);
        return div;
    }

    function setRequired(val) { docReqLabel.style.display = val ? "inline" : "none"; attachmentEl.required = val; }

    document.addEventListener('input', function(e) {
        if(e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
            if(e.target.type !== 'date' && e.target.type !== 'email' && e.target.type !== 'password' && e.target.type !== 'file') {
                e.target.value = e.target.value.toUpperCase();
            }
        }
    });

    const params = new URLSearchParams(window.location.search);
    if(params.get("msg") === "success") document.getElementById("successOverlay").classList.add("show");
  </script>
</body>

</html>
