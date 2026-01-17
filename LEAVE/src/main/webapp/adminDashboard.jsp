<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*"%>
<%@ page import="java.time.*"%>
<%@ include file="icon.jsp"%>
<%
// Data retrieved from Servlet
Map<String, Integer> leaveStats = (Map<String, Integer>) request.getAttribute("leaveStats");
Map<String, Integer> monthlyTrends = (Map<String, Integer>) request.getAttribute("monthlyTrends");
List<String> years = (List<String>) request.getAttribute("years");

// Get current filter from parameters or default to current year
String selectedYear = request.getParameter("year");
if (selectedYear == null || selectedYear.isEmpty()) {
	selectedYear = String.valueOf(LocalDate.now().getYear());
}

// Default workforce stats if null
Object totalEmployees = request.getAttribute("totalEmployees");
Object activeToday = request.getAttribute("activeToday");
Object totalHolidays = request.getAttribute("totalHolidays");
%>

<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Admin Dashboard | Enterprise Intelligence</title>
<link rel="stylesheet"
	href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<script src="https://cdn.tailwindcss.com"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
<link
	href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap"
	rel="stylesheet">

<style>
:root {
	--bg: #f1f5f9;
	--card: #fff;
	--border: #e2e8f0;
	--text: #1e293b;
	--muted: #64748b;
	--radius: 20px;
	--blue: #3b82f6;
	--orange: #f97316;
	--teal: #14b8a6;
	--blue-primary: #2563eb;
}

* {
	box-sizing: border-box;
	font-family: 'Inter', sans-serif !important;
}

body {
	background: var(--bg);
	color: var(--text);
	margin: 0;
	overflow-x: hidden;
}

.main-content {
	flex: 1;
	margin-left: 5rem;
	transition: all 0.3s ease;
}

@media ( min-width : 1024px) {
	.main-content {
		margin-left: 16rem;
	}
}

.pageWrap {
	padding: 32px 40px;
	max-width: 1300px;
	margin: 0 auto;
}

.title {
	font-size: 26px;
	font-weight: 800;
	margin: 0;
	text-transform: uppercase;
	color: var(--text);
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

/* ✅ FULL OUTLINE COLOURED CARDS */
.stat-card {
	background: var(--card);
	border-radius: var(--radius);
	box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
	padding: 24px;
	display: flex;
	align-items: center;
	justify-content: space-between;
	transition: all 0.3s ease;
	border: 2px solid transparent;
}

.stat-card:hover {
	transform: translateY(-4px);
	box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
}

/* Full color line borders */
.stat-card.blue {
	border-color: var(--blue);
	background-color: #eff6ff;
}

.stat-card.orange {
	border-color: var(--orange);
	background-color: #fff7ed;
}

.stat-card.teal {
	border-color: var(--teal);
	background-color: #f0fdfa;
}

.card-label {
	font-size: 11px;
	font-weight: 800;
	color: var(--muted);
	text-transform: uppercase;
	letter-spacing: 0.05em;
}

.card-value {
	font-size: 32px;
	font-weight: 900;
	color: var(--text);
	line-height: 1;
	margin-top: 4px;
}

/* Chart Containers */
.chart-card {
	background: var(--card);
	border: 1px solid var(--border);
	border-radius: var(--radius);
	padding: 28px;
	box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.05);
	display: flex;
	flex-direction: column;
}

.chart-header {
	display: flex;
	justify-content: space-between;
	align-items: center;
	margin-bottom: 24px;
}

.chart-title {
	font-size: 13px;
	font-weight: 800;
	color: var(--text);
	text-transform: uppercase;
	display: flex;
	align-items: center;
	gap: 8px;
}

/* Minimal Filter Dropdown */
.chart-filter {
	padding: 6px 12px;
	border-radius: 10px;
	border: 1.5px solid #e2e8f0;
	font-size: 11px;
	font-weight: 700;
	color: #64748b;
	outline: none;
	cursor: pointer;
	transition: 0.2s;
	background: #fff;
}

.chart-filter:focus {
	border-color: var(--blue-primary);
	color: var(--blue-primary);
}

.clock-box {
	text-align: right;
}

#clock {
	font-size: 24px;
	font-weight: 900;
	color: var(--text);
	font-variant-numeric: tabular-nums;
}

#date {
	font-size: 10px;
	font-weight: 700;
	color: var(--muted);
	text-transform: uppercase;
}
</style>
</head>

<body class="flex">

	<jsp:include page="sidebar.jsp" />

	<main class="main-content min-h-screen">
		<jsp:include page="topbar.jsp" />

		<div class="pageWrap">

			<!-- Header Section -->
			<div class="flex justify-between items-center mb-8">
				<div>
					<h2 class="title">Admin Dashboard</h2>
					<p class="sub-label">Analytic Intelligence Unit</p>
				</div>
				<div class="clock-box">
					<div id="clock">00:00:00</div>
					<div id="date">Loading...</div>
				</div>
			</div>

			<div class="grid grid-cols-1 md:grid-cols-3 gap-8 mb-8">
				<div class="stat-card blue">
					<div>
						<p class="card-label">Total Workforce</p>
						<h3 class="card-value"><%=totalEmployees != null ? totalEmployees : 0%></h3>
					</div>
					<div class="text-blue-500/10"><%=UsersIcon("w-12 h-12")%></div>
				</div>
				<div class="stat-card orange">
					<div>
						<p class="card-label">Absence Today</p>
						<h3 class="card-value text-orange-600"><%=activeToday != null ? activeToday : 0%></h3>
					</div>
					<div class="text-orange-500/10"><%=ClockIcon("w-12 h-12")%></div>
				</div>
				<div class="stat-card teal">
					<div>
						<p class="card-label">Annual Holidays</p>
						<h3 class="card-value text-teal-600"><%=totalHolidays != null ? totalHolidays : 0%></h3>
					</div>
					<div class="text-teal-500/10"><%=CalendarIcon("w-12 h-12")%></div>
				</div>
			</div>

			<div class="grid grid-cols-12 gap-8">

				<div class="col-span-12 lg:col-span-7 chart-card">
					<div class="chart-header">
						<h4 class="chart-title">
							<span class="text-indigo-500"><%=ChartBarIcon("w-5 h-5")%></span>
							Monthly Trends (<%=selectedYear%>)
						</h4>
						<!-- Individual Chart Filter -->
						<select
							onchange="window.location.href='AdminDashboard?year='+this.value"
							class="chart-filter">
							<%
							if (years != null) {
								for (String yr : years) {
							%>
							<option value="<%=yr%>"
								<%=yr.equals(selectedYear) ? "selected" : ""%>><%=yr%></option>
							<%
							}
							}
							%>
						</select>
					</div>
					<div class="h-[350px]">
						<canvas id="barChart"></canvas>
					</div>
				</div>

				<!-- Pie Chart Column -->
				<div class="col-span-12 lg:col-span-5 chart-card">
					<div class="chart-header">
						<h4 class="chart-title">
							<span class="text-blue-500"><%=ClipboardListIcon("w-5 h-5")%></span>
							Leave Category
						</h4>
						<!-- Individual Chart Filter -->
						<select
							onchange="window.location.href='AdminDashboard?year='+this.value"
							class="chart-filter">
							<%
							if (years != null) {
								for (String yr : years) {
							%>
							<option value="<%=yr%>"
								<%=yr.equals(selectedYear) ? "selected" : ""%>><%=yr%></option>
							<%
							}
							}
							%>
						</select>
					</div>
					<div class="h-[350px]">
						<canvas id="pieChart"></canvas>
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
            if (clockEl) clockEl.textContent = now.toLocaleTimeString('en-GB', { hour12: false });
            if (dateEl) dateEl.textContent = now.toLocaleDateString('en-GB', { 
                weekday: 'long', day: 'numeric', month: 'short', year: 'numeric' 
            });
        }
        setInterval(updateClock, 1000);
        updateClock();

        /**
         * Robust Data Injection
         * We use manual iteration to prevent trailing commas which trigger SyntaxErrors
         */
        const trendLabels = [
            <%if (monthlyTrends != null && !monthlyTrends.isEmpty()) {
	int i = 0;
	for (String key : monthlyTrends.keySet()) {%>
                    '<%=key.replace("'", "\\'")%>'<%=(i < monthlyTrends.size() - 1 ? "," : "")%>
                <%i++;
}
}%>
        ];
        const trendData = [
            <%if (monthlyTrends != null && !monthlyTrends.isEmpty()) {
				int i = 0;
				for (Integer val : monthlyTrends.values()) {%>
                    <%=val%><%=(i < monthlyTrends.size() - 1 ? "," : "")%>
                <%i++;
}
}%>
        ];
        
        const catLabels = [
            <%if (leaveStats != null && !leaveStats.isEmpty()) {
				int i = 0;
				for (String key : leaveStats.keySet()) {%>
                    '<%=key.replace("'", "\\'")%>'<%=(i < leaveStats.size() - 1 ? "," : "")%>
                <%i++;
}
}%>
        ];
        const catData = [
            <%if (leaveStats != null && !leaveStats.isEmpty()) {
				int i = 0;
				for (Integer val : leaveStats.values()) {%>
                    <%=val%><%=(i < leaveStats.size() - 1 ? "," : "")%>
                <%i++;
}
}%>
        ];

        // Monthly Trend Chart
        const ctxBar = document.getElementById('barChart');
        if (ctxBar && trendLabels.length > 0) {
            new Chart(ctxBar, {
                type: 'bar',
                data: {
                    labels: trendLabels,
                    datasets: [{
                        label: 'Leave Volume',
                        data: trendData,
                        backgroundColor: '#6366f1',
                        borderRadius: 10,
                        hoverBackgroundColor: '#4f46e5',
                        barThickness: 25
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                        x: { grid: { display: false }, ticks: { font: { weight: '700' }, color: '#94a3b8' } },
                        y: { beginAtZero: true, grid: { color: '#f1f5f9' }, ticks: { stepSize: 1, color: '#94a3b8' } }
                    }
                }
            });
        }

        const ctxPie = document.getElementById('pieChart');
        if (ctxPie && catLabels.length > 0) {
            new Chart(ctxPie, {
                type: 'doughnut',
                data: {
                    labels: catLabels,
                    datasets: [{
                        data: catData,
                        backgroundColor: ['#3b82f6', '#14b8a6', '#f59e0b', '#ef4444', '#a855f7'],
                        borderWidth: 5,
                        borderColor: '#ffffff',
                        hoverOffset: 15
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    cutout: '75%',
                    plugins: {
                        legend: {
                            position: 'bottom',
                            labels: { padding: 25, usePointStyle: true, font: { weight: '700', size: 11 }, color: '#64748b' }
                        }
                    }
                }
            });
        }
    </script>
</body>
</html>