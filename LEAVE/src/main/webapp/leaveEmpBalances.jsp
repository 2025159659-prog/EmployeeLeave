<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, java.text.SimpleDateFormat" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ include file="icon.jsp" %>

<%
    // =========================
    // ADMIN SECURITY GUARD
    // =========================
    if (session.getAttribute("empid") == null || session.getAttribute("role") == null ||
        !"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
        response.sendRedirect("login.jsp?error=Please+login+as+admin.");
        return;
    }

    String ctx = request.getContextPath();
    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
    Calendar cal = Calendar.getInstance();

    List<Map<String,Object>> employees = (List<Map<String,Object>>) request.getAttribute("employees");
    List<Map<String,Object>> leaveTypes = (List<Map<String,Object>>) request.getAttribute("leaveTypes");
    Map<Integer, Map<Integer, Map<String,Object>>> balanceIndex =
        (Map<Integer, Map<Integer, Map<String,Object>>>) request.getAttribute("balanceIndex");
    String error = (String) request.getAttribute("error");
%>

<%!
  double toNum(Object o){
    if(o == null) return 0.0;
    if(o instanceof Number) return ((Number)o).doubleValue();
    try { return Double.parseDouble(String.valueOf(o)); } catch(Exception e){ return 0.0; }
  }
  String esc(String s){
    if(s == null) return "";
    return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
            .replace("\"","&quot;").replace("'","&#39;");
  }
  String initials(String name){
    if(name == null || name.isBlank()) return "?";
    String[] parts = name.trim().split("\\s+");
    return parts[0].substring(0,1).toUpperCase() + (parts.length > 1 ? parts[parts.length-1].substring(0,1).toUpperCase() : "");
  }
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Leave Balances | Admin Access</title>

  <script src="https://cdn.tailwindcss.com"></script>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">

  <style>
    :root {
      --bg: #f8fafc;
      --card: #fff;
      --border: #cbd5e1;
      --text: #1e293b;
      --muted: #64748b;
      --blue-primary: #2563eb;
      --blue-light: #eff6ff;
      --blue-hover: #1d4ed8;
      --red: #ef4444;
      --green: #10b981;
      --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
      --radius: 16px;
    }

    * { 
      box-sizing: border-box; 
      font-family: 'Inter', sans-serif !important; 
    }

    body { background: var(--bg); color: var(--text); margin: 0; }
    
    .pageWrap { padding: 32px 40px; max-width: 1240px; margin: 0 auto; }

    /* ✅ Redesigned Title & Sub-label to match Employee Directory */
    .title { font-size: 26px; font-weight: 800; margin: 0; text-transform: uppercase; color: var(--text); }
    .sub-label { color: var(--blue-primary); font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.1em; margin-top: 4px; display: block; }

    /* ✅ Card Pattern */
    .card { background: var(--card); border: 1px solid var(--border); border-radius: var(--radius); box-shadow: var(--shadow); overflow: hidden; margin-top: 24px; }
    .cardHead { padding: 20px 24px; border-bottom: 1px solid #f1f5f9; display: flex; justify-content: space-between; align-items: center; }
    .cardHead span { font-weight: 800; font-size: 15px; color: var(--text); text-transform: uppercase; }

    table { width: 100%; border-collapse: collapse; }
    th, td { border-bottom: 1px solid #f1f5f9; padding: 18px 24px; text-align: left; vertical-align: top; }
    th { background: #f8fafc; font-size: 11px; text-transform: uppercase; color: var(--muted); font-weight: 800; letter-spacing: 0.05em; }
    
    /* Employee Profile Box */
    .empBox { display: flex; align-items: center; gap: 14px; min-width: 260px; }
    .avatar { width: 42px; height: 42px; border-radius: 10px; background: #f1f5f9; border: 1px solid var(--border); overflow: hidden; display: flex; align-items: center; justify-content: center; font-weight: 800; color: var(--blue-primary); font-size: 13px; }
    .avatar img { width: 100%; height: 100%; object-fit: cover; }

    /* Leave Balance Card (Inner) */
    .balCard { background: #fcfcfd; border: 1px solid #f1f5f9; border-radius: 14px; padding: 12px; min-width: 170px; transition: 0.2s; }
    .balCard:hover { border-color: var(--blue-primary); background: #fff; }
    
    .avail-lbl { color: var(--muted); font-size: 9px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 4px; display: block; }
    .avail-num { font-size: 20px; font-weight: 900; color: #0f172a; line-height: 1; }
    .avail-total { font-size: 14px; font-weight: 700; color: #94a3b8; }
    .avail-desc { font-size: 8px; font-weight: 700; color: #94a3b8; text-transform: uppercase; margin-top: 2px; }

    /* ✅ Updated miniRow for vertical key-value display */
    .miniRow { display: flex; justify-content: space-between; align-items: center; color: var(--muted); font-size: 11px; margin-top: 6px; padding-top: 4px; border-top: 1px solid #f8fafc; font-weight: 600; }
    .miniRow:first-child { border-top: none; margin-top: 0; padding-top: 0; }
    .miniRow b { color: var(--text); font-weight: 800; }

    .warning { color: var(--red) !important; }
  </style>
</head>

<body class="flex">
    <jsp:include page="sidebar.jsp" />

    <main class="flex-1 ml-20 lg:ml-64 min-h-screen transition-all duration-300">
        <jsp:include page="topbar.jsp" />

        <div class="pageWrap">
            <!-- ✅ Header Structure matched to Employee Directory -->
            <div class="mb-8">
                <h2 class="title">Leave Balances</h2>
                <span class="sub-label">List of employee record entitlements and usage status</span>
            </div>

            <% if (error != null) { %>
              <div class="bg-red-50 border border-red-100 text-red-600 p-4 rounded-xl mb-4 font-bold text-sm flex items-center gap-3">
                 <i class="fas fa-exclamation-circle text-lg"></i> DB Error: <%= esc(error) %>
              </div>
            <% } %>

            <!-- Main Card Container -->
            <div class="card">
                <div class="cardHead">
                    <span>Staff Entitlements Overview</span>
                    <div class="text-[10px] font-black text-slate-400 uppercase tracking-widest">
                        Total Staff: <%= (employees != null ? employees.size() : 0) %>
                    </div>
                </div>

                <div class="overflow-x-auto">
                    <table>
                        <thead>
                            <tr>
                                <th>Staff Member</th>
                                <% if (leaveTypes != null) {
                                     for (Map<String,Object> t : leaveTypes) { %>
                                      <th><%= esc(String.valueOf(t.get("code"))) %></th>
                                <%   }
                                   } %>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (employees == null || employees.isEmpty()) { %>
                                <tr><td colspan="10" class="py-24 text-center text-slate-300 font-black uppercase text-xs">No records found in database</td></tr>
                            <% } else {
                                 for (Map<String,Object> e : employees) {
                                    int empId = (Integer)e.get("empid");
                                    String fullName = String.valueOf(e.get("fullname"));
                                    String roleName = String.valueOf(e.get("role"));
                                    java.util.Date hireDate = (java.util.Date)e.get("hiredate");
                                    String profilePic = (String)e.get("profilePic");

                                    // ✅ ID LOGIC: EMP-YEARJOIN-0(EMPID)
                                    String joinYear = "0000";
                                    if (hireDate != null) {
                                        cal.setTime(hireDate);
                                        joinYear = String.valueOf(cal.get(Calendar.YEAR));
                                    }
                                    String customId = "EMP-" + joinYear + "-0" + empId;

                                    Map<Integer, Map<String,Object>> empBalances = (balanceIndex != null ? balanceIndex.get(empId) : null);
                            %>
                                <tr>
                                    <td>
                                        <div class="empBox">
                                            <div class="avatar shadow-sm">
                                                <% if (profilePic != null && !profilePic.isBlank()) { %>
                                                    <img src="<%= ctx + "/" + profilePic %>" alt="Profile"/>
                                                <% } else { %>
                                                    <%= esc(initials(fullName)) %>
                                                <% } %>
                                            </div>
                                            <div>
                                                <div class="text-sm font-bold text-slate-800 leading-none mb-1"><%= esc(fullName) %></div>
                                                <div class="flex items-center gap-2">
                                                   <span class="text-[10px] font-black text-blue-600 uppercase tracking-tighter"><%= customId %></span>
                                                   <span class="w-1 h-1 rounded-full bg-slate-300"></span>
                                                   <span class="text-[9px] font-bold text-slate-400 uppercase tracking-widest"><%= esc(roleName) %></span>
                                                </div>
                                                <div class="text-[10px] text-slate-400 font-medium mt-1">Joined: <%= (hireDate != null ? sdf.format(hireDate) : "-") %></div>
                                            </div>
                                        </div>
                                    </td>

                                    <% if (leaveTypes != null) {
                                         for (Map<String,Object> t : leaveTypes) {
                                            int typeId = (Integer)t.get("id");
                                            Map<String,Object> bal = (empBalances != null ? empBalances.get(typeId) : null);

                                            if (bal == null) { %>
                                                <td><div class="text-[10px] font-bold text-slate-200 uppercase">N/A</div></td>
                                    <%      } else {
                                                double available = toNum(bal.get("available"));
                                                double total     = toNum(bal.get("total"));
                                                double used      = toNum(bal.get("used"));
                                                double pending   = toNum(bal.get("pending"));
                                                double entitlement = toNum(bal.get("entitlement"));
                                    %>
                                                <td>
                                                    <div class="balCard shadow-sm">
                                                        <span class="avail-lbl">Available</span>
                                                        <div class="flex items-baseline gap-1">
                                                            <span class="avail-num <%= (available <= 0 ? "warning" : "") %>"><%= (int)available %></span>
                                                            <span class="avail-total">/ <%= (int)total %></span>
                                                        </div>
                                                        <div class="avail-desc">(total days per year)</div>

                                                        <!-- ✅ Metric List in miniRow format -->
                                                        <div class="space-y-1 mt-3">
                                                            <div class="miniRow"><span>Base Ent:</span><b><%= (int)entitlement %></b></div>
                                                            <div class="miniRow"><span>Used:</span><b><%= (int)used %></b></div>
                                                            <div class="miniRow"><span>Pending:</span><b><%= (int)pending %></b></div>
                                                        </div>
                                                    </div>
                                                </td>
                                    <%      }
                                         }
                                       } %>
                                </tr>
                            <%   } 
                               } %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </main>
</body>
</html>