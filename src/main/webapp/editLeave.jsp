<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<style>
.edit-grid {
	display: grid;
	grid-template-columns: 1fr 1fr;
	gap: 20px;
}

.dynamic-edit-box {
	grid-column: span 2;
	background: #f8fafc;
	border: 1px solid #e2e8f0;
	padding: 20px;
	border-radius: 12px;
	display: none;
	margin: 10px 0;
	animation: fadeIn 0.3s ease;
}

@
keyframes fadeIn {from { opacity:0;
	
}

to {
	opacity: 1;
}

}
.edit-field label {
	display: block;
	font-size: 11px;
	font-weight: 700;
	color: #64748b;
	text-transform: uppercase;
	margin-bottom: 5px;
}

.edit-field input, .edit-field select, .edit-field textarea {
	width: 100%;
	border: 1px solid #cbd5e1;
	border-radius: 8px;
	padding: 10px;
	font-size: 14px;
	outline: none;
}

.edit-field input:focus, .edit-field select:focus {
	border-color: #2563eb;
	box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
}
</style>
</head>
<body>

	<form id="editForm">
		<input type="hidden" id="editLeaveId" name="leaveId">

		<div class="edit-grid">
			<div class="edit-field" style="grid-column: 1/-1;">
				<label>Type of Leave</label> <select id="editLeaveType"
					name="leaveType" required onchange="handleEditTypeChange()"></select>
			</div>

			<div class="edit-field">
				<label>Start Date</label> <input type="date" id="editStartDate"
					name="startDate" required onchange="syncEditDates()">
			</div>

			<div class="edit-field">
				<label>End Date</label> <input type="date" id="editEndDate"
					name="endDate" required>
			</div>

			<div class="edit-field" style="grid-column: 1/-1;">
				<label>Duration Period</label> <select id="editDuration"
					name="duration" required onchange="syncEditDates()">
					<option value="FULL_DAY">Full Day</option>
					<option value="HALF_DAY_AM">Half Day (AM)</option>
					<option value="HALF_DAY_PM">Half Day (PM)</option>
				</select>
			</div>

			<!-- Container for Dynamic Fields -->
			<div id="editDynamicBox" class="dynamic-edit-box">
				<div id="editDynamicFields" class="edit-grid" style="gap: 15px;"></div>
			</div>

			<div class="edit-field" style="grid-column: 1/-1;">
				<label>Reason</label>
				<textarea id="editReason" name="reason" required
					style="height: 80px;"></textarea>
			</div>
		</div>

		<div class="edit-actions"
			style="margin-top: 25px; display: flex; gap: 10px; justify-content: flex-end;">
			<button type="button" class="btn-modal btn-gray"
				onclick="closeEditModal()">Cancel</button>
			<button type="submit" class="btn-modal btn-blue" id="editSubmitBtn">Save
				Changes</button>
		</div>
	</form>

	<script>
    // Global variable to store metadata returned by the EditLeave Servlet
    let currentMetadata = {};

    /**
     * This function should be called by the parent page (e.g., leaveHistory.jsp)
     * after fetching the leave data to populate the fields and metadata.
     */
    window.populateEditModal = function(data) {
        document.getElementById('editLeaveId').value = data.leaveId;
        document.getElementById('editStartDate').value = data.startDate;
        document.getElementById('editEndDate').value = data.endDate;
        document.getElementById('editReason').value = data.reason || "";
        
        // Store metadata for the dynamic field generators to use
        currentMetadata = {
            med: data.med || "",
            ref: data.ref || "",
            cat: data.cat || "",
            cnt: data.cnt || "",
            spo: data.spo || ""
        };

        // Set combined duration
        let durValue = data.duration || "FULL_DAY";
        if(durValue === 'HALF_DAY') {
            durValue = data.halfSession === 'PM' ? 'HALF_DAY_PM' : 'HALF_DAY_AM';
        }
        document.getElementById('editDuration').value = durValue;

        // Populate Types and ensure data-code is attached
        const typeSelect = document.getElementById('editLeaveType');
        typeSelect.innerHTML = "";
        if (data.leaveTypes) {
            data.leaveTypes.forEach(t => {
                const opt = document.createElement('option');
                opt.value = t.id;
                opt.text = (t.code) + (t.desc ? " - " + t.desc : "");
                opt.setAttribute('data-code', t.code); // CRITICAL: This allows handleEditTypeChange to work
                if(t.id == data.leaveTypeId) opt.selected = true;
                typeSelect.add(opt);
            });
        }

        // Trigger dynamic field generation and date syncing
        handleEditTypeChange();
        syncEditDates();
    };

    function syncEditDates() {
      const dur = document.getElementById('editDuration').value;
      const start = document.getElementById('editStartDate');
      const end = document.getElementById('editEndDate');
      if (dur !== 'FULL_DAY') {
        end.value = start.value;
        end.readOnly = true;
        end.style.background = "#f1f5f9";
      } else {
        end.readOnly = false;
        end.style.background = "#fff";
      }
    }

    function handleEditTypeChange() {
      const sel = document.getElementById('editLeaveType');
      const selectedOpt = sel.options[sel.selectedIndex];
      const code = selectedOpt ? selectedOpt.getAttribute('data-code').toUpperCase() : "";
      const box = document.getElementById('editDynamicBox');
      const container = document.getElementById('editDynamicFields');

      container.innerHTML = "";
      box.style.display = "none";

      // Check code for specific leave type logic (Sick, Emergency, Paternity)
      if (code.includes("SL") || code.includes("SICK")) {
          addEditInput("medicalFacility", "Clinic Name", currentMetadata.med);
          addEditInput("refSerialNo", "MC Serial No", currentMetadata.ref);
          box.style.display = "block";
      } else if (code.includes("EL") || code.includes("EMERGENCY")) {
          addEditSelect("emergencyCategory", "Category", [
              {v:"ACCIDENT", l:"Accident / Kemalangan"}, 
              {v:"DEATH", l:"Death / Kematian"}, 
              {v:"MEDICAL_FAMILY", l:"Medical (Family)"},
              {v:"OTHER", l:"Other / Lain-lain"}
          ], currentMetadata.cat);
          addEditInput("emergencyContact", "Emergency Contact No", currentMetadata.cnt);
          box.style.display = "block";
      } else if (code.includes("PL") || code.includes("PATERNITY")) {
          addEditInput("spouseName", "Spouse Name", currentMetadata.spo);
          box.style.display = "block";
      }
    }

    function addEditInput(name, label, val) {
        const div = document.createElement('div');
        div.className = "edit-field";
        div.innerHTML = `<label>${label}</label><input type="text" name="${name}" value="${val || ''}" required>`;
        document.getElementById('editDynamicFields').appendChild(div);
    }

    function addEditSelect(name, label, opts, val) {
        const div = document.createElement('div');
        div.className = "edit-field";
        let html = `<label>${label}</label><select name="${name}" required><option value="">--Select--</option>`;
        opts.forEach(o => {
            html += `<option value="${o.v}" ${val === o.v ? 'selected' : ''}>${o.l}</option>`;
        });
        html += `</select>`;
        div.innerHTML = html;
        document.getElementById('editDynamicFields').appendChild(div);
    }
  </script>
</body>
</html>