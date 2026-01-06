<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*,java.time.*,java.time.format.*" %>
<%@ include file="icon.jsp" %>
<%@ page import="bean.LeaveBalance, bean.Holiday, util.LeaveBalanceEngine" %>

<%
  // =========================
  // KAWALAN KESELAMATAN
  // =========================
  HttpSession ses = request.getSession(false);
  if (ses == null || ses.getAttribute("empid") == null ||
      ses.getAttribute("role") == null ||
      !"EMPLOYEE".equalsIgnoreCase(String.valueOf(ses.getAttribute("role")))) {
    response.sendRedirect(request.getContextPath() + "/login.jsp?error=Sila+log+masuk+sebagai+pekerja");
    return;
  }

  String fullname = String.valueOf(ses.getAttribute("fullname"));

  // =========================
  // DATA DARI SERVLET
  // =========================
  String dbError = (String) request.getAttribute("dbError");
  String balanceError = (String) request.getAttribute("balanceError");
  
//Use List<LeaveBalance> instead of List<Map>
 List<LeaveBalance> balances = (List<LeaveBalance>) request.getAttribute("balances");
 if (balances == null) balances = new ArrayList<>();

 // Map baki mengikut TypeCode untuk carian UI
 Map<String, LeaveBalance> balByType = new HashMap<>();
 for (LeaveBalance b : balances) {
   if (b == null || b.getTypeCode() == null) continue;
   balByType.put(b.getTypeCode().trim().toUpperCase(), b);
 }

 // Monthly Holidays (Now using Bean list)
 List<Holiday> monthHolidays = (List<Holiday>) request.getAttribute("monthHolidays");
 Map<LocalDate, List<Holiday>> holidayMap = new HashMap<>();
 if (monthHolidays != null) {
     for(Holiday h : monthHolidays) {
         holidayMap.computeIfAbsent(h.getDate(), k -> new ArrayList<>()).add(h);
     }
 }
 
 List<Holiday> holidayUpcoming = (List<Holiday>) request.getAttribute("holidayUpcoming");
 if (holidayUpcoming == null) holidayUpcoming = new ArrayList<>();
  // =========================
  // PENGURUSAN KALENDAR
  // =========================
  LocalDate today = LocalDate.now();
  Integer calYearObj = (Integer) request.getAttribute("calYear");
  Integer calMonthObj = (Integer) request.getAttribute("calMonth");
  int calYear = (calYearObj != null ? calYearObj : today.getYear());
  int calMonth = (calMonthObj != null ? calMonthObj : today.getMonthValue());
  
  YearMonth ym = YearMonth.of(calYear, calMonth);
  LocalDate firstDay = ym.atDay(1);
  int daysInMonth = ym.lengthOfMonth();

  int firstDow = firstDay.getDayOfWeek().getValue() % 7; // Ahad=0
  LocalDate gridStart = firstDay.minusDays(firstDow);
  YearMonth prev = ym.minusMonths(1);
  YearMonth next = ym.plusMonths(1);

  String monthTitle = ym.getMonth().getDisplayName(TextStyle.FULL, Locale.ENGLISH) + " " + calYear;
  DateTimeFormatter fmtLong = DateTimeFormatter.ofPattern("dd MMM yyyy");
%>

<%! 
    // Additional icons for navigation since they aren't in icon.jsp
    public String ChevronLeftIcon(String cls) {
        return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2.5' viewBox='0 0 24 24'><path d='m15 18-6-6 6-6'/></svg>";
    }
    public String ChevronRightIcon(String cls) {
        return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2.5' viewBox='0 0 24 24'><path d='m9 18 6-6-6-6'/></svg>";
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Employee Portal | Dashboard</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  <script src="https://cdn.tailwindcss.com"></script>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  
  <style>
    :root{
      --bg:#f8fafc;
      --card:#fff;
      --border:#e2e8f0;
      --text:#1e293b;
      --muted:#64748b;
      --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
      --radius:16px;
      --sb-w:300px;
      --primary: #2563eb;
      --red: #ef4444;
      --orange: #f97316;
      --blue: #3b82f6;
      --teal: #14b8a6;
      --purple: #a855f7;
      --pink: #ec4899;
      --indigo: #6366f1;
    }
    
    * { box-sizing: border-box; font-family: 'Inter', Arial, sans-serif !important; }
    body { margin:0; background:var(--bg); color:var(--text); overflow-x: hidden; }

    .content { min-height: 100vh; padding: 0; }
    .pageWrap { max-width: 1400px; margin: 0 auto; padding: 32px 40px; }

    h2.title { font-size: 26px; font-weight: 800; margin: 10px 0 6px; color: var(--text); text-transform: uppercase; }
    .sub { color: var(--muted); margin: 0 0 32px; font-size: 15px; font-weight: 500; }

    /* Grid Setup */
    .gridCards {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 20px;
      margin-bottom: 32px;
    }
    @media (max-width: 900px) { .gridCards { grid-template-columns: 1fr; } }
    
    .card {
      background: var(--card); border: 1px solid #f1f5f9; border-radius: var(--radius);
      box-shadow: var(--shadow); padding: 24px; position: relative; overflow: hidden;
      transition: all 0.3s ease; display: flex; flex-direction: column; justify-content: space-between; height: 100%;
    }
    .card:hover { transform: translateY(-4px); box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1); }

    .card.annual { border-top: 5px solid var(--blue); }
    .card.sick { border-top: 5px solid var(--teal); }
    .card.emergency { border-top: 5px solid var(--red); }
    .card.hospitalization { border-top: 5px solid var(--purple); }
    .card.unpaid { border-top: 5px solid var(--muted); }
    .card.maternity { border-top: 5px solid var(--pink); }
    .card.paternity { border-top: 5px solid var(--indigo); }

    .card .label { font-size: 13px; font-weight: 800; color: var(--text); text-transform: uppercase; letter-spacing: .05em; display: flex; justify-content: space-between; align-items: center; }
    .card .big { font-size: 28px; font-weight: 800; margin: 8px 0 2px; color: var(--text); }
    .card .big span { font-size: 14px; color: #94a3b8; font-weight: 500; margin-left: 4px; }
    
    .timeline-track { height: 10px; width: 100%; background: #f1f5f9; border-radius: 10px; margin: 14px 0; overflow: hidden; }
    .timeline-bar { height: 100%; border-radius: 10px; transition: width 0.8s ease; }
    
    .card.annual .timeline-bar { background: var(--blue); }
    .card.sick .timeline-bar { background: var(--teal); }
    .card.emergency .timeline-bar { background: var(--red); }
    .card.hospitalization .timeline-bar { background: var(--purple); }
    .card.unpaid .timeline-bar { background: var(--muted); }
    .card.maternity .timeline-bar { background: var(--pink); }
    .card.paternity .timeline-bar { background: var(--indigo); }

    .card-footer { border-top: 1px solid #f1f5f9; padding-top: 16px; margin-top: auto; }
    .entitlement-text { font-size: 12px; color: var(--muted); margin-bottom: 10px; font-weight: 600; }
    .entitlement-text b { color: #475569; font-weight: 800; }

    .stats-row { display: flex; align-items: center; justify-content: space-between; font-size: 13px; }
    .stat-box { flex: 1; text-align: center; }
    .stat-box span { color: var(--muted); font-size: 10px; text-transform: uppercase; display: block; margin-bottom: 2px; font-weight: 700; }
    .stat-box b { color: var(--text); font-size: 15px; font-weight: 800; }
    .divider { width: 1px; height: 18px; background: #e2e8f0; margin: 0 10px; }

    .gridMain { display: grid; grid-template-columns: 2fr 1.2fr; gap: 24px; margin-top: 8px; align-items: stretch; }
    @media(max-width: 1024px){ .gridMain { grid-template-columns: 1fr; } }

    .cal-card { background: #fff; border: 1px solid var(--border); border-radius: 16px; padding: 24px; box-shadow: var(--shadow); height: 100%; display: flex; flex-direction: column; }
    .calHeader { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; }
    .calTitle { font-weight: 800; font-size: 18px; color: var(--text); }
    
    .calNav { display: flex; gap: 8px; }
    .calNav a { 
        text-decoration: none; 
        width: 32px; height: 32px; 
        display: flex; align-items: center; justify-content: center;
        border: 1px solid var(--border); border-radius: 10px; 
        color: var(--muted); transition: 0.2s; 
    }
    .calNav a:hover { background: #f8fafc; color: var(--text); border-color: var(--text); }

    .calTable { width: 100%; border-collapse: collapse; flex-grow: 1; }
    .calTable th { font-size: 11px; text-transform: uppercase; color: #94a3b8; text-align: center; padding: 8px 0; font-weight: 800; }
    .calTable td { text-align: center; padding: 12px 0; position: relative; }

    .dayBox { display: inline-flex; align-items: center; justify-content: center; width: 34px; height: 34px; border-radius: 10px; font-weight: 800; font-size: 13px; transition: 0.2s; cursor: pointer; }
    .today { background: var(--text) !important; color: #fff !important; }

    .h-dot { width: 6px; height: 6px; border-radius: 50%; margin: 2px auto 0; }
    .h-public-dot { background: var(--red); }
    .h-state-dot { background: var(--orange); }
    .h-company-dot { background: var(--blue); }

    .tipWrap { position: relative; display: inline-block; }
    .tip {
      position: absolute; bottom: 120%; left: 50%; transform: translateX(-50%);
      background: var(--text); color: #fff; padding: 6px 12px; border-radius: 8px; font-size: 10px;
      white-space: nowrap; opacity: 0; pointer-events: none; transition: 0.2s; z-index: 100;
    }
    .tipWrap:hover .tip { opacity: 1; }

    .hListItem { display: flex; gap: 16px; align-items: center; padding: 10px 0; border-bottom: 1px solid #f1f5f9; }
    .dateBadge {
      width: 50px; height: 50px; border-radius: 12px;
      display: flex; flex-direction: column; align-items: center; justify-content: center;
      background: #f8fafc; color: var(--text); font-weight: 800; border: 1px solid var(--border); flex-shrink: 0;
    }
    .dateBadge span:first-child { font-size: 16px; line-height: 1; }
    .dateBadge span:last-child { font-size: 9px; text-transform: uppercase; margin-top: 2px; }
    
    .dateBadge.public { background: #fef2f2; border-color: #fee2e2; color: var(--red); }
    .dateBadge.state { background: #fffaf5; border-color: #ffedd5; color: var(--orange); }
    .dateBadge.company { background: #f0f9ff; border-color: #dbeafe; color: var(--blue); }

    .legend { display: flex; gap: 14px; align-items: center; margin-top: 20px; color: var(--muted); font-size: 11px; font-weight: 800; border-top: 1px solid #f1f5f9; padding-top: 15px; }
    .legend-item { display: flex; align-items: center; gap: 6px; }
    .legend-dot { width: 8px; height: 8px; border-radius: 3px; }

    .err { background:#fef2f2; border:1px solid #fee2e2; color:#991b1b; padding:12px 16px; border-radius:12px; margin-bottom:12px; font-size: 14px; font-weight: 700; }
  </style>
</head>

<body>

  <jsp:include page="sidebar.jsp" />
  
  <main class="ml-20 lg:ml-64 min-h-screen transition-all duration-300">

    <div class="content">
      
      <jsp:include page="topbar.jsp" />

   <div class="pageWrap">
    <% if (dbError != null && !dbError.isBlank()) { %>
      <div class="err">DB ERROR: <%= dbError %></div>
    <% } %>

    <h2 class="title">EMPLOYEE DASHBOARD</h2>
    <p class="sub">Welcome back, <b><%= fullname %></b>. Here is your leave summary.</p>

    <div class="gridCards">
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

          double availPercent = (entVal > 0) ? (totalVal / entVal) * 100 : 0;
      %>
        <div class="card <%= cardTheme %>">
          <div class="label">
            <%= type %> LEAVE
            <%= CalendarIcon("w-4 h-4 opacity-30") %>
          </div>
          
          <div class="big">
            <%= df.format(totalVal) %> <span>Available</span>
          </div>

          <div class="timeline-track">
              <div class="timeline-bar" style="width: <%= Math.min(availPercent, 100) %>%; background: var(--primary);"></div>
          </div>

          <div class="card-footer">
              <div class="entitlement-text">Base Entitlement: <b><%= df.format(entVal) %></b> days/year</div>
              <div class="stats-row">
                  <div class="stat-box">
                      <span>USED</span>
                      <b><%= df.format(usedVal) %></b>
                  </div>
                  <div class="divider"></div>
                  <div class="stat-box">
                      <span>PENDING</span>
                      <b style="color:var(--orange);"><%= df.format(pendVal) %></b>
                  </div>
              </div>
          </div>
        </div>
      <% } %>
    </div>

    <div class="gridMain">
      <div class="cal-card">
        <div class="calHeader">
          <div class="calTitle"><%= monthTitle %></div>
          <div class="calNav">
            <%-- FIXED LINKS: Changed from EmployeeDashboardServlet to EmployeeDashboard --%>
            <a href="EmployeeDashboard?year=<%=prev.getYear()%>&month=<%=prev.getMonthValue()%>">
                <%= ChevronLeftIcon("w-5 h-5") %>
            </a>
            <a href="EmployeeDashboard?year=<%=next.getYear()%>&month=<%=next.getMonthValue()%>">
                <%= ChevronRightIcon("w-5 h-5") %>
            </a>
          </div>
        </div>

        <table class="calTable">
          <thead>
            <tr><th>SUN</th><th>MON</th><th>TUE</th><th>WED</th><th>THU</th><th>FRI</th><th>SAT</th></tr>
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
              %><td><span class="dayBox">&nbsp;</span></td><%
                  } else {
                    LocalDate cursor = ym.atDay(dayCounter);
                    boolean isToday = cursor.equals(today);
                    List<Holiday> hs = holidayMap.get(cursor);
                    boolean isHoliday = (hs != null && !hs.isEmpty());
                    String tipText = ""; String dotClass = ""; 
                    if (isHoliday) {
                      StringBuilder sb = new StringBuilder();
                      String hType = hs.get(0).getType().toUpperCase();
                      for (int k=0; k<hs.size(); k++) {
                        sb.append(hs.get(k).getName());
                        if (k < hs.size()-1) sb.append(" • ");
                      }
                      tipText = sb.toString();
                      if (hType.contains("PUBLIC")) dotClass = "h-public-dot";
                      else if (hType.contains("STATE")) dotClass = "h-state-dot";
                      else if (hType.contains("COMPANY")) dotClass = "h-company-dot";
                    }
              %>
                <td>
                  <div class="tipWrap">
                    <span class="dayBox <%= isToday ? "today" : "" %>"><%= dayCounter %></span>
                    <% if (isHoliday) { %><div class="h-dot <%= dotClass %>"></div><span class="tip"><%= tipText %></span><% } %>
                  </div>
                </td>
              <% dayCounter++; } } %>
            </tr>
          <% if (dayCounter > daysInMonth) break; } %>
          </tbody>
        </table>
      </div>

      <div style="display: flex; flex-direction: column; gap: 20px;">
        <div class="cal-card" style="flex-grow: 1;">
          <h3 style="font-weight:800; font-size:16px; margin: 0 0 16px 0; color: #1e293b; display: flex; align-items: center; gap: 8px;">
              <%= CalendarIcon("w-5 h-5 text-slate-500") %> Upcoming Holidays
          </h3>
          <%
            int upCount = 0;
            for (Holiday h : holidayUpcoming) {
              if (upCount >= 4) break; 
              LocalDate d = h.getDate();
              String hType = h.getType().toUpperCase();
              String badgeCls = hType.contains("PUBLIC") ? "public" : (hType.contains("STATE") ? "state" : "company");
          %>
              <div class="hListItem">
                <div class="dateBadge <%= badgeCls %>">
                  <span><%= d.getDayOfMonth() %></span>
                  <span><%= d.getMonth().getDisplayName(TextStyle.SHORT, Locale.ENGLISH).toUpperCase() %></span>
                </div>
                <div>
                  <p style="font-weight:800; font-size:13px; margin:0;"><%= h.getName() %></p>
                  <div style="color:var(--muted); font-size:11px; font-weight: 700;"><%= h.getType() %></div>
                </div>
              </div>
          <% upCount++; } %>
        </div>

        <div class="cal-card" style="background: #f8fafc; border: 1px dashed #e2e8f0; padding: 15px;">
          <h3 style="font-weight:800; font-size:14px; margin: 0 0 10px 0; color: #1e293b; text-transform: uppercase;">Leave Guidelines</h3>
          <ul style="list-style: none; padding: 0; font-size: 12px; color: #64748b; font-weight: 700;">
            <li style="margin-bottom: 5px;">• Annual: 3 days notice.</li>
            <li style="margin-bottom: 5px;">• Sick: MC required.</li>
            <li style="margin-bottom: 5px;">• Maternity: 98 days (Female).</li>
            <li>• Paternity: 7 days (Male).</li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</div>


</main>
</body>
</html>