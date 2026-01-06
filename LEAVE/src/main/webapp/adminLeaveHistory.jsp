<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="bean.LeaveRecord" %>
<%@ include file="icon.jsp" %>

<%
// =========================
// SECURITY CHECK - ADMIN ONLY
// =========================
HttpSession sessionObj = request.getSession(false);
if (sessionObj == null || !"ADMIN".equalsIgnoreCase(String.valueOf(sessionObj.getAttribute("role")))) {
response.sendRedirect("login.jsp?error=Admin+Access+Required");
return;
}

List<LeaveRecord> leaves = (List<LeaveRecord>) request.getAttribute("leaves");
List<String> years = (List<String>) request.getAttribute("years");
String selStatus = (String) request.getAttribute("selStatus");
String selYear = (String) request.getAttribute("selYear");

if (leaves == null) leaves = new ArrayList<>();
if (years == null) years = new ArrayList<>();

SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");

// Calculate Stats for the Dashboard Look
int pendingCount = 0;
int cancelReqCount = 0;
for(LeaveRecord lr : leaves) {
    if("PENDING".equalsIgnoreCase(lr.getStatusCode())) pendingCount++;
    if("CANCELLATION_REQUESTED".equalsIgnoreCase(lr.getStatusCode())) cancelReqCount++;
}


%>

<!DOCTYPE html>

<html lang="en">
<head>
<meta charset="UTF-8">
<title>Admin | Global Leave Audit</title>
<script src="https://cdn.tailwindcss.com"></script>
<link href="https://www.google.com/search?q=https://fonts.googleapis.com/css2%3Ffamily%3DInter:wght%40400%3B500%3B600%3B700%3B800%3B900%26display%3Dswap" rel="stylesheet">
<style>
* { font-family: 'Inter', sans-serif; }

    /* Stats Badges from Reference */
    .stat { background:#ffffff; border:1px solid #e2e8f0; border-radius:16px; padding:24px; display:flex; align-items:center; justify-content:space-between; border-left: 6px solid #2563eb; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); }
    .stat.orange { border-left-color: #f97316; }

    /* Modal Overlay */
    .overlay { 
        position: fixed; inset: 0; background: rgba(15, 23, 42, 0.6); 
        display: none; align-items: center; justify-content: center; 
        z-index: 9999; backdrop-filter: blur(4px); 
    }
    .overlay.show { display: flex !important; }
    
    /* Status Badges - All 5 Statuses with Colors from Reference */
    .badge { padding: 4px 12px; border-radius: 999px; font-size: 10px; font-weight: 700; text-transform: uppercase; border: 1px solid transparent; display: inline-flex; align-items: center; gap: 4px; }
    
    .status-APPROVED { background: #ecfdf5; color: #047857; border-color: #a7f3d0; }
    .status-PENDING { background: #fff7ed; color: #9a3412; border-color: #fed7aa; }
    .status-REJECTED { background: #fef2f2; color: #b91c1c; border-color: #fecaca; }
    .status-CANCELLED { background: #f1f5f9; color: #475569; border-color: #e2e8f0; }
    .status-CANCELLATION_REQUESTED { background: #fff7ed; color: #c2410c; border-color: #fdba74; }

    /* Modal Details Layout */
    .modal-body { max-height: 80vh; overflow-y: auto; padding: 40px; }
    .info-label { font-size:10px; font-weight:800; color:#94a3b8; text-transform:uppercase; display:block; margin-bottom:4px; letter-spacing:0.05em; }
    .info-value { font-size:14px; font-weight:700; color:#1e293b; display:block; margin-bottom:18px; }
    .dynamic-meta-container { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 16px; padding: 20px; margin-top: 10px; margin-bottom: 24px; }
</style>


</head>
<body class="bg-slate-50">

<jsp:include page="sidebar.jsp" />

<main class="ml-20 lg:ml-64 min-h-screen transition-all duration-300">
<jsp:include page="topbar.jsp" />

<div class="max-w-[1400px] mx-auto p-8">
    <!-- Header -->
    <div class="flex justify-between items-center mb-10">
        <div class="flex items-center gap-4">
            <div class="p-3 bg-blue-600 text-white rounded-2xl shadow-lg shadow-blue-100">
                <%= ClipboardListIcon("w-6 h-6") %>
            </div>
            <div>
                <h2 class="text-3xl font-black text-slate-800 tracking-tight uppercase">Audit Dashboard</h2>
                <p class="text-slate-400 font-bold text-sm mt-1 uppercase tracking-widest">Global Workforce Review Console</p>
            </div>
        </div>
        <span class="bg-slate-900 text-white px-5 py-2 rounded-2xl text-[11px] font-black uppercase tracking-widest shadow-lg">
            Admin Access
        </span>
    </div>

    <!-- Dashboard Stats -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-8 mb-10">
        <div class="stat">
            <div>
                <span class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em]">Queued Applications</span>
                <div class="text-4xl font-black text-slate-800 mt-2"><%= pendingCount %></div>
            </div>
            <div class="w-16 h-16 bg-blue-50 text-blue-500 rounded-2xl flex items-center justify-center shadow-inner"><i class="fas fa-file-signature fa-2x"></i></div>
        </div>
        <div class="stat orange">
            <div>
                <span class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em]">Cancellation Requests</span>
                <div class="text-4xl font-black text-slate-800 mt-2"><%= cancelReqCount %></div>
            </div>
            <div class="w-16 h-16 bg-orange-50 text-orange-500 rounded-2xl flex items-center justify-center shadow-inner"><i class="fas fa-undo-alt fa-2x"></i></div>
        </div>
    </div>

    <!-- Filter Bar -->
    <form action="AdminLeaveHistory" method="GET" class="bg-white p-5 rounded-2xl border border-slate-200 flex flex-col md:flex-row gap-6 items-end mb-8 shadow-sm">
        <div class="flex flex-col">
            <span class="text-[10px] font-black text-slate-400 uppercase mb-1 ml-1">Academic Year</span>
            <select name="year" class="bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-sm font-bold outline-none min-w-[150px]">
                <option value="">All Years</option>
                <% for(String y : years) { %>
                    <option value="<%=y%>" <%= y.equals(selYear)?"selected":"" %>><%=y%></option>
                <% } %>
            </select>
        </div>
        <div class="flex flex-col">
            <span class="text-[10px] font-black text-slate-400 uppercase mb-1 ml-1">Request Status</span>
            <select name="status" class="bg-slate-50 border border-slate-200 rounded-xl px-4 py-2.5 text-sm font-bold outline-none min-w-[220px]">
                <option value="ALL">All Status</option>
                <option value="PENDING" <%= "PENDING".equals(selStatus)?"selected":"" %>>Pending</option>
                <option value="APPROVED" <%= "APPROVED".equals(selStatus)?"selected":"" %>>Approved</option>
                <option value="REJECTED" <%= "REJECTED".equals(selStatus)?"selected":"" %>>Rejected</option>
                <option value="CANCELLED" <%= "CANCELLED".equals(selStatus)?"selected":"" %>>Cancelled</option>
                <option value="CANCELLATION_REQUESTED" <%= "CANCELLATION_REQUESTED".equals(selStatus)?"selected":"" %>>Cancellation Requested</option>
            </select>
        </div>
        <button type="submit" class="bg-slate-900 text-white px-8 py-2.5 rounded-xl font-black text-xs uppercase tracking-widest hover:bg-blue-600 transition-all ml-auto">
            Apply Filters
        </button>
    </form>

    <!-- Audit Table (6 Columns) -->
    <div class="bg-white rounded-3xl shadow-sm border border-slate-200 overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-sm text-left">
                <thead class="text-[10px] text-slate-400 uppercase bg-slate-50/50 border-b font-black tracking-widest">
                    <tr>
                        <th class="px-6 py-5">Employee Details</th>
                        <th class="px-6 py-5">Leave Type</th>
                        <th class="px-6 py-5">Dates Range</th>
                        <th class="px-6 py-5">Duration</th>
                        <th class="px-6 py-5">Current Status</th>
                        <th class="px-6 py-5 text-right">Action</th>
                    </tr>
                </thead>
                <tbody>
                <% if (leaves.isEmpty()) { %>
                    <tr><td colspan="6" class="p-20 text-center text-slate-300 font-bold tracking-widest uppercase text-xs italic">No records found matching your criteria.</td></tr>
                <% } else {
                    for (LeaveRecord lr : leaves) {
                        Calendar cal = Calendar.getInstance(); 
                        cal.setTime(lr.getHireDate());
                        String formattedId = String.format("EMP-%d-%03d", cal.get(Calendar.YEAR), lr.getEmpId());
                        String pPic = (lr.getProfilePic() != null) ? lr.getProfilePic() : "https://ui-avatars.com/api/?name=" + lr.getFullName();
                        String statusKey = lr.getStatusCode().toUpperCase();
                %>
                    <tr class="border-b border-slate-100 hover:bg-slate-50/80 transition-colors">
                        <td class="px-6 py-4">
                            <div class="flex items-center gap-4">
                                <img src="<%= pPic %>" class="w-10 h-10 rounded-full border-2 border-white shadow-sm object-cover" />
                                <div>
                                    <div class="font-black text-slate-900 leading-tight"><%= lr.getFullName() %></div>
                                    <div class="text-[10px] text-slate-400 font-bold uppercase tracking-tighter"><%= formattedId %></div>
                                </div>
                            </div>
                        </td>
                        <td class="px-6 py-4">
                            <span class="bg-slate-100 text-slate-500 px-3 py-1 rounded-lg text-[9px] font-black uppercase border border-slate-200"><%= lr.getTypeCode() %></span>
                        </td>
                        <td class="px-6 py-4 text-xs font-bold text-slate-600">
                            <%= sdf.format(lr.getStartDate()) %> — <%= sdf.format(lr.getEndDate()) %>
                        </td>
                        <td class="px-6 py-4">
                            <div class="font-black text-blue-600 text-sm"><%= lr.getTotalDays() %></div>
                            <div class="text-[9px] text-slate-400 font-bold uppercase"><%= lr.getDurationLabel() %></div>
                        </td>
                        <td class="px-6 py-4">
                            <span class="badge status-<%= statusKey %>">
                                <%= lr.getStatusCode().replace("_", " ") %>
                            </span>
                        </td>
                        <td class="px-6 py-4 text-right">
                            <!-- Data-* attributes to pass data to JS without Gson -->
                            <button onclick="viewDetails(this)" 
                                    class="bg-slate-900 text-white px-6 py-2.5 rounded-xl text-[10px] font-black uppercase hover:bg-blue-600 transition-all shadow-md"
                                    data-id="<%= lr.getId() %>"
                                    data-name="<%= lr.getFullName() %>"
                                    data-pic="<%= pPic %>"
                                    data-empid="<%= formattedId %>"
                                    data-type="<%= lr.getTypeCode() %>"
                                    data-start="<%= sdf.format(lr.getStartDate()) %>"
                                    data-end="<%= sdf.format(lr.getEndDate()) %>"
                                    data-days="<%= lr.getTotalDays() %>"
                                    data-duration="<%= lr.getDurationLabel() %>"
                                    data-applied="<%= sdf.format(lr.getAppliedOn()) %>"
                                    data-reason="<%= lr.getReason() != null ? lr.getReason().replace("\"", "'") : "No specific reason provided." %>"
                                    data-hasfile="<%= lr.isHasFile() %>"
                                    data-filename="<%= lr.getFileName() %>"
                                    <%-- Special Attributes Injection for Inheritance --%>
                                    <% for(Map.Entry<String, String> entry : lr.getTypeSpecificData().entrySet()) { %>
                                        data-meta-<%= entry.getKey().toLowerCase().replace(" ", "") %>="<%= entry.getValue() %>"
                                    <% } %>
                            >Inspect</button>
                        </td>
                    </tr>
                <% } } %>
                </tbody>
            </table>
        </div>
    </div>
</div>


</main>

<!-- Detail Inspection Modal -->

<div class="overlay" id="inspectModal">
<div class="bg-white rounded-[2.5rem] shadow-2xl w-full max-w-3xl overflow-hidden animate-in zoom-in-95 duration-200 flex flex-col relative">
<!-- Modal Header -->
<div class="bg-slate-50 p-10 border-b flex items-center gap-6">
<img id="mPic" src="" class="w-20 h-20 rounded-full border-4 border-white shadow-md object-cover" />
<div>
<h3 id="mName" class="text-3xl font-black text-slate-800 tracking-tight"></h3>
<p id="mId" class="text-xs font-bold text-slate-400 uppercase tracking-[0.2em]"></p>
</div>
</div>

    <!-- Modal Body -->
    <div class="modal-body">
        <h3 class="text-2xl font-black text-slate-800 tracking-tight uppercase mb-8 border-b border-slate-100 pb-4">Application Details</h3>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-x-12">
            <div>
                <span class="info-label">Leave Type</span>
                <span class="info-value text-blue-600" id="mType"></span>
            </div>
            <div>
                <span class="info-label">Submission Date</span>
                <span class="info-value" id="mApplied"></span>
            </div>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-x-12">
            <div>
                <span class="info-label">Scheduled Period</span>
                <span class="info-value" id="mDates"></span>
            </div>
            <div>
                <span class="info-label">Calculated Days</span>
                <span class="info-value font-black text-blue-600" id="mDays"></span>
            </div>
        </div>

        <div>
            <span class="info-label">Employee Reason</span>
            <p class="text-sm text-slate-500 mb-8 bg-slate-50 p-6 rounded-2xl border border-slate-100 font-medium italic leading-relaxed" id="mReason"></p>
        </div>

        <!-- Inheritance Area (Dynamic Attributes) -->
        <div id="inheritanceArea" class="hidden">
            <div class="flex items-center gap-3 mb-4">
                <div class="w-1 h-4 bg-blue-600 rounded-full"></div>
                <h4 class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Additional Attributes</h4>
            </div>
            <div class="dynamic-meta-container space-y-4" id="mSpecialData"></div>
        </div>

        <!-- Attachment Area -->
        <div id="attachArea" class="hidden mb-6">
            <span class="info-label">Supporting Evidence</span>
            <a id="mViewAttach" href="#" target="_blank" class="inline-flex items-center gap-3 bg-white border-2 border-slate-100 px-6 py-4 rounded-2xl text-[11px] font-black text-slate-600 hover:border-blue-200 hover:text-blue-600 transition-all shadow-sm">
                <%= EyeIcon("w-6 h-6 text-red-500") %> VIEW ATTACHED DOCUMENT <i class="fas fa-external-link-alt opacity-20 text-[9px]"></i>
            </a>
        </div>
    </div>
    
    <!-- Modal Footer - Large Close button -->
    <div class="p-8 bg-slate-50 border-t flex justify-end">
        <button onclick="closeOverlay('inspectModal')" class="bg-slate-900 text-white px-12 py-4 rounded-2xl font-black shadow-xl hover:scale-105 transition-all text-xs uppercase tracking-[0.2em]">Close Review</button>
    </div>
</div>


</div>

<script>
const CTX = "<%=request.getContextPath()%>";

function closeOverlay(id) { 
    document.getElementById(id).classList.remove(&#39;show&#39;); 
}

function viewDetails(btn) {
    const d = btn.dataset;
    
    // Basic Info
    document.getElementById(&#39;mName&#39;).innerText = d.name;
    document.getElementById(&#39;mPic&#39;).src = d.pic;
    document.getElementById(&#39;mId&#39;).innerText = d.empid;
    document.getElementById(&#39;mType&#39;).innerText = d.type;
    document.getElementById(&#39;mDays&#39;).innerText = d.days + &quot; Days (&quot; + d.duration + &quot;)&quot;;
    document.getElementById(&#39;mDates&#39;).innerText = d.start + &quot; — &quot; + d.end;
    document.getElementById(&#39;mApplied&#39;).innerText = d.applied;
    document.getElementById(&#39;mReason&#39;).innerText = &#39;&quot;&#39; + d.reason + &#39;&quot;&#39;;
    
    // Dynamic Meta Data (Inheritance logic)
    const inheritArea = document.getElementById(&#39;inheritanceArea&#39;);
    const specialGrid = document.getElementById(&#39;mSpecialData&#39;);
    specialGrid.innerHTML = &quot;&quot;;
    let metaCount = 0;

    // Loop through dataset to find meta keys
    Object.keys(d).forEach(key =&gt; {
        if(key.startsWith(&#39;meta&#39;)) {
            // Convert metaClinicname to Clinic Name
            const rawLabel = key.replace(&#39;meta&#39;, &#39;&#39;);
            const label = rawLabel.replace(/([A-Z])/g, &#39; $1&#39;).replace(/^./, str =&gt; str.toUpperCase()).trim();
            
            specialGrid.innerHTML += `
                &lt;div class=&quot;flex justify-between items-center border-b border-slate-100 pb-3 last:border-0 last:pb-0&quot;&gt;
                    &lt;span class=&quot;info-label mb-0&quot;&gt;${label}&lt;/span&gt;
                    &lt;span class=&quot;info-value mb-0 text-slate-600&quot;&gt;${d[key]}&lt;/span&gt;
                &lt;/div&gt;
            `;
            metaCount++;
        }
    });
    
    inheritArea.classList.toggle(&#39;hidden&#39;, metaCount === 0);
    
    // Attachment handling
    const attachArea = document.getElementById(&#39;attachArea&#39;);
    if(d.hasfile === &quot;true&quot;) {
        attachArea.classList.remove(&#39;hidden&#39;);
        document.getElementById(&#39;mViewAttach&#39;).href = CTX + &quot;/ViewAttachment?id=&quot; + d.id;
    } else {
        attachArea.classList.add(&#39;hidden&#39;);
    }
    
    document.getElementById(&#39;inspectModal&#39;).classList.add(&#39;show&#39;);
}


</script>

</body>
</html>