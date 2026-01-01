<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ include file="icon.jsp" %>

<%
    // =========================
    // SECURITY CHECK
    // =========================
    if (session.getAttribute("empid") == null) {
        response.sendRedirect("login.jsp?error=Please login.");
        return;
    }

    boolean editMode = "1".equals(request.getParameter("edit"));

    // Dynamic Initial Calculation
    String nm = (request.getAttribute("fullname") != null) ? request.getAttribute("fullname").toString() : "User";
    String init = (!nm.isBlank()) ? (""+nm.charAt(0)).toUpperCase() : "U";

    String profilePic = (request.getAttribute("profilePic") != null) ? String.valueOf(request.getAttribute("profilePic")) : null;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile | Klinik Dr Mohamad</title>
    
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
            --sb-w: 300px;
        }

        /* ✅ Consistent Typography matching Dashboard/History */
        * { box-sizing: border-box; font-family: 'Inter', Arial, sans-serif !important; }
        
        body { margin: 0; background: var(--bg); color: var(--text); overflow-x: hidden; }

        .content { min-height: 100vh; padding: 0; }
        .pageWrap { max-width: 1200px; margin: 0 auto; padding: 32px 40px; }
        
        /* ✅ Standard H2 Title */
        h2.title { font-size: 26px; font-weight: 800; margin: 10px 0 6px; color: var(--text); text-transform: uppercase; }
        .sub { color: var(--muted); margin: 0 0 32px; font-size: 15px; font-weight: 500; }

        .card { 
            background: var(--card); 
            border: 1px solid var(--border); 
            border-radius: var(--radius); 
            box-shadow: var(--shadow); 
            overflow: hidden;
        }

        .profile-grid { display: grid; grid-template-columns: 320px 1fr; gap: 24px; }
        @media (max-width: 980px) { .profile-grid { grid-template-columns: 1fr; } }

        /* Avatar Styling */
        .avatar-circle {
            width: 100px; height: 100px; border-radius: 999px; margin: 0 auto 16px;
            border: 4px solid #f1f5f9; display: flex; align-items: center; justify-content: center;
            font-weight: 800; font-size: 36px; background: var(--primary); color: #fff; overflow: hidden;
        }
        .avatar-circle img { width: 100%; height: 100%; object-fit: cover; }

        .role-badge {
            display: inline-flex; align-items: center; padding: 4px 12px; border-radius: 99px;
            background: #eff6ff; color: var(--primary); font-size: 10px; font-weight: 800;
            text-transform: uppercase; letter-spacing: 0.05em; border: 1px solid #dbeafe;
        }

        .label-sm { font-size: 11px; font-weight: 800; color: var(--muted); text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 6px; }
        .data-value { font-size: 15px; font-weight: 600; color: var(--text); }
        
        input, textarea {
            width: 100%; padding: 12px 14px; border: 1px solid #cbd5e1;
            border-radius: 12px; font-size: 14px; background: #fff; transition: all 0.2s; color: var(--text);
        }
        input:focus, textarea:focus { outline: none; border-color: var(--primary); box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.1); }
        
        .locked input { background: #f8fafc; color: #94a3b8; cursor: not-allowed; border-color: var(--border); }

        .btn { padding: 10px 24px; border-radius: 12px; font-weight: 700; font-size: 14px; transition: all 0.2s; display: inline-flex; align-items: center; gap: 8px; cursor: pointer; text-transform: uppercase; }
        .btn-primary { background: var(--primary); color: #fff; border: none; }
        .btn-primary:hover { background: var(--primary-hover); transform: translateY(-1px); }
        .btn-ghost { background: #fff; border: 1px solid var(--border); color: var(--muted); }
        .btn-ghost:hover { background: #f8fafc; color: var(--text); }

        .err-banner { background: #fef2f2; color: #b91c1c; padding: 12px 20px; border-radius: 12px; margin-bottom: 20px; font-size: 13px; font-weight: 700; }
        .success-banner { background: #ecfdf5; color: #047857; padding: 12px 20px; border-radius: 12px; margin-bottom: 20px; font-size: 13px; font-weight: 700; }
    </style>
</head>
<body>

    <jsp:include page="sidebar.jsp" />

    <!-- ✅ Responsive Main Container -->
    <main class="ml-20 lg:ml-64 min-h-screen transition-all duration-300 flex flex-col">
        
        <!-- ✅ Shared Topbar -->
        <jsp:include page="topbar.jsp" />

        <div class="content">
            <div class="pageWrap">

                <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-8">
                    <div>
                        <h2 class="title">MY PROFILE</h2>
                        <p class="sub">
                            <%= editMode ? "Update your personal details and profile photo." : "View and manage your account information." %>
                        </p>
                    </div>
                    <% if (!editMode) { %>
                        <a class="btn btn-primary shadow-md shadow-blue-100" href="ProfileServlet?edit=1">
                            <%= EditIcon("w-4 h-4") %> Edit Profile
                        </a>
                    <% } %>
                </div>

                <!-- Alert Messages -->
                <c:if test="${not empty param.msg}">
                    <div class="success-banner flex items-center gap-2">
                        <span class="text-lg">✓</span> ${param.msg}
                    </div>
                </c:if>
                <c:if test="${not empty param.error}">
                    <div class="err-banner flex items-center gap-2">
                        <span class="text-lg">⚠️</span> ${param.error}
                    </div>
                </c:if>

                <div class="profile-grid">
                    
                    <!-- Left Column: Avatar & ID -->
                    <div class="flex flex-col gap-6">
                        <div class="card p-8 text-center flex flex-col items-center">
                            <div class="avatar-circle">
                                <% if (profilePic != null && !profilePic.isBlank()) { %>
                                    <img src="<%= profilePic %>" alt="Profile">
                                <% } else { %>
                                    <%= init %>
                                <% } %>
                            </div>
                            <h3 class="text-lg font-bold text-slate-800 mb-1"><c:out value="${fullname}"/></h3>
                            <p class="text-sm text-slate-500 mb-4 font-medium"><c:out value="${email}"/></p>
                            <span class="role-badge"><c:out value="${role}"/></span>
                        </div>

                        <div class="card p-6">
                            <h4 class="label-sm border-b border-slate-100 pb-3 mb-4">Official Records</h4>
                            <div class="space-y-5">
                                <div>
                                    <p class="label-sm">Employee ID</p>
                                    <p class="data-value text-blue-600">#<c:out value="${empid}"/></p>
                                </div>
                                <div>
                                    <p class="label-sm">Date Joined</p>
                                    <p class="data-value"><c:out value="${hireDate}"/></p>
                                </div>
                                <c:if test="${not empty icNumber}">
                                    <div>
                                        <p class="label-sm">NRIC / Identification</p>
                                        <p class="data-value"><c:out value="${icNumber}"/></p>
                                    </div>
                                </c:if>
                            </div>
                        </div>
                    </div>

                    <!-- Right Column: Form/Details -->
                    <div class="card">
                        <div class="px-6 py-4 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
                            <h3 class="font-bold text-slate-700 text-sm uppercase tracking-wider">General Information</h3>
                            <span class="px-2 py-1 bg-white text-slate-400 text-[10px] font-bold rounded border border-slate-200 uppercase">
                                <%= editMode ? "Edit Mode" : "Read Only" %>
                            </span>
                        </div>

                        <% if (!editMode) { %>
                            <div class="p-8 grid grid-cols-1 md:grid-cols-2 gap-y-10 gap-x-12">
                                <div>
                                    <p class="label-sm">Full Name</p>
                                    <p class="data-value"><c:out value="${fullname}"/></p>
                                </div>
                                <div>
                                    <p class="label-sm">Email Address</p>
                                    <p class="data-value"><c:out value="${email}"/></p>
                                </div>
                                <div>
                                    <p class="label-sm">Contact Number</p>
                                    <p class="data-value"><%= (request.getAttribute("phone") == null || String.valueOf(request.getAttribute("phone")).isBlank()) ? "—" : request.getAttribute("phone") %></p>
                                </div>
                                <div>
                                    <p class="label-sm">Gender</p>
                                    <p class="data-value"><c:out value="${gender}"/></p>
                                </div>
                                <div class="md:col-span-2">
                                    <p class="label-sm">Mailing Address</p>
                                    <p class="data-value leading-relaxed"><c:out value="${address}"/></p>
                                </div>
                            </div>
                        <% } else { %>
                            <form action="ProfileServlet" method="post" enctype="multipart/form-data">
                                <div class="p-8 space-y-8">
                                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                                        <div class="locked">
                                            <p class="label-sm">Legal Name</p>
                                            <input value="<c:out value='${fullname}'/>" disabled>
                                        </div>
                                        <div class="locked">
                                            <p class="label-sm">Employment Status</p>
                                            <input value="<c:out value='${role}'/>" disabled>
                                        </div>
                                        <div>
                                            <p class="label-sm">Email Address <span class="text-red-500">*</span></p>
                                            <input name="email" type="email" value="<c:out value='${email}'/>" required>
                                        </div>
                                        <div>
                                            <p class="label-sm">Mobile Phone</p>
                                            <input name="phone" type="text" value="<c:out value='${phone}'/>" placeholder="+60...">
                                        </div>
                                        <div class="md:col-span-2">
                                            <p class="label-sm">Residential Address</p>
                                            <textarea name="address" rows="3" placeholder="Street, City, State, Postcode..."><c:out value="${address}"/></textarea>
                                        </div>
                                        <div class="md:col-span-2 p-6 bg-slate-50 rounded-2xl border-2 border-dashed border-slate-200 text-center">
                                            <p class="label-sm mb-3">Change Profile Photo</p>
                                            <input name="profilePic" type="file" accept="image/*" class="text-xs file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-xs file:font-bold file:bg-blue-600 file:text-white hover:file:bg-blue-700 cursor-pointer">
                                            <p class="text-[10px] text-slate-400 mt-2">Recommended: Square image, Max 2MB (JPG/PNG)</p>
                                        </div>
                                    </div>
                                    
                                    <div class="flex justify-end items-center gap-4 pt-6 border-t border-slate-100">
                                        <a class="text-xs font-bold text-slate-400 hover:text-slate-600 transition-colors uppercase tracking-widest" href="ProfileServlet">Discard Changes</a>
                                        <button class="btn btn-primary" type="submit">
                                            <%= SendIcon("w-4 h-4") %> Save Profile
                                        </button>
                                    </div>
                                </div>
                            </form>
                        <% } %>
                    </div>
                </div>

                <div class="mt-12 text-center opacity-30 text-[10px] font-bold uppercase tracking-widest">
                    v1.2.5 © 2024 Klinik Dr Mohamad
                </div>

            </div>
        </div>
    </main>
</body>
</html>