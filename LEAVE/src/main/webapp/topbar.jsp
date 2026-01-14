<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="dao.UserDAO" %>
<%@ page import="bean.User" %>
<%@ include file="icon.jsp" %>

<%
    // =========================
    // DATABASE RETRIEVAL (Like profile.jsp approach)
    // =========================
    // Get ID from session
    Integer empidTB = (Integer) session.getAttribute("empid");
    User userTB = null;
    
    if (empidTB != null) {
        try {
            UserDAO uDaoTB = new UserDAO();
            userTB = uDaoTB.getUserById(empidTB);
        } catch(Exception e) {
            // If DB fetch fails, fallback logic will trigger below
        }
    }

    // =========================
    // DATA MAPPING
    // =========================
    String fullNameTB = "User";
    String roleTB = "EMPLOYEE";
    String profilePic = null;

    if (userTB != null) {
        // Data from Database (Fresh)
        fullNameTB = userTB.getFullName();
        roleTB = userTB.getRole();
        profilePic = userTB.getProfilePic();
    } else {
        // Fallback to Session if DB fetch failed or user not found
        fullNameTB = (session.getAttribute("fullname") != null) ? session.getAttribute("fullname").toString() : "User";
        roleTB = (session.getAttribute("role") != null) ? session.getAttribute("role").toString() : "EMPLOYEE";
        Object sPic = session.getAttribute("profilePic");
        profilePic = (sPic != null) ? sPic.toString() : null;
    }

    // =========================
    // FORMATTING LOGIC
    // =========================
    String init = "U";
    if (fullNameTB != null && !fullNameTB.isBlank()) {
        init = ("" + fullNameTB.trim().charAt(0)).toUpperCase();
    }

    // Portal Title based on Role
    String portalName = "Employee Portal";
    if ("ADMIN".equalsIgnoreCase(roleTB)) {
        portalName = "Admin Portal";
    } else if ("MANAGER".equalsIgnoreCase(roleTB)) {
        portalName = "Management Portal";
    }

    // Path Construction Logic
    String finalPicPath = null;
    if (profilePic != null && !profilePic.isBlank() && !profilePic.equalsIgnoreCase("null")) {
        if (profilePic.startsWith("http") || profilePic.startsWith("data:")) {
            finalPicPath = profilePic;
        } else {
            // Prepend context path for relative paths
            String cleanPath = profilePic.startsWith("/") ? profilePic.substring(1) : profilePic;
            finalPicPath = request.getContextPath() + "/" + cleanPath;
        }
    }
%>

<header class="h-16 bg-white/90 backdrop-blur-md border-b border-slate-200 flex items-center justify-between px-8 sticky top-0 z-50 transition-all duration-300">
  
  <!-- Left Side: Portal Identity -->
  <div class="flex items-center gap-4">
    <div class="w-1.5 h-6 bg-blue-600 rounded-full hidden sm:block"></div>
    <h2 class="text-[13px] font-black text-slate-800 tracking-tight uppercase">
      <%= portalName %>
    </h2>
  </div>

  <!-- Right Side: User Dropdown -->
  <div class="flex items-center">
    <div class="relative group">
      
      <!-- Trigger: Avatar -->
      <button class="w-10 h-10 rounded-xl bg-blue-600 flex items-center justify-center text-white font-black text-sm shadow-lg shadow-blue-500/20 border-2 border-slate-50 group-hover:scale-105 group-hover:rotate-2 transition-all overflow-hidden cursor-pointer focus:outline-none">
        <% if (finalPicPath != null) { %>
            <img src="<%= finalPicPath %>" alt="Profile" class="w-full h-full object-cover" onerror="this.style.display='none'; this.parentElement.innerHTML='<%= init %>';">
        <% } else { %>
            <%= init %>
        <% } %>
      </button>

      <!-- Dropdown Menu -->
      <div class="absolute right-0 mt-2 w-56 origin-top-right bg-white border border-slate-200 rounded-2xl shadow-xl opacity-0 invisible translate-y-2 group-hover:opacity-100 group-hover:visible group-hover:translate-y-0 transition-all duration-200 z-50 overflow-hidden">
        
        <div class="px-4 py-3 border-b border-slate-50 bg-slate-50/50">
          <p class="text-[11px] font-black text-slate-900 leading-tight truncate"><%= fullNameTB %></p>
          <p class="text-[9px] text-blue-600 font-extrabold uppercase mt-1 tracking-widest"><%= roleTB %></p>
        </div>

        <div class="py-1">
          <a href="Profile" class="flex items-center gap-3 px-4 py-2.5 text-[11px] font-bold text-slate-600 hover:bg-blue-50 hover:text-blue-600 transition-colors">
            <%= UsersIcon("w-4 h-4") %>
            <span>MY PROFILE</span>
          </a>

          <a href="ChangePassword" class="flex items-center gap-3 px-4 py-2.5 text-[11px] font-bold text-slate-600 hover:bg-blue-50 hover:text-blue-600 transition-colors">
            <%= LockIcon("w-4 h-4") %>
            <span>CHANGE PASSWORD</span>
          </a>

          <a href="LogoutServlet" class="flex items-center gap-3 px-4 py-2.5 text-[11px] font-bold text-red-500 hover:bg-red-50 transition-colors border-t border-slate-50">
            <%= LogOutIcon("w-4 h-4") %>
            <span>LOG OUT</span>
          </a>
        </div>
      </div>

    </div>
  </div>
</header>