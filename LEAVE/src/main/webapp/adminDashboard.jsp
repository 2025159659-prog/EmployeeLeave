<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<%
    // Admin guard
    if (session.getAttribute("empid") == null || session.getAttribute("role") == null) {
        response.sendRedirect("login.jsp"); return;
    }
    if (!"ADMIN".equalsIgnoreCase(String.valueOf(session.getAttribute("role")))) {
        response.sendRedirect("login.jsp"); return;
    }

    List<Map<String, Object>> leaves = (List<Map<String, Object>>) request.getAttribute("leaves");
    Integer pendingCount = (Integer) request.getAttribute("pendingCount");
    Integer cancelReqCount = (Integer) request.getAttribute("cancelReqCount");

    String msg = request.getParameter("msg");
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Admin Dashboard</title>
    
    <script src="https://cdn.tailwindcss.com"></script>

    <style>
        :root{
            --bg:#f4f6fb;
            --card:#ffffff;
            --border:#e5e7eb;
            --text:#0f172a;
            --muted:#64748b;
            --primary:#2563eb;
            --primary2:#1d4ed8;
            --dangerBg:#fee2e2;
            --dangerBorder:#fecaca;
            --infoBg:#ecfeff;
            --infoBorder:#a5f3fc;
            --shadow:0 10px 25px rgba(0,0,0,0.06);
            --radius:16px;
            --green:#16a34a;
            --red:#dc2626;
        }

        *{box-sizing:border-box}
        body{margin:0;font-family:Arial, sans-serif;background:var(--bg);color:var(--text);}
        
        /* Buang padding-left manual di sini supaya ml-20 lg:ml-64 ambil alih */
        .content {
            padding: 24px;
        }

        .container{max-width: 1100px; margin:0 auto;}
        .pageHeader{margin-bottom:16px;}
        .pageTitle{margin:0;font-size:22px;font-weight:800;}
        .pageSub{margin-top:6px;font-size:13px;color:var(--muted);}

        /* stats */
        .stats{
            display:grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap:12px;
            margin: 14px 0 18px;
        }
        .stat{
            background:var(--card);
            border:1px solid var(--border);
            border-radius:var(--radius);
            box-shadow:var(--shadow);
            padding:14px 16px;
            display:flex;
            align-items:center;
            justify-content:space-between;
            border-left: 5px solid rgba(37,99,235,0.75);
        }
        .stat.orange{ border-left-color: rgba(249,115,22,0.9); }
        .stat .label{font-size:12px;color:var(--muted);font-weight:800;}
        .stat .num{font-size:26px;font-weight:900;line-height:1;}

        /* card + table */
        .card{
            background:var(--card);
            border:1px solid var(--border);
            border-radius:var(--radius);
            box-shadow:var(--shadow);
            overflow:hidden;
        }
        .cardHead{
            padding:16px 18px;
            border-bottom:1px solid #eef2f7;
            display:flex;
            justify-content:space-between;
            align-items:center;
            gap:12px;
            font-weight:900;
        }
        .hint{font-size:12px;color:var(--muted);font-weight:700;}

        table{width:100%;border-collapse:collapse;}
        th,td{border-bottom:1px solid #eef2f7;padding:14px;text-align:left;vertical-align:top;}
        th{background:#f8fafc;font-size:12px;text-transform:uppercase;color:#334155;}

        .badge{
            display:inline-block;
            font-size:12px;
            font-weight:900;
            padding:4px 10px;
            border-radius:999px;
            border:1px solid var(--border);
            background:#fff;
        }
        .badge.pending{background:#fff7ed;border-color:#fed7aa;color:#9a3412;}
        .badge.cancel{background:#ffedd5;border-color:#fdba74;color:#9a3412;}

        .small{font-size:12px;color:var(--muted);}

        input[type=text]{
            width:100%;
            padding:10px 12px;
            border:1px solid #cbd5e1;
            border-radius:12px;
            font-size:13px;
        }

        .actionsRow{
            display:flex;
            gap:10px;
            margin-top:10px;
        }
        .btn{
            padding:10px 12px;
            border:none;
            border-radius:12px;
            cursor:pointer;
            font-weight:900;
            font-size:12px;
            flex:1;
        }
        .btn.green{background:var(--green);color:#fff;}
        .btn.red{background:var(--red);color:#fff;}

        @media (max-width: 860px){
            .stats{grid-template-columns:1fr;}
        }
    </style>
</head>

<body>
    <jsp:include page="sidebar.jsp" />
    
    <main class="ml-20 lg:ml-64 min-h-screen transition-all duration-300">
        
        <jsp:include page="topbar.jsp" />

        <div class="content">
            <div class="container">

                <div class="pageHeader">
                    <h2 class="pageTitle">Admin Dashboard</h2>
                    <p class="pageSub">Review pending leave requests and cancellation requests.</p>
                </div>

                <div class="stats">
                    <div class="stat">
                        <div>
                            <div class="label">Pending Approvals</div>
                        </div>
                        <div class="num"><%= (pendingCount==null?0:pendingCount) %></div>
                    </div>

                    <div class="stat orange">
                        <div>
                            <div class="label">Cancellation Requests</div>
                        </div>
                        <div class="num"><%= (cancelReqCount==null?0:cancelReqCount) %></div>
                    </div>
                </div>

                <% if (msg != null && !msg.isBlank()) { %>
                    <div class="msgBox"><b><%= msg %></b></div>
                <% } %>

                <div class="card">
                    <div class="cardHead">
                        <span>Action Required</span>
                        <span class="hint"><%= (leaves==null?0:leaves.size()) %> items</span>
                    </div>

                    <div style="overflow-x:auto;">
                        <table>
                            <thead>
                            <tr>
                                <th>Employee</th>
                                <th>Leave Details</th>
                                <th>Reason & Docs</th>
                                <th>Status</th>
                                <th style="width:260px;">Action</th>
                            </tr>
                            </thead>
                            <tbody>
                            <%
                                if (leaves == null || leaves.isEmpty()) {
                            %>
                                <tr>
                                    <td colspan="5" style="text-align:center; padding:22px;">
                                        <span class="small">All caught up! No pending requests.</span>
                                    </td>
                                </tr>
                            <%
                                } else {
                                    for (Map<String, Object> r : leaves) {
                                        String fullname = String.valueOf(r.get("fullname"));
                                        int empid = (Integer) r.get("empid");
                                        String leaveType = String.valueOf(r.get("leaveType"));
                                        String duration = String.valueOf(r.get("duration"));
                                        Object startDate = r.get("startDate");
                                        Object endDate = r.get("endDate");
                                        String reason = (String) r.get("reason");
                                        String attachment = (String) r.get("attachment");
                                        String status = String.valueOf(r.get("status"));

                                        boolean isCancelReq = "CANCELLATION_REQUESTED".equalsIgnoreCase(status);
                            %>
                                <tr>
                                    <td>
                                        <b><%= fullname %></b><br/>
                                        <span class="small">EMPID: <%= empid %></span>
                                    </td>

                                    <td>
                                        <div style="margin-bottom:6px;">
                                            <span class="badge"><%= leaveType %></span>
                                        </div>
                                        <span class="small">Start:</span> <%= startDate %><br/>
                                        <span class="small">End:</span> <%= endDate %><br/>
                                        <span class="small">Duration:</span> <%= duration %>
                                    </td>

                                    <td>
                                        <span class="small"><b>Reason:</b></span><br/>
                                        <%= (reason == null || reason.isBlank()) ? "-" : reason %>
                                        <br/><br/>
                                        <span class="small"><b>Attachment:</b></span><br/>
                                        <%= (attachment == null || attachment.isBlank()) ? "-" : attachment %>
                                    </td>

                                    <td>
                                        <% if (isCancelReq) { %>
                                            <span class="badge cancel">Cancel Requested</span>
                                        <% } else { %>
                                            <span class="badge pending">Pending Review</span>
                                        <% } %>
                                        <div class="small" style="margin-top:8px;"><b><%= status %></b></div>
                                    </td>

                                    <td>
                                        <form action="AdminLeaveActionServlet" method="post">
                                            <input type="hidden" name="leaveId" value="<%= r.get("leaveId") %>"/>
                                            <input type="text" name="comment" placeholder="Comment (optional)"/>
                                            <div class="actionsRow">
                                                <% if (isCancelReq) { %>
                                                    <button class="btn green" name="action" value="APPROVE_CANCEL" type="submit">Approve Cancel</button>
                                                    <button class="btn red" name="action" value="REJECT" type="submit">Reject</button>
                                                <% } else { %>
                                                    <button class="btn green" name="action" value="APPROVE" type="submit">Approve</button>
                                                    <button class="btn red" name="action" value="REJECT" type="submit">Reject</button>
                                                <% } %>
                                            </div>
                                        </form>
                                    </td>
                                </tr>
                            <%
                                    }
                                }
                            %>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div></div></main>
</body>
</html>

