<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%
    Map<String, Integer> leaveStats = (Map<String, Integer>) request.getAttribute("leaveStats");
    Map<String, Integer> monthlyTrends = (Map<String, Integer>) request.getAttribute("monthlyTrends");
%>

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Admin Dashboard | Real-Time Intelligence</title>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  <script src="https://cdn.tailwindcss.com"></script>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
  
  <style>
    :root {
      --bg: #f8fafc;
      --card: #fff;
      --border: #e2e8f0;
      --text: #1e293b;
      --muted: #64748b;
      --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
      --radius: 16px;
      --primary: #2563eb;
      --red: #ef4444;
      --orange: #f97316;
      --blue: #3b82f6;
      --teal: #14b8a6;
      --purple: #a855f7;
      --indigo: #6366f1;
    }
    
    * { 
      box-sizing: border-box; 
      font-family: 'Inter', Arial, sans-serif !important; 
    }
    
    html, body { 
      height: 100vh; 
      width: 100vw;
      overflow: hidden; 
      background: var(--bg); 
      color: var(--text);
      margin: 0;
    }

    /* Consistent Header Styling */
    h2.title { 
      font-size: 26px; 
      font-weight: 800; 
      margin: 0; 
      color: var(--text); 
      text-transform: uppercase; 
      letter-spacing: -0.025em;
    }
    
    .sub-label { 
      color: var(--indigo); 
      font-size: 11px; 
      font-weight: 800; 
      text-transform: uppercase; 
      letter-spacing: 0.1em;
    }

    /* Main Container with Sidebar Offset */
    .main-content {
      flex: 1;
      display: flex;
      flex-direction: column;
      margin-left: 5rem; /* ml-20 default */
      height: 100vh;
      transition: all 0.3s ease;
    }
    @media (min-width: 1024px) {
      .main-content { margin-left: 16rem; /* lg:ml-64 */ }
    }

    .pageWrap { 
      padding: 24px 32px; 
      flex: 1; 
      display: flex; 
      flex-direction: column; 
      gap: 24px;
      overflow-y: auto;
    }

    /* Consistent Card Styling */
    .stat-card {
      background: var(--card); 
      border: 1px solid var(--border); 
      border-radius: var(--radius);
      box-shadow: var(--shadow); 
      padding: 24px; 
      display: flex; 
      align-items: center; 
      justify-content: space-between;
      transition: transform 0.3s ease;
    }
    .stat-card:hover { transform: translateY(-2px); }
    .stat-card.blue { border-left: 5px solid var(--blue); }
    .stat-card.orange { border-left: 5px solid var(--orange); }
    .stat-card.teal { border-left: 5px solid var(--teal); }

    .card-label { 
      font-size: 12px; 
      font-weight: 800; 
      color: var(--muted); 
      text-transform: uppercase; 
      letter-spacing: 0.05em; 
    }
    .card-value { 
      font-size: 32px; 
      font-weight: 800; 
      color: var(--text); 
      line-height: 1;
      margin-top: 4px;
    }

    /* Chart Containers */
    .chart-card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      padding: 24px;
      box-shadow: var(--shadow);
      display: flex;
      flex-direction: column;
    }
    .chart-title {
      font-size: 13px;
      font-weight: 800;
      color: var(--text);
      text-transform: uppercase;
      margin-bottom: 20px;
      display: flex;
      align-items: center;
      gap: 8px;
    }

    /* Clock Widget */
    .clock-box {
      background: var(--card);
      padding: 12px 24px;
      border-radius: var(--radius);
      border: 1px solid var(--border);
      text-align: right;
    }
    #clock { font-size: 24px; font-weight: 800; color: var(--text); font-variant-numeric: tabular-nums; }
    #date { font-size: 10px; font-weight: 700; color: var(--muted); text-transform: uppercase; margin-top: 2px; }

    /* Custom scrollbar for pageWrap */
    .pageWrap::-webkit-scrollbar { width: 6px; }
    .pageWrap::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }
  </style>
</head>

<body class="flex">

    <jsp:include page="sidebar.jsp" />

    <main class="main-content">
        <jsp:include page="topbar.jsp" />

        <div class="pageWrap">
            
            <!-- Header Section -->
            <div class="flex justify-between items-center">
                <div>
                    <h2 class="title">Admin Dashboard</h2>
                    <p class="sub-label">Live Data Visualization</p>
                </div>
                <div class="clock-box shadow-sm">
                    <div id="clock">00:00:00</div>
                    <div id="date">Loading Date...</div>
                </div>
            </div>

            <!-- Stats Grid -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div class="stat-card blue">
                    <div>
                        <p class="card-label">Workforce</p>
                        <h3 class="card-value"><%= request.getAttribute("totalEmployees") %></h3>
                    </div>
                    <div class="text-blue-500/20"><i class="fa fa-users fa-2x"></i></div>
                </div>
                <div class="stat-card orange">
                    <div>
                        <p class="card-label">On Leave Today</p>
                        <h3 class="card-value text-orange-600"><%= request.getAttribute("activeToday") %></h3>
                    </div>
                    <div class="text-orange-500/20"><i class="fa fa-clock fa-2x"></i></div>
                </div>
                <div class="stat-card teal">
                    <div>
                        <p class="card-label">Annual Holidays</p>
                        <h3 class="card-value text-teal-600"><%= request.getAttribute("totalHolidays") %></h3>
                    </div>
                    <div class="text-teal-500/20"><i class="fa fa-calendar-check fa-2x"></i></div>
                </div>
            </div>

            <!-- Charts Section -->
            <div class="grid grid-cols-12 gap-6 flex-1 min-h-0">
                <div class="col-span-12 lg:col-span-7 chart-card">
                    <h4 class="chart-title">
                        <i class="fa fa-chart-bar text-indigo-500"></i>
                        Monthly Absence Volume
                    </h4>
                    <div class="flex-1 min-h-0">
                        <canvas id="barChart"></canvas>
                    </div>
                </div>

                <div class="col-span-12 lg:col-span-5 chart-card">
                    <h4 class="chart-title justify-center">
                        <i class="fa fa-chart-pie text-blue-500"></i>
                        Category Distribution
                    </h4>
                    <div class="flex-1 min-h-0">
                        <canvas id="pieChart"></canvas>
                    </div>
                </div>
            </div>
            
        </div>
    </main>

    <script>
        function updateClock() {
            const now = new Date();
            document.getElementById('clock').textContent = now.toLocaleTimeString('en-GB', { hour12: false });
            document.getElementById('date').textContent = now.toLocaleDateString('en-GB', { 
                weekday: 'long', day: 'numeric', month: 'short', year: 'numeric' 
            });
        }
        setInterval(updateClock, 1000);
        updateClock();

        const chartDefaults = {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { 
                legend: { display: false },
                tooltip: {
                    backgroundColor: '#1e293b',
                    titleFont: { size: 12, weight: 'bold' },
                    bodyFont: { size: 12 },
                    padding: 12,
                    cornerRadius: 8
                }
            }
        };

        // Trend Bar Chart
        new Chart(document.getElementById('barChart'), {
            type: 'bar',
            data: {
                labels: [<% for(String m : monthlyTrends.keySet()) { %> '<%=m%>', <% } %>],
                datasets: [{
                    data: [<% for(Integer v : monthlyTrends.values()) { %> <%=v%>, <% } %>],
                    backgroundColor: '#6366f1',
                    borderRadius: 6,
                    hoverBackgroundColor: '#4f46e5'
                }]
            },
            options: {
                ...chartDefaults,
                scales: {
                    x: { 
                        grid: { display: false }, 
                        ticks: { font: { size: 10, weight: '700' }, color: '#94a3b8' } 
                    },
                    y: { 
                        beginAtZero: true, 
                        grid: { color: '#f1f5f9' },
                        ticks: { font: { size: 10, weight: '700' }, color: '#94a3b8', stepSize: 1 } 
                    }
                }
            }
        });

        // Category Pie Chart
        new Chart(document.getElementById('pieChart'), {
            type: 'doughnut', /* Changed to doughnut for a more modern look */
            data: {
                labels: [<% for(String t : leaveStats.keySet()) { %> '<%=t%>', <% } %>],
                datasets: [{
                    data: [<% for(Integer v : leaveStats.values()) { %> <%=v%>, <% } %>],
                    backgroundColor: ['#3b82f6', '#14b8a6', '#f59e0b', '#ef4444', '#a855f7'],
                    borderWidth: 4,
                    borderColor: '#ffffff',
                    hoverOffset: 4
                }]
            },
            options: {
                ...chartDefaults,
                cutout: '70%',
                plugins: {
                    legend: {
                        display: true,
                        position: 'bottom',
                        labels: { 
                            boxWidth: 8, 
                            usePointStyle: true,
                            font: { size: 11, weight: '700' }, 
                            padding: 20,
                            color: '#64748b'
                        }
                    }
                }
            }
        });
    </script>
</body>
</html>