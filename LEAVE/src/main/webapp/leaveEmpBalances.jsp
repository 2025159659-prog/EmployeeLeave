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
%>

<%!
  // Method to safely handle number conversion
  double toNum(Object o){
    if(o == null) return 0.0;
    if(o instanceof Number) return ((Number)o).doubleValue();
    try { return Double.parseDouble(String.valueOf(o)); } catch(Exception e){ return 0.0; }
  }

  // Method to escape HTML
  String esc(String s){
    if(s == null) return "";
    return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
            .replace("\"","&quot;").replace("'","&#39;");
  }

  // Method to get initials for avatar
  String initials(String name){
    if(name == null || name.isBlank()) return "?";
    String[] parts = name.trim().split("\\s+");
    String a = parts[0].substring(0,1).toUpperCase();
    String b = (parts.length > 1 ? parts[parts.length-1].substring(0,1).toUpperCase() : "");
    return a + b;
  }
%>

<%
  String ctx = request.getContextPath();
  SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");

  // Retrieve data from Servlet
  List<Map<String,Object>> employees = (List<Map<String,Object>>) request.getAttribute("employees");
  List<Map<String,Object>> leaveTypes = (List<Map<String,Object>>) request.getAttribute("leaveTypes");
  Map<Integer, Map<Integer, Map<String,Object>>> balanceIndex =
      (Map<Integer, Map<Integer, Map<String,Object>>>) request.getAttribute("balanceIndex");
  String error = (String) request.getAttribute("error");
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Leave Balances Overview | LMS</title>
  
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
      --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
      --radius: 16px;
      --pink: #ec4899;
      --indigo: #6366f1;
    }

    /* ✅ Consistent Typography matching Employee Portal */
    * { box-sizing: border-box; font-family: 'Inter', Arial, sans-serif !important; }
    
    body { margin: 0; background: var(--bg); color: var(--text); overflow-x: hidden; }

    .content { min-height: 100vh; padding: 0; }
    .pageWrap { max-width: 1600px; margin: 0 auto; padding: 32px 40px; }

    /* ✅ Standard H2 Title */
    h2.title { font-size: 26px; font-weight: 800; margin: 10px 0 6px; color: var(--text); text-transform: uppercase; }
    .sub { color: var(--muted); margin: 0 0 32px; font-size: 15px; font-weight: 500; }

    /* Alert DB Error */
    .errBox { background:#fef2f2; border:1px solid #fee2e2; color:#b91c1c; padding:16px; border-radius:12px; margin-bottom:24px; font-size:14px; font-weight:700; }

    /* Table Design */
    .tableCard { background:#fff; border-radius: var(--radius); border: 1px solid var(--border); box-shadow: var(--shadow); overflow: auto; }
    table { width: 100%; border-collapse: separate; border-spacing: 0; }
    
    th { 
      position: sticky; top: 0; background: #f8fafc; z-index: 10; 
      border-bottom: 1px solid var(--border); text-align: left; 
      color: var(--muted); font-size: 11px; font-weight: 800; 
      text-transform: uppercase; padding: 16px 14px; letter-spacing: 0.05em;
    }
    
    td { padding: 20px 14px; vertical-align: top; border-bottom: 1px solid #f1f5f9; }

    /* Employee Details Style */
    .empBox { display: flex; gap: 14px; align-items: center; min-width: 260px; }
    .avatar { 
        width: 44px; height: 44px; border-radius: 12px; overflow: hidden; 
        background: #f1f5f9; display: flex; align-items: center; justify-content: center; 
        font-weight: 800; color: var(--primary); border: 1px solid var(--border); 
    }
    .avatar img { width: 100%; height: 100%; object-fit: cover; }

    /* Balance Card Style inside Table Cell */
    .balCard {
      border: 1px solid #f1f5f9; border-radius: 12px; padding: 12px; background: #fcfcfd; 
      min-width: 170px; transition: 0.2s;
    }
    .balCard:hover { border-color: var(--border); background: #fff; }
    
    .bigNum { font-size: 22px; font-weight: 800; line-height: 1; margin-bottom: 4px; }
    .mutedLabel { color: var(--muted); font-size: 10px; font-weight: 800; text-transform: uppercase; }
    
    /* Progress Bar */
    .bar { height: 6px; border-radius: 99px; background: #f1f5f9; margin: 10px 0 8px; overflow: hidden; }
    .barFill { height: 100%; transition: width 0.8s ease; }
    
    /* Default, Maternity, Paternity Colors */
    .bg-annual { background: var(--primary); }
    .bg-maternity { background: var(--pink); }
    .bg-paternity { background: var(--indigo); }
    .bg-parenity { background: var(--indigo); } /* Support typo */

    .miniRow { display: flex; justify-content: space-between; color: var(--muted); font-size: 11px; margin-bottom: 2px; font-weight: 600; }
    .miniRow b { color: var(--text); font-weight: 800; }
    .noData { color: #cbd5e1; font-size: 11px; font-weight: 700; text-align: center; }
  </style>
</head>

<body>
  <jsp:include page="sidebar.jsp" />

  <!-- ✅ Main Responsive Container -->
  <main class="ml-20 lg:ml-64 min-h-screen transition-all duration-300">
    
    <!-- ✅ Standard Topbar with No Gap -->
    <jsp:include page="topbar.jsp" />

    <div class="content">
      <div class="pageWrap">

        <div class="pageHeader">
          <h2 class="title">LEAVE BALANCES OVERVIEW</h2>
          <p class="sub">Breakdown of entitlements and current balances for all staff members.</p>
        </div>

        <% if (error != null && !error.isBlank()) { %>
          <div class="errBox flex items-center gap-3">
             <i class="fas fa-exclamation-circle text-lg"></i> DB Error: <%= esc(error) %>
          </div>
        <% } %>

        <div class="tableCard">
          <table>
            <thead>
              <tr>
                <th>EMPLOYEE DETAILS</th>
                <% if (leaveTypes != null) {
                     for (Map<String,Object> t : leaveTypes) { %>
                      <th><%= esc(String.valueOf(t.get("code"))) %></th>
                <%   }
                   } %>
              </tr>
            </thead>

            <tbody>
            <% if (employees == null || employees.isEmpty()) { %>
              <tr>
                <td colspan="<%= (leaveTypes==null?1:leaveTypes.size()+1) %>">
                  <div class="p-20 text-center text-slate-400 font-bold">No employee records found.</div>
                </td>
              </tr>
            <% } else {
                 for (Map<String,Object> e : employees) {
                    int empId = (Integer)e.get("empid");
                    String fullName = String.valueOf(e.get("fullname"));
                    String roleName = String.valueOf(e.get("role"));
                    java.util.Date hireDate = (java.util.Date)e.get("hiredate");
                    String profilePic = (String)e.get("profilePic");

                    Map<Integer, Map<String,Object>> empBalances =
                        (balanceIndex != null ? balanceIndex.get(empId) : null);
            %>
              <tr>
                <td>
                  <div class="empBox">
                    <div class="avatar">
                      <% if (profilePic != null && !profilePic.isBlank()) { %>
                        <img src="<%= ctx + "/" + profilePic %>" alt="Profile"/>
                      <% } else { %>
                        <%= esc(initials(fullName)) %>
                      <% } %>
                    </div>

                    <div>
                      <div class="text-sm font-bold text-slate-800"><%= esc(fullName) %></div>
                      <div class="flex items-center gap-2 mt-0.5">
                          <span class="text-[10px] font-black text-slate-400 uppercase tracking-wider">ID: <%= empId %></span>
                          <span class="w-1 h-1 rounded-full bg-slate-300"></span>
                          <span class="text-[10px] font-bold text-blue-600 uppercase"><%= esc(roleName) %></span>
                      </div>
                      <div class="text-[10px] text-slate-400 font-medium">Joined: <%= (hireDate != null ? sdf.format(hireDate) : "-") %></div>
                    </div>
                  </div>
                </td>

                <% if (leaveTypes != null) {
                     for (Map<String,Object> t : leaveTypes) {
                        int typeId = (Integer)t.get("id");
                        String typeCode = String.valueOf(t.get("code")).toUpperCase();
                        Map<String,Object> bal = (empBalances != null ? empBalances.get(typeId) : null);

                        if (bal == null) { %>
                          <td><div class="noData">Not Assigned</div></td>
                <%      } else {
                          double available = toNum(bal.get("available"));
                          double total     = toNum(bal.get("total"));
                          double used      = toNum(bal.get("used"));
                          double pending   = toNum(bal.get("pending"));
                          double entitlement = toNum(bal.get("entitlement"));
                          double cf        = toNum(bal.get("carriedFwd"));

                          double pct = (total > 0) ? Math.min(100.0, (used/total)*100.0) : 0;
                          
                          // ✅ Color Theming Logic
                          String barColor = "bg-blue-600"; // Default
                          if (typeCode.contains("MATERNITY")) barColor = "bg-pink-500";
                          else if (typeCode.contains("PATERNITY") || typeCode.contains("PARENITY")) barColor = "bg-indigo-500";
                          else if (available <= 0) barColor = "bg-red-500";

                          String numColor = "text-slate-800";
                          if (available <= 0) numColor = "text-red-600";
                %>
                          <td>
                            <div class="balCard">
                              <div class="flex justify-between items-end pb-2">
                                <div>
                                  <div class="bigNum <%= numColor %>"><%= (int)available %></div>
                                  <div class="mutedLabel">Available</div>
                                </div>
                                <div class="text-right">
                                  <div class="text-xs font-extrabold text-slate-500"><%= (int)total %></div>
                                  <div class="mutedLabel">Total</div>
                                </div>
                              </div>

                              <div class="bar"><div class="barFill <%= barColor %>" style="width:<%= pct %>%;"></div></div>

                              <div class="miniRow"><span>Used:</span><b><%= (int)used %></b></div>
                              <div class="miniRow"><span>Pending:</span><b><%= (int)pending %></b></div>
                              <div class="miniRow"><span>Entitled:</span><b><%= (int)entitlement %></b></div>
                              <div class="miniRow"><span>C/F:</span><b><%= (int)cf %></b></div>
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

        <div class="mt-12 text-center opacity-30 text-[10px] font-bold uppercase tracking-widest">
            v1.2.5 © 2024 Klinik Dr Mohamad
        </div>

      </div>
    </div>
  </main>
</body>
</html>