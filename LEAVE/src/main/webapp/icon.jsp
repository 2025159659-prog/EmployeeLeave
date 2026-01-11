<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%!
// Home Icon (Dashboard)
public String HomeIcon(String cls) {
return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><path d='m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z'/><polyline points='9 22 9 12 15 12 15 22'/></svg>";
}

// File Plus Icon
public String FilePlusIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><path d='M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z'/><path d='M14 2v4a2 2 0 0 0 2 2h4'/><path d='M9 15h6'/><path d='M12 12v6'/></svg>";
}

// Calendar Icon
public String CalendarIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><rect width='18' height='18' x='3' y='4' rx='2'/><line x1='16' y1='2' x2='16' y2='6'/><line x1='8' y1='2' x2='8' y2='6'/><line x1='3' y1='10' x2='21' y2='10'/></svg>";
}

// Users Icon (Employee)
public String UsersIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><circle cx='9' cy='7' r='4'/><path d='M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2'/><path d='M22 21v-2a4 4 0 0 0-3-3.87'/><path d='M16 3.13a4 4 0 0 1 0 7.75'/></svg>";
}

// Chart Icon (Leave Balances)
public String ChartBarIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><path d='M3 3v18h18'/><path d='M18 17V9'/><path d='M13 17V5'/><path d='M8 17v-3'/></svg>";
}

// Clipboard List Icon (Leave History)
public String ClipboardListIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><rect width='8' height='4' x='8' y='2' rx='1'/><path d='M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2'/><path d='M9 12h6'/><path d='M9 16h6'/><path d='M9 8h6'/></svg>";
}

// Logout Icon
public String LogOutIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><path d='M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4'/><polyline points='16 17 21 12 16 7'/><line x1='21' y1='12' x2='9' y2='12'/></svg>";
}

// Briefcase Icon (Admin Dashboard)
public String BriefcaseIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><rect width='20' height='14' x='2' y='7' rx='2'/><path d='M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16'/></svg>";
}

// Paper Plane Icon (Submit Application)
public String SendIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><line x1='22' y1='2' x2='11' y2='13'/><polygon points='22 2 15 22 11 13 2 9 22 2'/></svg>";
}

// Check Circle Icon (Success/Approval)
public String CheckCircleIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><path d='M22 11.08V12a10 10 0 1 1-5.93-9.14'/><polyline points='22 4 12 14.01 9 11.01'/></svg>";
}

// Edit (Pencil) Icon
public String EditIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><path d='M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7'/><path d='M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z'/></svg>";
}

// Trash (Delete) Icon
public String TrashIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><polyline points='3 6 5 6 21 6'/><path d='M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2'/><line x1='10' y1='11' x2='10' y2='17'/><line x1='14' x2='14' y1='11' y2='17'/></svg>";
}

// Eye (View Details) Icon
public String EyeIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><path d='M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z'/><circle cx='12' cy='12' r='3'/></svg>";
}

// Info Circle Icon
public String InfoIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><circle cx='12' cy='12' r='10'/><line x1='12' y1='16' x2='12' y2='12'/><line x1='12' y1='8' x2='12.01' y2='8'/></svg>";
}

// Alert Circle (Warning) Icon
public String AlertIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><circle cx='12' cy='12' r='10'/><line x1='12' y1='8' x2='12' y2='12'/><line x1='12' y1='16' x2='12.01' y2='16'/></svg>";
}

// --- 10 NEW ICONS ADDED BELOW ---

// Save Icon (Floppy Disk)
public String SaveIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><path d='M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z'/><polyline points='17 21 17 13 7 13 7 21'/><polyline points='7 3 7 8 15 8'/></svg>";
}

// Search Icon
public String SearchIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><circle cx='11' cy='11' r='8'/><line x1='21' y1='21' x2='16.65' y2='16.65'/></svg>";
}

// Filter Icon
public String FilterIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><polygon points='22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3'/></svg>";
}

// Plus Icon (Generic Add)
public String PlusIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><line x1='12' y1='5' x2='12' y2='19'/><line x1='5' y1='12' x2='19' y2='12'/></svg>";
}

// Arrow Left Icon (Back)
public String ArrowLeftIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><line x1='19' y1='12' x2='5' y2='12'/><polyline points='12 19 5 12 12 5'/></svg>";
}

// Clock Icon (History/Pending)
public String ClockIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><circle cx='12' cy='12' r='10'/><polyline points='12 6 12 12 16 14'/></svg>";
}

// X-Circle Icon (Cancel/Reject)
public String XCircleIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><circle cx='12' cy='12' r='10'/><line x1='15' y1='9' x2='9' y2='15'/><line x1='9' y1='9' x2='15' y2='15'/></svg>";
}

// Lock Icon (Security/Permissions)
public String LockIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><rect width='18' height='11' x='3' y='11' rx='2' ry='2'/><path d='M7 11V7a5 5 0 0 1 10 0v4'/></svg>";
}

// Globe Icon (States/Region)
public String GlobeIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><circle cx='12' cy='12' r='10'/><line x1='2' y1='12' x2='22' y2='12'/><path d='M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z'/></svg>";
}

// Shield Check Icon (System Admin/Verification)
public String ShieldCheckIcon(String cls) {
    return "<svg class='" + cls + "' xmlns='http://www.w3.org/2000/svg' fill='none' stroke='currentColor' stroke-width='2' viewBox='0 0 24 24'><path d='M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z'/><path d='m9 12 2 2 4-4'/></svg>";
}


%>