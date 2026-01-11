<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="icon.jsp" %>

<%
    // Retrieve user data from session
    String fullNameTB = (session.getAttribute("fullname") != null)
            ? session.getAttribute("fullname").toString()
            : "User";

    String roleTB = (session.getAttribute("role") != null)
            ? session.getAttribute("role").toString()
            : "EMPLOYEE";

    // Generate initial for avatar fallback
    String initialTB = (fullNameTB != null && !fullNameTB.isBlank()) 
            ? ("" + fullNameTB.trim().charAt(0)).toUpperCase() : "U";

    // Dynamic Portal Title based on Role
    String portalName = "Employee Portal";
    if ("ADMIN".equalsIgnoreCase(roleTB)) {
        portalName = "Admin Portal";
    } else if ("MANAGER".equalsIgnoreCase(roleTB)) {
        portalName = "Management Portal";
    }

    // Retrieve profile picture path from session
    Object sessionPic = session.getAttribute("profilePic");
    String profilePicTB = (sessionPic != null) ? sessionPic.toString() : null;
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

    <!-- Profile Dropdown Container -->
    <div class="relative group">
      
      <!-- Trigger: Avatar only -->
      <button class="w-10 h-10 rounded-xl bg-blue-600 flex items-center justify-center text-white font-black text-sm shadow-lg shadow-blue-500/20 border-2 border-slate-50 group-hover:scale-105 group-hover:rotate-2 transition-all overflow-hidden cursor-pointer focus:outline-none">
        <% if (profilePicTB != null && !profilePicTB.isBlank()) { %>
          <img src="<%= profilePicTB %>" alt="Profile" class="w-full h-full object-cover">
        <% } else { %>
          <%= initialTB %>
        <% } %>
      </button>

      <!-- Dropdown Menu -->
      <div class="absolute right-0 mt-2 w-56 origin-top-right bg-white border border-slate-200 rounded-2xl shadow-xl opacity-0 invisible translate-y-2 group-hover:opacity-100 group-hover:visible group-hover:translate-y-0 transition-all duration-200 z-50 overflow-hidden">
        
        <!-- Header Info (Optional but good for context) -->
        <div class="px-4 py-3 border-b border-slate-50 bg-slate-50/50">
          <p class="text-[11px] font-black text-slate-900 leading-tight truncate"><%= fullNameTB %></p>
          <p class="text-[9px] text-slate-400 font-extrabold uppercase mt-1 tracking-widest"><%= roleTB %></p>
        </div>

        <div class="py-1">
          <!-- Profile Link -->
          <a href="Profile" class="flex items-center gap-3 px-4 py-2.5 text-[11px] font-bold text-slate-600 hover:bg-blue-50 hover:text-blue-600 transition-colors">
            <%= UsersIcon("w-4 h-4") %>
            <span>MY PROFILE</span>
          </a>

          <!-- Change Password Link -->
          <a href="ChangePassword" class="flex items-center gap-3 px-4 py-2.5 text-[11px] font-bold text-slate-600 hover:bg-blue-50 hover:text-blue-600 transition-colors">
            <%= LockIcon("w-4 h-4") %>
            <span>CHANGE PASSWORD</span>
          </a>

          <!-- Logout Link -->
          <a href="LogoutServlet" class="flex items-center gap-3 px-4 py-2.5 text-[11px] font-bold text-red-500 hover:bg-red-50 transition-colors border-t border-slate-50">
            <%= LogOutIcon("w-4 h-4") %>
            <span>LOG OUT</span>
          </a>
        </div>
      </div>

    </div>
  </div>
</header>