<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="bean.User" %>
<%@ include file="icon.jsp" %>

<%
// SECURITY CHECK
if (session.getAttribute("empid") == null) {
    response.sendRedirect("login.jsp?error=Please login.");
    return;
}

// DATA & LOGIC
User userObj = (User) request.getAttribute("user");
boolean editMode = "1".equals(request.getParameter("edit"));

String displayEmpId = "N/A";
String displayHireDate = "N/A";
String displayIc = "N/A";
String displayGender = "—";
String init = "U";
String profilePic = null;
String combinedAddress = "—";

if (userObj != null) {
    profilePic = userObj.getProfilePic();
    String nm = userObj.getFullName();
    if (nm != null && !nm.isBlank()) {
        init = ("" + nm.charAt(0)).toUpperCase();
    }

    if (userObj.getHireDate() != null) {
        Calendar cal = Calendar.getInstance();
        cal.setTime(userObj.getHireDate());
        int year = cal.get(Calendar.YEAR);
        displayEmpId = "EMP-" + year + "-" + String.format("%02d", userObj.getEmpId());
        
        SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy");
        displayHireDate = sdf.format(userObj.getHireDate()).toUpperCase();
    }

    String rawIc = userObj.getIcNumber();
    if (rawIc != null && rawIc.length() == 12) {
        displayIc = rawIc.substring(0, 6) + "-" + rawIc.substring(6, 8) + "-" + rawIc.substring(8);
    }

    String g = userObj.getGender();
    displayGender = "M".equalsIgnoreCase(g) ? "MALE" : ("F".equalsIgnoreCase(g) ? "FEMALE" : "—");

    List<String> addrParts = new ArrayList<>();
    if (userObj.getStreet() != null && !userObj.getStreet().isBlank()) addrParts.add(userObj.getStreet().toUpperCase());
    if (userObj.getPostalCode() != null && !userObj.getPostalCode().isBlank()) addrParts.add(userObj.getPostalCode());
    if (userObj.getCity() != null && !userObj.getCity().isBlank()) addrParts.add(userObj.getCity().toUpperCase());
    if (userObj.getState() != null && !userObj.getState().isBlank()) addrParts.add(userObj.getState().toUpperCase());
    
    combinedAddress = !addrParts.isEmpty() ? String.join(", ", addrParts) : "NO ADDRESS RECORDED.";
}
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile | Klinik Dr Mohamad</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">

    <style>
        :root {
            --bg: #f1f5f9;
            --card: #ffffff;
            --border: #e2e8f0;
            --text: #1e293b;
            --blue: #2563eb;
            --blue-hover: #1d4ed8;
            --radius: 20px;
        }

        * { box-sizing: border-box; font-family: 'Inter', sans-serif !important; }
        body { margin: 0; background: var(--bg); color: var(--text); overflow-x: hidden; -webkit-font-smoothing: antialiased; }

        .pageWrap { max-width: 1300px; margin: 0; padding: 24px 40px; }
        
        h2.title { font-size: 26px; font-weight: 800; margin: 0; text-transform: uppercase; color: var(--text); letter-spacing: -0.02em; }
        .sub-label { color: var(--blue); font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.1em; margin-top: 4px; display: block; }

        .card { background: var(--card); border: 1px solid var(--border); border-radius: var(--radius); box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.04); overflow: hidden; }

        .profile-layout { display: grid; grid-template-columns: 280px 1fr; gap: 24px; margin-top: 16px; }
        @media (max-width: 950px) { .profile-layout { grid-template-columns: 1fr; } }

        .label-xs { font-size: 14px; font-weight: 900; color: #233f66; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 4px; display: block; }
        .val-text { font-size: 14px; font-weight: 600; color: var(--text); text-transform: uppercase; }

        /* INPUT BOX PADDING AND STYLING */
        .pageWrap input, .pageWrap select {
            width: 100% !important; 
            padding: 0 20px !important; 
            height: 52px !important;
            border: 2px solid #e2e8f0 !important;
            border-radius: 12px !important; 
            font-size: 14px !important; 
            font-weight: 600 !important; 
            background: #fff !important; 
            color: var(--text) !important;
            outline: none !important;
            display: block !important;
            box-sizing: border-box !important;
            transition: all 0.2s;
            text-transform: uppercase;
        }
        .pageWrap input:focus, .pageWrap select:focus { border-color: var(--blue) !important; box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.08) !important; }

        /* IN-BOX CONSTRAINT STYLING */
        .pageWrap input.invalid-field {
            border-color: #ef4444 !important;
            background-color: #fff1f2 !important;
        }

        .pageWrap .read-only-box { 
            background: #f1f5f9 !important; 
            color: #94a3b8 !important; 
            cursor: not-allowed; 
            border-color: #e2e8f0 !important;
        }

        .avatar-sq {
            width: 110px; height: 110px; border-radius: 24px; margin-bottom: 12px;
            background: #f1f5f9;
            color: #fff; overflow: hidden; position: relative;
            box-shadow: 0 8px 15px -3px rgba(0, 0, 0, 0.08);
        }
        .avatar-sq img { width: 100%; height: 100%; object-fit: cover; display: block; }

        #avatarInit {
            width: 100%; height: 100%;
            background: linear-gradient(135deg, #2563eb 0%, #3b82f6 100%);
            display: flex; align-items: center; justify-content: center;
            font-weight: 800; font-size: 42px;
        }
        
        .avatar-overlay {
            position: absolute; inset: 0; background: rgba(15, 23, 42, 0.6);
            display: flex; align-items: center; justify-content: center;
            opacity: 0; transition: 0.2s; cursor: pointer;
        }
        .avatar-sq:hover .avatar-overlay { opacity: 1; }

        .btn { padding: 0 24px; height: 46px; border-radius: 14px; font-weight: 800; font-size: 12px; transition: 0.2s; display: inline-flex; align-items: center; justify-content: center; gap: 10px; cursor: pointer; text-transform: uppercase; border: none; letter-spacing: 0.05em; }
        .btn-blue { background: var(--blue); color: #fff; }
        .btn-blue:hover { background: var(--blue-hover); transform: translateY(-1px); }
        .btn-ghost { background: #f1f5f9; color: #64748b; }
        
        /* 3-SECOND SUCCESS MESSAGE STYLE */
        #statusToast {
            position: fixed; top: -100px; left: 50%; transform: translateX(-50%);
            padding: 16px 32px; border-radius: 12px; font-weight: 800; font-size: 13px; 
            text-transform: uppercase; z-index: 9999; transition: all 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275);
            display: flex; align-items: center; gap: 12px; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1);
            letter-spacing: 0.05em;
        }
        #statusToast.show { top: 30px; }
        .toast-success { background: #10b981; color: white; }
        .toast-error { background: #ef4444; color: white; }
    </style>
</head>
<body class="flex">

<div id="statusToast">
    <span id="toastIcon"></span>
    <span id="toastMessage"></span>
</div>

<jsp:include page="sidebar.jsp" />

<main class="ml-20 lg:ml-64 min-h-screen flex-1 transition-all duration-300">
    <jsp:include page="topbar.jsp" />

    <div class="pageWrap">
        <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-2">
            <div>
                <h2 class="title">MY ACCOUNT</h2>
                <span class="sub-label">Employee profile settings</span>
            </div>
            <% if (!editMode) { %>
                <a href="Profile?edit=1" class="btn btn-blue shadow-lg shadow-blue-500/10">
                    <%= EditIcon("icon-sm") %> Edit Profile
                </a>
            <% } %>
        </div>

        <% if (editMode) { %>
        <form action="Profile" method="post" enctype="multipart/form-data" id="profileForm">
        <% } %>

        <div class="profile-layout">
            <div class="flex flex-col gap-4">
                <div class="card p-6 flex flex-col items-center text-center">
                    <div class="avatar-sq" id="avatarContainer">
                        <% if (profilePic != null && !profilePic.isBlank()) { %>
                            <img src="<%= profilePic %>" alt="Profile" id="avatarImg">
                        <% } else { %>
                            <span id="avatarInit"><%= init %></span>
                        <% } %>
                        <% if (editMode) { %>
                            <div class="avatar-overlay" onclick="document.getElementById('profilePicInput').click()">
                                <%= EditIcon("w-6 h-6 text-white") %>
                            </div>
                            <input type="file" name="profilePic" id="profilePicInput" accept="image/*" hidden onchange="previewImage(this)">
                        <% } %>
                    </div>
                    
                    <div class="flex flex-col items-center gap-1 mt-0">
                        <span class="text-[10px] font-black text-blue-600 uppercase tracking-widest"><%= userObj.getRole() %></span>
                        <span class="px-2 py-0.5 rounded text-[9px] font-black uppercase <%= "ACTIVE".equalsIgnoreCase(userObj.getStatus()) ? "bg-emerald-50 text-emerald-600" : "bg-red-50 text-red-600" %> border border-current">
                            <%= userObj.getStatus() != null ? userObj.getStatus() : "ACTIVE" %>
                        </span>
                    </div>
                    
                    <div class="w-full mt-6 pt-6 border-t border-slate-100 space-y-4 text-left">
                        <div><span class="label-xs" style="font-size: 11px;">Employment ID</span><span class="val-text text-blue-600 font-bold"><%= displayEmpId %></span></div>
                        <div><span class="label-xs" style="font-size: 11px;">IC / NRIC Number</span><span class="val-text"><%= displayIc %></span></div>
                        <div><span class="label-xs" style="font-size: 11px;">Date of Joining</span><span class="val-text"><%= displayHireDate %></span></div>
                    </div>
                </div>
            </div>

            <div class="card">
                <div class="px-8 py-3 border-b border-slate-50 bg-slate-50/30"><span class="text-[9px] font-black text-slate-400 uppercase tracking-widest">Personal Identification</span></div>
                <div class="p-8">
                <% if (!editMode) { %>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-y-6 gap-x-12">
                        <div class="md:col-span-2"><span class="label-xs">Full  Name</span><p class="text-2xl font-black text-slate-900 tracking-tight uppercase leading-tight"><%= userObj.getFullName() %></p></div>
                        <div><span class="label-xs">Primary Email</span><p class="val-text text-slate-500"><%= userObj.getEmail() %></p></div>
                        <div><span class="label-xs">Mobile Contact</span><p class="val-text"><%= (userObj.getPhone() != null && !userObj.getPhone().isEmpty()) ? userObj.getPhone() : "—" %></p></div>
                        <div><span class="label-xs">Gender</span><p class="val-text"><%= displayGender %></p></div>
                        <div class="md:col-span-2"><span class="label-xs">Residential Address</span><p class="val-text leading-relaxed text-slate-600" style="font-weight: 500;"><%= combinedAddress %></p></div>
                    </div>
                <% } else { %>
                    <div class="space-y-5">
                        <div class="space-y-1"><span class="label-xs">Full Legal Name</span><input value="<%= userObj.getFullName() %>" class="read-only-box" disabled></div>
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div class="space-y-1"><span class="label-xs">Email</span><input value="<%= userObj.getEmail() %>" class="read-only-box" disabled></div>
                            <div class="space-y-1">
                                <span class="label-xs">Phone</span>
                                <input name="phone" id="phone" type="text" value="<%= userObj.getPhone() != null ? userObj.getPhone() : "" %>" placeholder="012-3456789">
                            </div>
                        </div>
                        <div class="pt-4 border-t border-slate-100 space-y-4">
                            <div class="space-y-1"><span class="label-xs">Street Name</span><input name="street" type="text" value="<%= userObj.getStreet() != null ? userObj.getStreet() : "" %>"></div>
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div class="space-y-1"><span class="label-xs">City</span><input name="city" type="text" value="<%= userObj.getCity() != null ? userObj.getCity() : "" %>"></div>
                                <div class="space-y-1">
                                    <span class="label-xs">Postal Code</span>
                                    <input name="postalCode" id="postalCode" type="text" value="<%= userObj.getPostalCode() != null ? userObj.getPostalCode() : "" %>" maxlength="5">
                                </div>
                            </div>
                            <div class="space-y-1">
                                <span class="label-xs">State / Region</span>
                                <select name="state">
                                    <option value="" disabled <%= userObj.getState() == null ? "selected" : "" %>>SELECT STATE</option>
                                    <optgroup label="PENINSULAR MALAYSIA">
                                        <option value="JOHOR" <%= "JOHOR".equalsIgnoreCase(userObj.getState()) ? "selected" : "" %>>JOHOR</option>
                                        <option value="KEDAH" <%= "KEDAH".equalsIgnoreCase(userObj.getState()) ? "selected" : "" %>>KEDAH</option>
                                        <option value="KELANTAN" <%= "KELANTAN".equalsIgnoreCase(userObj.getState()) ? "selected" : "" %>>KELANTAN</option>
                                        <option value="MELAKA" <%= "MELAKA".equalsIgnoreCase(userObj.getState()) ? "selected" : "" %>>MELAKA</option>
                                        <option value="NEGERI SEMBILAN" <%= "NEGERI SEMBILAN".equalsIgnoreCase(userObj.getState()) ? "selected" : "" %>>NEGERI SEMBILAN</option>
                                        <option value="PAHANG" <%= "PAHANG".equalsIgnoreCase(userObj.getState()) ? "selected" : "" %>>PAHANG</option>
                                        <option value="PERAK" <%= "PERAK".equalsIgnoreCase(userObj.getState()) ? "selected" : "" %>>PERAK</option>
                                        <option value="PERLIS" <%= "PERLIS".equalsIgnoreCase(userObj.getState()) ? "selected" : "" %>>PERLIS</option>
                                        <option value="PENANG" <%= "PENANG".equalsIgnoreCase(userObj.getState()) ? "selected" : "" %>>PENANG</option>
                                        <option value="SELANGOR" <%= "SELANGOR".equalsIgnoreCase(userObj.getState()) ? "selected" : "" %>>SELANGOR</option>
                                        <option value="TERENGGANU" <%= "TERENGGANU".equalsIgnoreCase(userObj.getState()) ? "selected" : "" %>>TERENGGANU</option>
                                    </optgroup>
                                    <optgroup label="FEDERAL TERRITORIES">
                                        <option value="KUALA LUMPUR" <%= "KUALA LUMPUR".equalsIgnoreCase(userObj.getState()) ? "selected" : "" %>>KUALA LUMPUR</option>
                                        <option value="PUTRAJAYA" <%= "PUTRAJAYA".equalsIgnoreCase(userObj.getState()) ? "selected" : "" %>>PUTRAJAYA</option>
                                        <option value="LABUAN" <%= "LABUAN".equalsIgnoreCase(userObj.getState()) ? "selected" : "" %>>LABUAN</option>
									</optgroup>
                                              <optgroup label="EAST MALAYSIA">
                                        <option value="SABAH" <%= "SABAH".equalsIgnoreCase(userObj.getState()) ? "selected" : "" %>>SABAH</option>
                                        <option value="SARAWAK" <%= "SARAWAK".equalsIgnoreCase(userObj.getState()) ? "selected" : "" %>>SARAWAK</option>
                                    </optgroup>
                                </select>
                            </div>
                        </div>
                        <div class="flex justify-end gap-3 pt-6 border-t border-slate-100">
                            <a href="Profile" class="btn btn-ghost">Discard</a>
                            <button type="submit" class="btn btn-blue shadow-lg shadow-blue-500/20"><%= SaveIcon("w-4 h-4") %> Save Changes</button>
                        </div>
                    </div>
                <% } %>
                </div>
            </div>
        </div>
        <% if (editMode) { %></form><% } %>
    </div>
</main>

<script>
    // 1. SUCCESS / ERROR MESSAGE (3 SECONDS)
    window.addEventListener('load', () => {
        const urlParams = new URLSearchParams(window.location.search);
        const msg = urlParams.get('msg');
        const error = urlParams.get('error');
        
        if (msg || error) {
            const toast = document.getElementById('statusToast');
            const toastMsg = document.getElementById('toastMessage');
            const toastIcon = document.getElementById('toastIcon');
            
            if (msg) {
                toast.className = 'toast-success';
                toastMsg.textContent = msg.toUpperCase();
                toastIcon.innerHTML = `<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"></path></svg>`;
            } else {
                toast.className = 'toast-error';
                toastMsg.textContent = error.toUpperCase();
                toastIcon.innerHTML = `<svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>`;
            }
            
            toast.classList.add('show');
            setTimeout(() => {
                toast.classList.remove('show');
                const newUrl = window.location.protocol + "//" + window.location.host + window.location.pathname;
                window.history.replaceState({path:newUrl}, '', newUrl);
            }, 3000);
        }
    });

    // 2. INPUT FORMATTING (CAPS, PHONE, POSTAL)
    document.querySelectorAll('input').forEach(el => {
        el.addEventListener('input', function() {
            this.value = this.value.toUpperCase();
            this.classList.remove('invalid-field'); // Clear error on type

            if (this.id === 'phone') {
                let val = this.value.replace(/\D/g, '').slice(0, 11);
                if (val.length > 3) {
                    this.value = val.substring(0, 3) + '-' + val.substring(3);
                } else { this.value = val; }
            }
            if (this.id === 'postalCode') {
                this.value = this.value.replace(/\D/g, '').slice(0, 5);
            }
        });
    });

    // 3. ON-BOX CONSTRAINTS (NO ALERT)
    const form = document.getElementById('profileForm');
    if(form) {
        form.addEventListener('submit', function(e) {
            let isValid = true;
            const phone = document.getElementById('phone');
            const postal = document.getElementById('postalCode');

            if (phone.value.replace(/-/g, '').length < 10) {
                phone.classList.add('invalid-field');
                isValid = false;
            }
            if (postal.value.length !== 5) {
                postal.classList.add('invalid-field');
                isValid = false;
            }

            if (!isValid) e.preventDefault();
        });
    }

    function previewImage(input) {
        if (input.files && input.files[0]) {
            const reader = new FileReader();
            reader.onload = (e) => {
                let img = document.getElementById('avatarImg');
                if (!img) {
                    const init = document.getElementById('avatarInit');
                    if (init) init.remove();
                    img = document.createElement('img');
                    img.id = 'avatarImg';
                    img.className = 'w-full h-full object-cover';
                    document.getElementById('avatarContainer').insertBefore(img, document.getElementById('avatarContainer').firstChild);
                }
                img.src = e.target.result;
            }
            reader.readAsDataURL(input.files[0]);
        }
    }
</script>

</body>
</html>