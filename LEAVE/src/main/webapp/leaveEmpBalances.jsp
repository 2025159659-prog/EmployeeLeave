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
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Leave Balances | Admin Intelligence</title>

  <script src="https://cdn.tailwindcss.com"></script>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">

  <style>
    :root {
      --bg: #f1f5f9;
      --card: #ffffff;
      --border: #e2e8f0;
      --text: #1e293b;
      --muted: #64748b;
      --blue-primary: #2563eb;
      --blue-light: #eff6ff;
      --radius: 20px; /* ✅ Matches Main Container and Cards */
      --shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
    }

    * { box-sizing: border-box; font-family: 'Inter', sans-serif !important; }
    
    html, body { 
      background: var(--bg); 
      color: var(--text); 
      margin: 0; 
      height: 100vh;
      width: 100vw;
      overflow: hidden; 
    }

    main { height: 100vh; display: flex; flex-direction: column; min-width: 0; }

    .pageWrap { 
      padding: 24px 40px; 
      flex: 1;
      display: flex;
      flex-direction: column;
      overflow: hidden; 
      min-height: 0;
    }

    .title { font-size: 26px; font-weight: 800; margin: 0; text-transform: uppercase; color: var(--text); }
    .sub-label { color: var(--blue-primary); font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: 0.1em; margin-top: 4px; display: block; }

    /* ✅ Main Card with 20px Corners */
    .card { 
      background: var(--card); 
      border: 1px solid var(--border); 
      border-radius: var(--radius); 
      box-shadow: var(--shadow); 
      margin-top: 24px;
      flex: 1;
      display: flex;
      flex-direction: column;
      overflow: hidden; /* Ensures corners clip content */
    }
    
    .cardHead { 
      padding: 16px 24px; 
      border-bottom: 1px solid #f1f5f9; 
      display: flex; 
      justify-content: space-between; 
      align-items: center;
      background: #fcfcfd;
      flex-shrink: 0;
    }
    .cardHead span { font-weight: 800; font-size: 15px; color: var(--text); text-transform: uppercase; }

    .scroll-container { flex: 1; overflow: auto; min-height: 0; position: relative; }
    .scroll-container::-webkit-scrollbar { width: 6px; height: 6px; }
    .scroll-container::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }

    table { width: 100%; border-collapse: separate; border-spacing: 0; }
    
    thead th {
        position: sticky; top: 0; z-index: 20;
        background: #f8fafc; border-bottom: 1px solid #f1f5f9;
        padding: 12px 16px;
        text-align: left; font-size: 10px; text-transform: uppercase;
        color: var(--muted); font-weight: 900;
    }

    th:first-child, td:first-child { position: sticky; left: 0; z-index: 15; border-right: 1px solid #f1f5f9; background: #fff; }
    thead th:first-child { z-index: 30; background: #f8fafc; }

    td { padding: 12px 16px; border-bottom: 1px solid #f1f5f9; vertical-align: top; }

    .empBox { width: 170px; display: flex; align-items: flex-start; gap: 10px; }
    .emp-name { font-size: 14px; font-weight: 800; color: #0f172a; line-height: 1.3; }
    .role-badge { font-size: 8px; font-weight: 900; background: #eff6ff; color: #2563eb; padding: 2px 6px; border-radius: 4px; border: 1px solid #dbeafe; text-transform: uppercase; margin-top: 4px; display: inline-block; }
    .emp-meta { font-size: 9px; font-weight: 700; color: #3b4a5f; text-transform: uppercase; margin-top: 2px; display: block; }

    /* ✅ UPDATED BALANCE CARD: Smaller Size & 20px Radius */
    .balCard { 
      background: #f1f5f9; 
      border: 1.5px solid #3b82f6; 
      border-radius: var(--radius); /* ✅ Perfectly matched 20px */
      padding: 10px; 
      min-width: 150px; /* Reduced width */
      transition: all 0.2s ease;
    }
    .balCard:hover { background: #ffffff; transform: scale(1.02); }
    
    /* Dark & Larger Labels */
    .avail-lbl { color: #0f172a; font-size: 10px; font-weight: 900; text-transform: uppercase; display: block; margin-bottom: 2px; }
    
    .avail-summary { font-size: 18px; font-weight: 900; color: #1e3a8a; line-height: 1; margin-bottom: 8px; display: flex; align-items: baseline; gap: 2px; }
    .avail-total-base { font-size: 12px; font-weight: 700; color: var(--muted); }

    .miniRow { 
      display: flex; justify-content: space-between; align-items: center; 
      font-size: 10px; padding-top: 4px; margin-top: 4px; 
      border-top: 1px solid #e2e8f0; 
    }
    .miniRow span { color: #475569; font-size: 10px; font-weight: 900; text-transform: uppercase; }
    .miniRow b { color: #0f172a; font-weight: 900; }
    
    .text-warning { color: #ef4444 !important; }
  </style>
</head>

<body class="flex">
    <jsp:include page="sidebar.jsp" />

    <main class="flex-1 ml-20 lg:ml-64 transition-all duration-300">
        <jsp:include page="topbar.jsp" />

        <div class="pageWrap">
            <div class="flex-shrink-0">
                <h2 class="title">Leave Balances</h2>
                <span class="sub-label">Employee record entitlements and usage status</span>
            </div>

            <div class="card">
                <div class="cardHead">
                    <span>Staff Entitlements Overview</span>
                    <div class="text-[9px] font-black text-slate-400 uppercase">
                        Total Staff: <%= (employees != null ? employees.size() : 0) %>
                    </div>
                </div>

                <div class="scroll-container">
                    <table>
                        <thead>
                            <tr>
                                <th>Staff Member</th>
                                <% if (leaveTypes != null) {
                                     for (Map<String,Object> t : leaveTypes) { %>
                                      <th class="text-center"><%= esc(String.valueOf(t.get("code"))) %></th>
                                <%   }
                                   } %>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (employees != null) {
                                 for (Map<String,Object> e : employees) {
                                    int empId = (Integer)e.get("empid");
                                    String fullName = String.valueOf(e.get("fullname"));
                                    String roleName = String.valueOf(e.get("role"));
                                    java.util.Date hireDate = (java.util.Date)e.get("hiredate");
                                    String profilePic = (String)e.get("profilePic");
                                    String joinYear = (hireDate != null) ? String.valueOf(1900 + hireDate.getYear()) : "0000";
                                    String customId = "EMP-" + joinYear + "-0" + empId;

                                    Map<Integer, Map<String, Object>> empBals = (balanceIndex != null ? balanceIndex.get(empId) : null);
                            %>
                                <tr>
                                    <td>
                                        <div class="empBox">
                                            <div class="w-8 h-8 rounded-lg bg-slate-100 overflow-hidden flex-shrink-0 border border-slate-200 flex items-center justify-center">
                                                <% if (profilePic != null && !profilePic.isEmpty() && !profilePic.equalsIgnoreCase("null")) { %>
                                                    <img src="<%= ctx + "/" + profilePic %>" class="w-full h-full object-cover">
                                                <% } else { %>
                                                    <div class="text-slate-400 font-black text-[10px] uppercase"><%= fullName.substring(0,1) %></div>
                                                <% } %>
                                            </div>
                                            <div class="min-w-0 flex-1">
                                                <div class="emp-name"><%= esc(fullName) %></div>
                                                <div class="role-badge"><%= esc(roleName) %></div>
                                                <span class="emp-meta"><%= customId %></span>
                                            </div>
                                        </div>
                                    </td>

                                    <% if (leaveTypes != null) {
                                         for (Map<String,Object> t : leaveTypes) {
                                            int typeId = (Integer)t.get("id");
                                            Map<String,Object> bal = (empBals != null ? empBals.get(typeId) : null);

                                            if (bal == null) { %>
                                                <td class="text-center"><div class="text-[9px] font-black text-slate-200">-</div></td>
                                    <%      } else {
                                                double available = toNum(bal.get("available"));
                                                double total     = toNum(bal.get("total"));
                                                double used      = toNum(bal.get("used"));
                                                double pending   = toNum(bal.get("pending"));
                                                double entitlement = toNum(bal.get("entitlement"));
                                    %>
                                                <td>
                                                    <div class="balCard shadow-sm">
                                                        <span class="avail-lbl">AVAILABLE</span>
                                                        <div class="avail-summary">
                                                            <span class="<%= (available <= 0 ? "text-warning" : "") %>"><%= (int)available %></span>
                                                            <span class="avail-total-base">/<%= (int)total %></span>
                                                        </div>

                                                        <div class="miniRow">
                                                            <span>ENTITLEMENT</span>
                                                            <b><%= (int)entitlement %></b>
                                                        </div>
                                                        <div class="miniRow">
                                                            <span>USED</span>
                                                            <b><%= (int)used %></b>
                                                        </div>
                                                        <div class="miniRow">
                                                            <span>PENDING</span>
                                                            <b class="<%= (pending > 0 ? "text-orange-500" : "") %>"><%= (int)pending %></b>
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