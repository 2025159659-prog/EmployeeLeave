<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="bean.User" %>
<%@ include file="icon.jsp" %>

<%
// =========================
// SECURITY CHECK
// =========================
if (session.getAttribute("empid") == null) {
    response.sendRedirect("login.jsp?error=Please login.");
    return;
}

// =========================
// LOGIC & FORMATTING
// =========================
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
        displayHireDate = sdf.format(userObj.getHireDate());
    }

    String rawIc = userObj.getIcNumber();
    if (rawIc != null && rawIc.length() == 12) {
        displayIc = rawIc.substring(0, 6) + "-" + rawIc.substring(6, 8) + "-" + rawIc.substring(8);
    }

    String g = userObj.getGender();
    displayGender = "M".equalsIgnoreCase(g) ? "Male" : ("F".equalsIgnoreCase(g) ? "Female" : "—");

    List<String> addrParts = new ArrayList<>();
    if (userObj.getStreet() != null && !userObj.getStreet().isBlank()) addrParts.add(userObj.getStreet());
    if (userObj.getCity() != null && !userObj.getCity().isBlank()) addrParts.add(userObj.getCity());
    if (userObj.getPostalCode() != null && !userObj.getPostalCode().isBlank()) addrParts.add(userObj.getPostalCode());
    if (userObj.getState() != null && !userObj.getState().isBlank()) addrParts.add(userObj.getState());
    
    combinedAddress = !addrParts.isEmpty() ? String.join(", ", addrParts) : "No address recorded.";
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
            --bg: #f8fafc;
            --card: #ffffff;
            --border: #e2e8f0;
            --text: #1e293b;
            --muted: #64748b;
            --blue: #2563eb;
            --blue-hover: #1d4ed8;
            --radius: 16px;
        }

        * { box-sizing: border-box; font-family: 'Inter', sans-serif !important; }
        body { margin: 0; background: var(--bg); color: var(--text); overflow-x: hidden; -webkit-font-smoothing: antialiased; }

        .pageWrap { max-width: 1140px; margin: 0 auto; padding: 20px 40px; }
        
        h2.title { 
            font-size: 26px; 
            font-weight: 800; 
            margin: 0; 
            color: var(--text); 
            text-transform: uppercase; 
            letter-spacing: -0.025em;
        }
        
        .sub-label { 
            color: var(--blue); 
            font-size: 11px; 
            font-weight: 800; 
            text-transform: uppercase; 
            letter-spacing: 0.1em;
            margin-top: 2px;
            display: block;
        }

        .card { background: var(--card); border: 1px solid var(--border); border-radius: var(--radius); box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.02); overflow: hidden; }

        .profile-layout { display: grid; grid-template-columns: 280px 1fr; gap: 24px; }
        @media (max-width: 950px) { .profile-layout { grid-template-columns: 1fr; } }

        .avatar-sq {
            width: 80px; height: 80px; border-radius: 20px; margin-bottom: 12px;
            background: linear-gradient(135deg, #2563eb 0%, #3b82f6 100%);
            color: #fff; display: flex; align-items: center; justify-content: center;
            font-weight: 800; font-size: 32px; overflow: hidden;
            box-shadow: 0 10px 15px -5px rgba(37, 99, 235, 0.25);
            position: relative;
        }
        .avatar-sq img { width: 100%; height: 100%; object-fit: cover; }

        .avatar-overlay {
            position: absolute; inset: 0; background: rgba(15, 23, 42, 0.6);
            display: flex; align-items: center; justify-content: center;
            opacity: 0; transition: 0.2s; cursor: pointer;
        }
        .avatar-sq:hover .avatar-overlay { opacity: 1; }

        .label-xs { font-size: 10px; font-weight: 900; color: var(--muted); text-transform: uppercase; letter-spacing: 0.1em; margin-bottom: 4px; display: block; }
        .val-text { font-size: 14px; font-weight: 600; color: var(--text); }
        
        input, select {
            width: 100%; padding: 0 16px; height: 45px; border: 1.5px solid #e2e8f0;
            border-radius: 12px; font-size: 13px; background: #fff; transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
            color: var(--text);
        }
        input:focus, select:focus { outline: none; border-color: var(--blue); box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.08); }
        .read-only-box { background: #f8fafc; color: #94a3b8; cursor: not-allowed; border-color: #e2e8f0; }

        .btn { padding: 0 20px; height: 42px; border-radius: 10px; font-weight: 800; font-size: 12px; transition: 0.2s; display: inline-flex; align-items: center; gap: 8px; cursor: pointer; text-transform: uppercase; letter-spacing: 0.02em; }
        .btn-blue { background: var(--blue); color: #fff; }
        .btn-blue:hover { background: var(--blue-hover); transform: translateY(-2px); }
        .btn-ghost { background: #fff; border: 1px solid var(--border); color: var(--text); }
        .btn-ghost:hover { background: #f8fafc; border-color: var(--text); }

        .icon-sm { width: 14px; height: 14px; }
    </style>
</head>
<body>

<jsp:include page="sidebar.jsp" />

<main class="ml-20 lg:ml-64 min-h-screen transition-all duration-300">
    <jsp:include page="topbar.jsp" />

    <div class="pageWrap">
        <!-- Header -->
        <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-8">
            <div>
                <h2 class="title">MY ACCOUNT</h2>
                <span class="sub-label">Employee profile settings.</span>
            </div>
            <div class="flex gap-2">
                <% if (!editMode) { %>

                    <a href="Profile?edit=1" class="btn btn-blue shadow-lg shadow-blue-500/10">
                        <%= EditIcon("icon-sm") %> Edit Profile
                    </a>
                <% } %>
            </div>
        </div>

        <% if (editMode) { %>
        <form action="Profile" method="post" enctype="multipart/form-data">
        <% } %>

        <div class="profile-layout">
            <!-- Sidebar: Visual Snapshot -->
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
                    
                    <!-- Role & Status (Name removed as requested) -->
                    <div class="flex flex-col items-center gap-1.5 mt-1">
                        <span class="text-[10px] font-black text-blue-600 uppercase tracking-widest"><%= userObj.getRole() %></span>
                        <span class="px-2 py-0.5 rounded text-[9px] font-black uppercase <%= "ACTIVE".equalsIgnoreCase(userObj.getStatus()) ? "bg-emerald-50 text-emerald-600" : "bg-red-50 text-red-600" %> border border-current">
                            <%= userObj.getStatus() != null ? userObj.getStatus() : "ACTIVE" %>
                        </span>
                    </div>
                    
                    <div class="w-full mt-6 pt-6 border-t border-slate-100 space-y-5 text-left">
                        <div>
                            <span class="label-xs">Employment ID</span>
                            <span class="val-text text-blue-600 font-bold"><%= displayEmpId %></span>
                        </div>
                        <div>
                            <span class="label-xs">IC / NRIC Number</span>
                            <span class="val-text"><%= displayIc %></span>
                        </div>
                        <div>
                            <span class="label-xs">Date of Joining</span>
                            <span class="val-text"><%= displayHireDate %></span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Main: Detailed Information -->
            <div class="card">
                <div class="px-8 py-4 border-b border-slate-50 bg-slate-50/30">
                    <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Personal Identification</span>
                </div>

                <% if (!editMode) { %>
                    <!-- VIEW MODE: Clean text layout -->
                    <div class="p-8">
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-y-8 gap-x-12">
                            <div class="md:col-span-2">
                                <span class="label-xs">Full Legal Name</span>
                                <p class="text-2xl font-black text-slate-900 tracking-tight"><%= userObj.getFullName() %></p>
                            </div>
                            
                            <div>
                                <span class="label-xs">Primary Email Address</span>
                                <p class="val-text text-slate-500 font-medium"><%= userObj.getEmail() %></p>
                            </div>

                            <div>
                                <span class="label-xs">Mobile Contact</span>
                                <p class="val-text"><%= (userObj.getPhone() != null && !userObj.getPhone().isEmpty()) ? userObj.getPhone() : "Not provided" %></p>
                            </div>

                            <div>
                                <span class="label-xs">Gender Identification</span>
                                <p class="val-text"><%= displayGender %></p>
                            </div>

                            <div class="md:col-span-2">
                                <span class="label-xs">Current Residential Address</span>
                                <p class="text-slate-600 font-medium leading-relaxed max-w-xl"><%= combinedAddress %></p>
                            </div>
                        </div>
                    </div>
                <% } else { %>
                    <!-- EDIT LAYOUT: Balanced and compact -->
                    <div class="p-8 space-y-6">
                        
                        <div class="field">
                            <span class="label-xs">Full Legal Name (Verified)</span>
                            <input value="<%= userObj.getFullName() %>" class="read-only-box" disabled>
                        </div>

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div class="field">
                                <span class="label-xs">Login Email (Locked)</span>
                                <input value="<%= userObj.getEmail() %>" class="read-only-box" disabled>
                            </div>
                            <div class="field">
                                <span class="label-xs">Personal Contact</span>
                                <input name="phone" type="text" value="<%= userObj.getPhone() != null ? userObj.getPhone() : "" %>" placeholder="0123456789">
                            </div>
                        </div>

                        <div class="pt-4 border-t border-slate-100 space-y-4">
                            <span class="text-[10px] font-black text-blue-600 uppercase tracking-widest">Residential Records</span>
                            
                            <div class="field">
                                <span class="label-xs">Street Name / House Number</span>
                                <input name="street" type="text" value="<%= userObj.getStreet() != null ? userObj.getStreet() : "" %>" placeholder="Street name">
                            </div>
                            
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                                <div class="field">
                                    <span class="label-xs">City</span>
                                    <input name="city" type="text" value="<%= userObj.getCity() != null ? userObj.getCity() : "" %>" placeholder="City">
                                </div>
                                <div class="field">
                                    <span class="label-xs">Postal Code</span>
                                    <input name="postalCode" type="text" value="<%= userObj.getPostalCode() != null ? userObj.getPostalCode() : "" %>" placeholder="Postcode">
                                </div>
                            </div>

                            <div class="field">
                                <span class="label-xs">State / Region</span>
                                <select name="state">
                                    <option value="" disabled <%= userObj.getState() == null ? "selected" : "" %>>Select State</option>
                                    <optgroup label="Peninsular Malaysia">
                                        <option value="Johor" <%= "Johor".equals(userObj.getState()) ? "selected" : "" %>>Johor</option>
                                        <option value="Kedah" <%= "Kedah".equals(userObj.getState()) ? "selected" : "" %>>Kedah</option>
                                        <option value="Kelantan" <%= "Kelantan".equals(userObj.getState()) ? "selected" : "" %>>Kelantan</option>
                                        <option value="Melaka" <%= "Melaka".equals(userObj.getState()) ? "selected" : "" %>>Melaka</option>
                                        <option value="Negeri Sembilan" <%= "Negeri Sembilan".equals(userObj.getState()) ? "selected" : "" %>>Negeri Sembilan</option>
                                        <option value="Pahang" <%= "Pahang".equals(userObj.getState()) ? "selected" : "" %>>Pahang</option>
                                        <option value="Perak" <%= "Perak".equals(userObj.getState()) ? "selected" : "" %>>Perak</option>
                                        <option value="Perlis" <%= "Perlis".equals(userObj.getState()) ? "selected" : "" %>>Perlis</option>
                                        <option value="Penang" <%= "Penang".equals(userObj.getState()) ? "selected" : "" %>>Penang</option>
                                        <option value="Selangor" <%= "Selangor".equals(userObj.getState()) ? "selected" : "" %>>Selangor</option>
                                        <option value="Terengganu" <%= "Terengganu".equals(userObj.getState()) ? "selected" : "" %>>Terengganu</option>
                                    </optgroup>
                                    <optgroup label="Federal & East Malaysia">
                                        <option value="Kuala Lumpur" <%= "Kuala Lumpur".equals(userObj.getState()) ? "selected" : "" %>>Kuala Lumpur</option>
                                        <option value="Putrajaya" <%= "Putrajaya".equals(userObj.getState()) ? "selected" : "" %>>Putrajaya</option>
                                        <option value="Labuan" <%= "Labuan".equals(userObj.getState()) ? "selected" : "" %>>Labuan</option>
                                        <option value="Sabah" <%= "Sabah".equals(userObj.getState()) ? "selected" : "" %>>Sabah</option>
                                        <option value="Sarawak" <%= "Sarawak".equals(userObj.getState()) ? "selected" : "" %>>Sarawak</option>
                                    </optgroup>
                                </select>
                            </div>
                        </div>

                        <div class="flex justify-end gap-3 pt-6 border-t border-slate-100">
                            <a href="Profile" class="btn btn-ghost">Discard</a>
                            <button type="submit" class="btn btn-blue shadow-lg shadow-blue-500/20">
                                <%= SaveIcon("w-4 h-4") %> Save Changes
                            </button>
                        </div>
                    </div>
                <% } %>
            </div>
        </div>

        <% if (editMode) { %>
        </form>
        <% } %>
         </div>
</main>

<script>
    function previewImage(input) {
        if (input.files && input.files[0]) {
            const reader = new FileReader();
            reader.onload = function(e) {
                let img = document.getElementById('avatarImg');
                const container = document.getElementById('avatarContainer');
                const init = document.getElementById('avatarInit');
                
                if (!img) {
                    if (init) init.remove();
                    img = document.createElement('img');
                    img.id = 'avatarImg';
                    img.className = 'w-full h-full object-cover';
                    container.insertBefore(img, container.firstChild);
                }
                img.src = e.target.result;
            }
            reader.readAsDataURL(input.files[0]);
        }
    }
</script>

</body>
</html>