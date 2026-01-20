<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.,java.time.,java.time.format.*"%>
<%@ include file="icon.jsp"%>
<%@ page import="bean.LeaveBalance, bean.Holiday, util.LeaveBalanceEngine"%>

<%
//=========================
// SECURITY & DATA LOGIC
//=========================
HttpSession ses = request.getSession(false);
String role = (ses != null) ? String.valueOf(ses.getAttribute("role")) : "";

if (ses == null || ses.getAttribute("empid") == null
		|| (!"EMPLOYEE".equalsIgnoreCase(role) && !"MANAGER".equalsIgnoreCase(role))) {
	response.sendRedirect(request.getContextPath() + "/login.jsp?error=Please+login+as+employee+or+manager");
	return;
}
String fullname = String.valueOf(ses.getAttribute("fullname"));

String dbError = (String) request.getAttribute("dbError");
List<LeaveBalance> balances = (List<LeaveBalance>) request.getAttribute("balances");
if (balances == null)
	balances = new ArrayList<>();

Map<String, LeaveBalance> balByType = new HashMap<>();
for (LeaveBalance b : balances) {
	if (b == null || b.getTypeCode() == null)
		continue;
	balByType.put(b.getTypeCode().trim().toUpperCase(), b);
}

List<Holiday> monthHolidays = (List<Holiday>) request.getAttribute("monthHolidays");
Map<LocalDate, List<Holiday>> holidayMap = new HashMap<>();
if (monthHolidays != null) {
	for (Holiday h : monthHolidays) {
		holidayMap.computeIfAbsent(h.getDate(), k -> new ArrayList<>()).add(h);
	}
}

List<Holiday> holidayUpcoming = (List<Holiday>) request.getAttribute("holidayUpcoming");
if (holidayUpcoming == null)
	holidayUpcoming = new ArrayList<>();

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
String monthTitle = ym.getMonth().getDisplayName(TextStyle.FULL, Locale.ENGLISH).toUpperCase() + " " + calYear;
%>

<%!public String ChevronLeftIcon(String cls) {
		return "<svg class='" + cls
				+ "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='3' viewBox='0 0 24 24'><path d='m15 18-6-6 6-6'/></svg>";
	}
	public String ChevronRightIcon(String cls) {
		return "<svg class='" + cls
				+ "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='3' viewBox='0 0 24 24'><path d='m9 18 6-6-6-6'/></svg>";
	}%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Employee Dashboard | Klinik Dr Mohamad</title>
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
	--radius: 20px;
	--shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.04);
}

* {
	box-sizing: border-box;
	font-family: 'Inter', sans-serif !important;
}

body {
	margin: 0;
	background: var(--bg);
	color: var(--text);
	min-height: 100vh;
	-webkit-font-smoothing: antialiased;
}

/* Page Wrapper Responsiveness - Removed restrictive centering */
.pageWrap {
	padding: 24px 20px;
	display: flex;
	flex-direction: column;
	width: 100%;
}

@media (min-width: 768px) {
    .pageWrap {
        padding: 32px 30px;
    }
}

.title {
	font-size: 26px;
	font-weight: 800;
	margin: 0;
	text-transform: uppercase;
	color: var(--text);
	letter-spacing: -0.02em;
}

.sub-label {
	color: var(--blue-primary);
	font-size: 11px;
	font-weight: 800;
	text-transform: uppercase;
	letter-spacing: 0.1em;
	margin-top: 4px;
	display: block;
}

/* Leave Cards Design */
.card {
	background: var(--card);
	border-radius: 16px;
	border: 1px solid var(--border);
	box-shadow: var(--shadow);
	padding: 16px 20px;
	position: relative;
	display: flex;
	flex-direction: column;
	transition: all 0.2s ease;
	border-left-width: 5px;
    min-height: 170px;
}

.card:hover {
	transform: translateY(-2px);
	box-shadow: 0 12px 20px -5px rgba(0, 0, 0, 0.08);
}

/* Left Border Coloring */
.card.annual { border-left-color: #3b82f6; background: linear-gradient(to right, #eff6ff 0%, #ffffff 20%); }
.card.sick { border-left-color: #14b8a6; background: linear-gradient(to right, #f0fdfa 0%, #ffffff 20%); }
.card.emergency { border-left-color: #ef4444; background: linear-gradient(to right, #fef2f2 0%, #ffffff 20%); }
.card.hospitalization { border-left-color: #a855f7; background: linear-gradient(to right, #faf5ff 0%, #ffffff 20%); }
.card.unpaid { border-left-color: #64748b; background: linear-gradient(to right, #f8fafc 0%, #ffffff 20%); }
.card.maternity { border-left-color: #ec4899; background: linear-gradient(to right, #fdf2f8 0%, #ffffff 20%); }
.card.paternity { border-left-color: #6366f1; background: linear-gradient(to right, #f5f3ff 0%, #ffffff 20%); }

.label-badge {
	font-size: 9px;
	font-weight: 900;
	color: #1e293b;
	text-transform: uppercase;
	letter-spacing: .05em;
	background: rgba(255, 255, 255, 0.8);
	padding: 3px 10px;
	border-radius: 8px;
	border: 1px solid #e2e8f0;
}

.card .big {
	font-size: 26px;
	font-weight: 900;
	color: #000;
	margin-top: 6px;
	line-height: 1;
}

.card .big .slash {
	color: #cbd5e1;
	margin: 0 2px;
}

.card-footer {
	border-top: 1.5px solid #f1f5f9;
	padding-top: 12px;
	margin-top: auto;
}

.stats-row {
	display: flex;
	align-items: center;
	justify-content: space-between;
}

.stat-box span {
	color: var(--muted);
	font-size: 9px;
	text-transform: uppercase;
	font-weight: 800;
	display: block;
	margin-bottom: 2px;
}

.stat-box b {
	color: #1e293b;
	font-size: 14px;
	font-weight: 900;
}

/* Calendar Styling - Larger Size */
.cal-card {
	background: #fff;
	border: 1px solid var(--border);
	border-radius: var(--radius);
	padding: 24px;
	box-shadow: var(--shadow);
}

.calHeader {
	display: flex;
	align-items: center;
	justify-content: space-between;
	margin-bottom: 16px;
}

.calTitle {
	font-weight: 950;
	font-size: 17px;
	color: #0f172a;
    letter-spacing: -0.02em;
}

.calTable {
	width: 100%;
	text-align: center;
}

.calTable th {
	font-size: 11px;
	color: #94a3b8;
	font-weight: 900;
	padding-bottom: 12px;
	text-transform: uppercase;
}

.dayBox {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	width: 38px;
	height: 38px;
	border-radius: 12px;
	font-weight: 900;
	font-size: 13px;
	transition: 0.2s;
	cursor: pointer;
    margin-bottom: 2px;
}

@media (max-width: 480px) {
    .dayBox { width: 32px; height: 32px; font-size: 11px; }
}

.today {
	background: #000 !important;
	color: #fff !important;
}

/* Tooltip */
.tipWrap {
	position: relative;
	display: inline-block;
}

.tip {
	position: absolute;
	bottom: 125%;
	left: 50%;
	transform: translateX(-50%);
	background: #0f172a;
	color: #fff;
	padding: 6px 10px;
	border-radius: 8px;
	font-size: 10px;
	white-space: nowrap;
	opacity: 0;
	pointer-events: none;
	transition: 0.2s;
	z-index: 100;
	font-weight: 700;
}

.tipWrap:hover .tip {
	opacity: 1;
}

.h-dot {
	width: 6px;
	height: 6px;
	border-radius: 50%;
	margin: 2px auto 0;
}

.h-public-dot { background: #ef4444; }
.h-state-dot { background: #f97316; }
.h-company-dot { background: #3b82f6; }

/* Holiday Items */
.hListItem {
	display: flex;
	gap: 12px;
	align-items: center;
	padding: 12px 0;
	border-bottom: 1px solid #f8fafc;
}

.dateBadge {
	width: 44px;
	height: 44px;
	border-radius: 12px;
	flex-shrink: 0;
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	background: #f8fafc;
	border: 1px solid var(--border);
}

.dateBadge span:first-child {
	font-size: 16px;
	font-weight: 950;
	line-height: 1;
}

.dateBadge span:last-child {
	font-size: 9px;
	font-weight: 800;
	text-transform: uppercase;
}

.dateBadge.public { background: #fef2f2; border-color: #fee2e2; color: #ef4444; }
.dateBadge.state { background: #fffaf5; border-color: #ffedd5; color: #f97316; }
.dateBadge.company { background: #f0f9ff; border-color: #dbeafe; color: #3b82f6; }

.custom-scrollbar::-webkit-scrollbar { width: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #e2e8f0; border-radius: 10px; }

.clock-box { text-align: left; }
@media (min-width: 768px) { .clock-box { text-align: right; } }

#clock {
	font-size: 28px;
	font-weight: 950;
	color: var(--text);
	font-variant-numeric: tabular-nums;
    line-height: 1;
}

#date {
	font-size: 10px;
	font-weight: 700;
	color: var(--muted);
	text-transform: uppercase;
    margin-top: 4px;
}
</style>
</head>

<body class="overflow-x-hidden">
	<jsp:include page="sidebar.jsp" />

	<main class="ml-20 lg:ml-64 min-h-screen flex flex-col transition-all duration-300">
		<jsp:include page="topbar.jsp" />

		<div class="pageWrap">
			<% if (dbError != null && !dbError.isBlank()) { %>
			<div class="bg-red-50 text-red-600 p-4 rounded-xl mb-6 font-bold text-sm border border-red-100 uppercase">
				DB ERROR: <%=dbError%>
			</div>
			<% } %>

			<!-- Header Section -->
			<div class="flex flex-col md:flex-row justify-between items-center mb-8 gap-6">
				<div>
					<h2 class="title">EMPLOYEE DASHBOARD</h2>
					<span class="sub-label"> Welcome back <span
						class="text-[15px] font-black"><%=fullname%></span> <br> Access your leave summary and calendar
					</span>
			    </div>

                <div class="clock-box bg-white/60 px-6 py-3 rounded-2xl border border-white shadow-sm">
                    <div id="clock">00:00:00</div>
                    <div id="date">Loading...</div>
                </div>
		    </div>

		<div class="flex flex-col lg:flex-row gap-10 items-start">

			<!-- Left Section: Leave Cards - Grid locked to 2 columns on desktop -->
			<div class="w-full lg:flex-1 grid grid-cols-1 sm:grid-cols-2 gap-5">
				<%
				java.text.DecimalFormat df = new java.text.DecimalFormat("0.#");
				List<String> typesOrder = new ArrayList<>(
						Arrays.asList("ANNUAL", "SICK", "EMERGENCY", "HOSPITALIZATION", "UNPAID", "MATERNITY", "PATERNITY"));

				for (String type : typesOrder) {
					LeaveBalance b = balByType.get(type);
					if (b == null)
						continue;

					double entVal = b.getEntitlement();
					double usedVal = b.getUsed();
					double pendVal = b.getPending();
					double totalVal = b.getTotalAvailable();

					String cardTheme = type.toLowerCase().replace(" ", "-");
					if (cardTheme.contains("maternity"))
						cardTheme = "maternity";
					else if (cardTheme.contains("paternity"))
						cardTheme = "paternity";
				%>
				<div class="card <%=cardTheme%>">
					<div class="flex justify-between items-start mb-3">
						<div
							class="w-9 h-9 bg-white/80 rounded-xl border border-slate-100 flex items-center justify-center text-slate-600 shadow-sm">
							<%=CalendarIcon("w-5 h-5")%>
						</div>
						<span class="label-badge"><%=type.replace("_", " ")%></span>
					</div>

					<div class="mt-1">
						<span
							class="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-0.5">Available
							Balance</span>
						<div class="big flex items-baseline">
							<span><%=df.format(totalVal)%><span class="slash">/</span><%=df.format(entVal)%></span>
							<span
								class="text-[11px] font-black text-slate-400 uppercase ml-2">Days</span>
						</div>
					</div>

					<div class="card-footer">
						<div class="stats-row">
							<div class="stat-box">
								<span>Taken</span> <b><%=df.format(usedVal)%></b>
							</div>
							<div class="stat-box text-right">
								<span>Pending</span> <b class="text-orange-500"><%=df.format(pendVal)%></b>
							</div>
						</div>
					</div>
				</div>
				<%
				}
				%>
			</div>

			<!-- Right Section: Tools - Calendar and Holidays -->
			<div class="w-full lg:w-[420px] flex flex-col gap-8">

				<!-- Calendar Card -->
				<div class="cal-card">
					<div class="calHeader">
						<div class="calTitle uppercase tracking-tighter font-black"><%=monthTitle%></div>
						<div class="flex gap-2">
							<a href="EmployeeDashboard?year=<%=prev.getYear()%>&month=<%=prev.getMonthValue()%>"
								class="w-9 h-9 flex items-center justify-center border border-slate-100 rounded-xl hover:bg-slate-50 transition-colors shadow-sm bg-white">
								<%=ChevronLeftIcon("w-4 h-4 text-slate-500")%>
							</a> <a
								href="EmployeeDashboard?year=<%=next.getYear()%>&month=<%=next.getMonthValue()%>"
								class="w-9 h-9 flex items-center justify-center border border-slate-100 rounded-xl hover:bg-slate-50 transition-colors shadow-sm bg-white">
								<%=ChevronRightIcon("w-4 h-4 text-slate-500")%>
							</a>
						</div>
					</div>

					<table class="calTable">
						<thead>
							<tr>
								<th>S</th><th>M</th><th>T</th><th>W</th><th>T</th><th>F</th><th>S</th>
							</tr>
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
								%><td><span class="dayBox text-slate-100">&bull;</span></td>
								<%
								} else {
								LocalDate cursor = ym.atDay(dayCounter);
								boolean isToday = cursor.equals(today);
								List<Holiday> hs = holidayMap.get(cursor);
								boolean isHoliday = (hs != null && !hs.isEmpty());

								String hNames = "";
								String dotClass = "";
								if (isHoliday) {
									StringBuilder sb = new StringBuilder();
									for (int k = 0; k < hs.size(); k++) {
										sb.append(hs.get(k).getName());
										if (k < hs.size() - 1)
									sb.append(" • ");
									}
									hNames = sb.toString();
									String hType = hs.get(0).getType().toUpperCase();
									if (hType.contains("PUBLIC"))
										dotClass = "h-public-dot";
									else if (hType.contains("STATE"))
										dotClass = "h-state-dot";
									else if (hType.contains("COMPANY"))
										dotClass = "h-company-dot";
								}
								%>
								<td>
									<div class="tipWrap">
										<span
											class="dayBox <%=isToday ? "today shadow-lg" : "hover:bg-slate-100 text-slate-600"%>">
											<%=dayCounter%>
										</span>
										<%
										if (isHoliday) {
										%>
										<div class="h-dot <%=dotClass%>"></div>
										<span class="tip"><%=hNames%></span>
										<%
										}
										%>
									</div>
								</td>
								<%
								dayCounter++;
								}
								}
								%>
							</tr>
							<%
							if (dayCounter > daysInMonth)
								break;
							}
							%>
						</tbody>
					</table>
				</div>

				<!-- Upcoming Holidays Card -->
				<div class="cal-card flex flex-col">
					<h3 class="font-black text-[12px] uppercase text-slate-400 tracking-widest mb-4 flex items-center gap-2 border-b pb-4 border-slate-50 shrink-0">
						<%=CalendarIcon("w-4 h-4 text-blue-500")%>
						Upcoming Holidays
					</h3>
					<div class="space-y-1">
						<%
						int upCount = 0;
						for (Holiday h : holidayUpcoming) {
							if (upCount >= 5)
								break;
							LocalDate d = h.getDate();
							String hType = h.getType().toUpperCase();
							String badgeCls = hType.contains("PUBLIC") ? "public" : (hType.contains("STATE") ? "state" : "company");
						%>
						<div class="hListItem hover:bg-slate-50 px-2 rounded-xl transition-colors border-none">
							<div class="dateBadge <%=badgeCls%>">
								<span><%=d.getDayOfMonth()%></span> <span><%=d.getMonth().getDisplayName(TextStyle.SHORT, Locale.ENGLISH).toUpperCase()%></span>
							</div>
							<div class="min-w-0">
								<p class="font-bold text-[13px] text-slate-800 truncate leading-tight uppercase mb-1"><%=h.getName()%></p>
								<div class="text-[10px] font-black text-slate-400 uppercase tracking-tighter"><%=h.getType()%></div>
							</div>
						</div>
						<%
						upCount++;
						}
						%>
						<%
						if (holidayUpcoming.isEmpty()) {
						%>
						<p class="text-[11px] font-bold text-slate-300 italic text-center py-10">No upcoming holidays scheduled.</p>
						<%
						}
						%>
					</div>
				</div>

			</div>
		</div>
		</div>
	</main>

	<script>
		function updateClock() {
			const now = new Date();
			const clockEl = document.getElementById('clock');
			const dateEl = document.getElementById('date');
			if (clockEl)
				clockEl.textContent = now.toLocaleTimeString('en-GB', {
					hour12 : false
				});
			if (dateEl)
				dateEl.textContent = now.toLocaleDateString('en-GB', {
					weekday : 'long',
					day : 'numeric',
					month : 'short',
					year : 'numeric'
				});
		}
		setInterval(updateClock, 1000);
		updateClock();
	</script>
</body>
</html>
