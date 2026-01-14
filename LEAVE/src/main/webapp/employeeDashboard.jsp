<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*,java.time.*,java.time.format.*" %>
<%@ include file="icon.jsp" %>
<%@ page import="bean.LeaveBalance, bean.Holiday, util.LeaveBalanceEngine" %>

<%
//=========================
// SECURITY & DATA LOGIC (UNCHANGED)
//=========================
HttpSession ses = request.getSession(false);
String role = (ses != null) ? String.valueOf(ses.getAttribute("role")) : "";

if (ses == null || ses.getAttribute("empid") == null ||
(!"EMPLOYEE".equalsIgnoreCase(role) && !"MANAGER".equalsIgnoreCase(role))) {
response.sendRedirect(request.getContextPath() + "/login.jsp?error=Please+login+as+employee+or+manager");
return;
}
  String fullname = String.valueOf(ses.getAttribute("fullname"));

  String dbError = (String) request.getAttribute("dbError");
  List<LeaveBalance> balances = (List<LeaveBalance>) request.getAttribute("balances");
  if (balances == null) balances = new ArrayList<>();

  Map<String, LeaveBalance> balByType = new HashMap<>();
  for (LeaveBalance b : balances) {
    if (b == null || b.getTypeCode() == null) continue;
    balByType.put(b.getTypeCode().trim().toUpperCase(), b);
  }

  List<Holiday> monthHolidays = (List<Holiday>) request.getAttribute("monthHolidays");
  Map<LocalDate, List<Holiday>> holidayMap = new HashMap<>();
  if (monthHolidays != null) {
      for(Holiday h : monthHolidays) {
          holidayMap.computeIfAbsent(h.getDate(), k -> new ArrayList<>()).add(h);
      }
  }
  
  List<Holiday> holidayUpcoming = (List<Holiday>) request.getAttribute("holidayUpcoming");
  if (holidayUpcoming == null) holidayUpcoming = new ArrayList<>();

  LocalDate today = LocalDate.now();
  Integer calYearObj = (Integer) request.getAttribute("calYear");
  Integer calMonthObj = (Integer) request.getAttribute("calMonth");
  int calYear = (calYearObj != null ? calYearObj : today.getYear());
  int calMonth = (calMonthObj != null ? calMonthObj : today.getMonthValue());
  
  YearMonth ym = YearMonth.of(calYear, calMonth);
  LocalDate firstDay = ym.atDay(1);
  int daysInMonth = ym.lengthOfMonth();
  int firstDow = firstDay.getDayOfWeek().getValue() % 7; 

  YearMonth prev = ym.minusMonths(1);
  YearMonth next = ym.plusMonths(1);
  String monthTitle = ym.getMonth().getDisplayName(TextStyle.FULL, Locale.ENGLISH) + " " + calYear;
%>

<%! 
    public String ChevronLeftIcon(String cls) {
        return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='3' viewBox='0 0 24 24'><path d='m15 18-6-6 6-6'/></svg>";
    }
    public String ChevronRightIcon(String cls) {
        return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='3' viewBox='0 0 24 24'><path d='m9 18 6-6-6-6'/></svg>";
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Employee Portal | Dashboard</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
  
  <style>
    :root{
      --bg:#f8fafc; --card:#fff; --border:#e2e8f0; --text:#1e293b; --muted:#64748b;
      --shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05); --radius:12px;
      --primary: #2563eb; --red: #ef4444; --orange: #f97316; --blue: #3b82f6;
      --teal: #14b8a6; --purple: #a855f7; --pink: #ec4899; --indigo: #6366f1;
    }
    
    * { box-sizing: border-box; font-family: 'Inter', sans-serif !important; }
    body { margin:0; background:var(--bg); color:var(--text); overflow: hidden; height: 100vh; }

    /* Headers - Kept same as requested */
    h2.title { font-size: 26px; font-weight: 800; margin: 10px 0 6px; color: var(--text); text-transform: uppercase; }
    .sub { color: var(--muted); margin: 0 0 24px; font-size: 15px; font-weight: 500; }

    /* Layout Controls */
    .pageWrap { height: calc(100vh - 80px); padding: 15px 30px; display: flex; flex-direction: column; overflow: hidden; }
    
    .card {
      background: var(--card); border-radius: var(--radius);
      box-shadow: var(--shadow); padding: 8px 12px; position: relative; overflow: hidden;
      display: flex; flex-direction: column; transition: all 0.2s;
    }

    /* FULL Borders for Each Card */
    .card.annual { border: 2px solid var(--blue); }
    .card.sick { border: 2px solid var(--teal); }
    .card.emergency { border: 2px solid var(--red); }
    .card.hospitalization { border: 2px solid var(--purple); }
    .card.unpaid { border: 2px solid var(--muted); }
    .card.maternity { border: 2px solid var(--pink); }
    .card.paternity { border: 2px solid var(--indigo); }

    .card:hover { transform: scale(1.01); }

    .card .label-badge { font-size: 7px; font-weight: 900; color: var(--muted); text-transform: uppercase; letter-spacing: .02em; background: #f1f5f9; padding: 2px 6px; border-radius: 4px; border: 1px solid #e2e8f0; }
    .card .big { font-size: 18px; font-weight: 900; margin: 0; color: var(--text); line-height: 1.1; }
    .card .big .slash { color: #cbd5e1; font-weight: 400; margin: 0 1px; }
    
    .card-footer { border-top: 1px solid #f8fafc; padding-top: 4px; margin-top: 4px; }
    .stats-row { display: flex; align-items: center; justify-content: space-between; font-size: 9px; }
    .stat-box span { color: var(--muted); font-size: 7px; text-transform: uppercase; font-weight: 800; display: block; }
    .stat-box b { color: var(--text); font-size: 11px; font-weight: 900; }

    /* Calendar Styling - Reduced size */
    .cal-card { background: #fff; border: 1px solid var(--border); border-radius: var(--radius); padding: 12px; box-shadow: var(--shadow); }
    .calHeader { display: flex; align-items: center; justify-content: space-between; margin-bottom: 8px; }
    .calTitle { font-weight: 900; font-size: 14px; color: var(--text); }
    .calTable { width: 100%; text-align: center; border-collapse: separate; border-spacing: 0.5px; }
    .calTable th { font-size: 8px; color: #94a3b8; font-weight: 900; padding: 2px 0; }
    .dayBox { display: inline-flex; align-items: center; justify-content: center; width: 24px; height: 24px; border-radius: 8px; font-weight: 900; font-size: 10px; transition: 0.2s; cursor: pointer; }
    .today { background: var(--text) !important; color: #fff !important; }

    /* Tooltip Hover Tooltip */
    .tipWrap { position: relative; display: inline-block; }
    .tip {
      position: absolute; bottom: 125%; left: 50%; transform: translateX(-50%);
      background: #1e293b; color: #fff; padding: 4px 8px; border-radius: 6px; font-size: 9px;
      white-space: nowrap; opacity: 0; pointer-events: none; transition: 0.2s; z-index: 100; font-weight: 700;
    }
    .tipWrap:hover .tip { opacity: 1; }

    .h-dot { width: 4px; height: 4px; border-radius: 50%; margin: 1px auto 0; }
    .h-public-dot { background: var(--red); }
    .h-state-dot { background: var(--orange); }
    .h-company-dot { background: var(--blue); }

    /* Holiday Items - Reduced size */
    .hListItem { display: flex; gap: 8px; align-items: center; padding: 6px 0; border-bottom: 1px solid #f8fafc; }
    .dateBadge {
      width: 36px; height: 36px; border-radius: 8px; flex-shrink: 0;
      display: flex; flex-direction: column; align-items: center; justify-content: center;
      background: #f8fafc; border: 1px solid var(--border);
    }
    .dateBadge span:first-child { font-size: 13px; font-weight: 900; line-height: 1; }
    .dateBadge span:last-child { font-size: 7px; font-weight: 800; text-transform: uppercase; }
    
    .dateBadge.public { background: #fef2f2; border-color: #fee2e2; color: var(--red); }
    .dateBadge.state { background: #fffaf5; border-color: #ffedd5; color: var(--orange); }
    .dateBadge.company { background: #f0f9ff; border-color: #dbeafe; color: var(--blue); }

    .err { background:#fef2f2; border:1px solid #fee2e2; color:#991b1b; padding:8px 12px; border-radius:12px; margin-bottom:12px; font-size: 12px; font-weight: 700; }
    
    /* Scrollbar */
    .custom-scrollbar::-webkit-scrollbar { width: 3px; }
    .custom-scrollbar::-webkit-scrollbar-thumb { background: #e2e8f0; border-radius: 10px; }
  </style>
</head>

<body>
  <jsp:include page="sidebar.jsp" />
  
  <main class="ml-20 lg:ml-64 h-screen flex flex-col transition-all duration-300 overflow-hidden">
    <jsp:include page="topbar.jsp" />

    <div class="pageWrap">
      <% if (dbError != null && !dbError.isBlank()) { %>
        <div class="err">DB ERROR: <%= dbError %></div>
      <% } %>

      <h2 class="title uppercase">EMPLOYEE DASHBOARD</h2>
      <p class="sub">Welcome back, <b><%= fullname %></b>. Here is your leave summary.</p>

      <div class="flex-1 flex flex-col lg:flex-row gap-5 min-h-0">
        
        <!-- Left Section: Leave Cards (Smaller & Responsive Grid) -->
        <div class="flex-[1.4] grid grid-cols-2 gap-3 overflow-y-auto pr-2 custom-scrollbar align-content-start">
          <%
            java.text.DecimalFormat df = new java.text.DecimalFormat("0.#");
            List<String> typesOrder = new ArrayList<>(Arrays.asList("ANNUAL", "SICK", "EMERGENCY", "HOSPITALIZATION", "UNPAID", "MATERNITY", "PATERNITY"));
            
            for (String type : typesOrder) {
              LeaveBalance b = balByType.get(type);
              if (b == null) continue;

              double entVal   = b.getEntitlement();
              double usedVal  = b.getUsed();
              double pendVal  = b.getPending();
              double totalVal = b.getTotalAvailable();
              
              String cardTheme = type.toLowerCase().replace(" ", "-");
              if (cardTheme.contains("maternity")) cardTheme = "maternity";
              else if (cardTheme.contains("paternity")) cardTheme = "paternity";
          %>
            <div class="card <%= cardTheme %>">
              <div class="flex justify-between items-start mb-1">
                <div class="p-1 bg-slate-50 rounded-lg border border-slate-100 text-slate-400">
                  <%= CalendarIcon("w-3 h-3") %>
                </div>
                <span class="label-badge"><%= type.replace("_", " ") %></span>
              </div>
              
              <div>
                <span class="text-[8px] font-black text-slate-400 uppercase tracking-widest block">Available</span>
                <div class="big flex items-baseline">
                  <span class="tracking-tighter"><%= df.format(totalVal) %><span class="slash">/</span><%= df.format(entVal) %></span>
                  <span class="text-[9px] font-bold text-slate-400 uppercase ml-1">Days</span>
                </div>
              </div>

              <div class="card-footer">
                <div class="stats-row">
                  <div class="stat-box">
                    <span>USED</span>
                    <b><%= df.format(usedVal) %></b>
                  </div>
                  <div class="stat-box text-right">
                    <span>PENDING</span>
                    <b style="color:var(--orange);"><%= df.format(pendVal) %></b>
                  </div>
                </div>
              </div>
            </div>
          <% } %>
        </div>

        <!-- Right Section: Tools (Calendar & Holidays) -->
        <div class="flex-1 flex flex-col gap-3 min-w-[280px] max-w-full lg:max-w-[400px]">
          
          <!-- Calendar Card -->
          <div class="cal-card shrink-0">
            <div class="calHeader">
              <div class="calTitle uppercase tracking-tighter font-black text-slate-800"><%= monthTitle %></div>
              <div class="flex gap-1">
                <a href="EmployeeDashboard?year=<%=prev.getYear()%>&month=<%=prev.getMonthValue()%>" class="w-6 h-6 flex items-center justify-center border border-slate-100 rounded-lg hover:bg-slate-50 transition-colors">
                  <%= ChevronLeftIcon("w-3 h-3 text-slate-400") %>
                </a>
                <a href="EmployeeDashboard?year=<%=next.getYear()%>&month=<%=next.getMonthValue()%>" class="w-6 h-6 flex items-center justify-center border border-slate-100 rounded-lg hover:bg-slate-50 transition-colors">
                  <%= ChevronRightIcon("w-3 h-3 text-slate-400") %>
                </a>
              </div>
            </div>

            <table class="calTable">
              <thead>
                <tr><th>S</th><th>M</th><th>T</th><th>W</th><th>T</th><th>F</th><th>S</th></tr>
              </thead>
              <tbody>
              <%
                int dayCounter = 1;
                for (int row = 0; row < 6; row++) {
              %>
                <tr>
                  <%
                    for (int col = 0; col < 7; col++) {
                      int cellIndex = row * 7 + col;
                      if (cellIndex < firstDow || dayCounter > daysInMonth) {
                  %><td><span class="dayBox text-slate-100">&bull;</span></td><%
                      } else {
                        LocalDate cursor = ym.atDay(dayCounter);
                        boolean isToday = cursor.equals(today);
                        List<Holiday> hs = holidayMap.get(cursor);
                        boolean isHoliday = (hs != null && !hs.isEmpty());
                        
                        String hNames = "";
                        String dotClass = "";
                        if (isHoliday) {
                          StringBuilder sb = new StringBuilder();
                          for (int k=0; k<hs.size(); k++) {
                            sb.append(hs.get(k).getName());
                            if (k < hs.size()-1) sb.append(" • ");
                          }
                          hNames = sb.toString();
                          String hType = hs.get(0).getType().toUpperCase();
                          if (hType.contains("PUBLIC")) dotClass = "h-public-dot";
                          else if (hType.contains("STATE")) dotClass = "h-state-dot";
                          else if (hType.contains("COMPANY")) dotClass = "h-company-dot";
                        }
                  %>
                    <td>
                      <div class="tipWrap">
                        <span class="dayBox <%= isToday ? "today shadow-sm" : "hover:bg-slate-50 text-slate-600" %>">
                          <%= dayCounter %>
                        </span>
                        <% if (isHoliday) { %>
                          <div class="h-dot <%= dotClass %>"></div>
                          <span class="tip"><%= hNames %></span>
                        <% } %>
                      </div>
                    </td>
                  <% dayCounter++; } } %>
                </tr>
              <% if (dayCounter > daysInMonth) break; } %>
              </tbody>
            </table>
          </div>

          <!-- Upcoming Holidays Card -->
          <div class="cal-card flex-1 overflow-hidden flex flex-col">
            <h3 class="font-black text-[10px] uppercase text-slate-400 tracking-widest mb-2 flex items-center gap-2 border-b pb-1 border-slate-50 shrink-0">
               <%= CalendarIcon("w-3 h-3 text-blue-500") %> Upcoming Holidays
            </h3>
            <div class="overflow-y-auto pr-1 flex-1 custom-scrollbar no-scrollbar">
              <%
                int upCount = 0;
                for (Holiday h : holidayUpcoming) {
                  if (upCount >= 6) break; 
                  LocalDate d = h.getDate();
                  String hType = h.getType().toUpperCase();
                  String badgeCls = hType.contains("PUBLIC") ? "public" : (hType.contains("STATE") ? "state" : "company");
              %>
                  <div class="hListItem">
                    <div class="dateBadge <%= badgeCls %>">
                      <span><%= d.getDayOfMonth() %></span>
                      <span><%= d.getMonth().getDisplayName(TextStyle.SHORT, Locale.ENGLISH).toUpperCase() %></span>
                    </div>
                    <div class="min-w-0">
                      <p class="font-black text-[10px] text-slate-800 truncate leading-tight"><%= h.getName() %></p>
                      <div class="text-[8px] font-bold text-slate-400 uppercase tracking-tight truncate"><%= h.getType() %></div>
                    </div>
                  </div>
              <% upCount++; } %>
            </div>
          </div>

        </div>
      </div>
    </div>
  </main>
</body>
</html>