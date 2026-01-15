import java.time.LocalDate;
import java.time.Year;
import java.time.temporal.ChronoUnit;

/**
 * LeaveBalanceEngine strictly follows the Malaysia Employment Act 1955 (Updated 2023).
 */
public class LeaveBalanceEngine {

    public static class EntitlementResult {
        public final int baseEntitlement;      // The full yearly quota
        public final double proratedEntitlement; // Quota adjusted for new hires

        public EntitlementResult(int baseEntitlement, double proratedEntitlement) {
            this.baseEntitlement = baseEntitlement;
            this.proratedEntitlement = proratedEntitlement;
        }
    }

    /**
     * Dasar kelayakan cuti Malaysia (EA 1955):
     * * 1. ANNUAL LEAVE (Section 60E):
     * - < 2 years: 8 days
     * - 2-5 years: 12 days
     * - > 5 years: 16 days
     * * 2. SICK LEAVE (Section 60F):
     * - < 2 years: 14 days
     * - 2-5 years: 18 days
     * - > 5 years: 22 days
     * * 3. HOSPITALIZATION (Section 60F):
     * - 60 days per year. 
     * - Note: This is usually the total including used sick leave, 
     * but most systems treat it as a separate 60-day buffer.
     * * 4. MATERNITY LEAVE (Section 37 - Amendment 2023):
     * - 98 days. (Required: Employed > 90 days total).
     * * 5. PATERNITY LEAVE (Section 60A - Amendment 2023):
     * - 7 days. (Required: At least 12 months service with same employer).
     */
    public static int baseEntitlementByType(String typeCode, long serviceYears, String genderUpper, long totalDaysEmployed) {
        String t = typeCode == null ? "" : typeCode.trim().toUpperCase();
        String g = genderUpper == null ? "" : genderUpper.trim().toUpperCase();

        switch (t) {
            case "ANNUAL":
                if (serviceYears < 2) return 8;
                if (serviceYears < 5) return 12;
                return 16;

            case "SICK":
                if (serviceYears < 2) return 14;
                if (serviceYears < 5) return 18;
                return 22;

            case "HOSPITALIZATION":
                return 60;

            case "MATERNITY":
                // Must be female and worked at least 90 days
                if ((g.equals("F") || g.equals("FEMALE")) && totalDaysEmployed >= 90) return 98;
                return 0;

            case "PATERNITY":
                // Must be male and worked at least 12 months (365 days)
                if ((g.equals("M") || g.equals("MALE")) && totalDaysEmployed >= 365) return 7;
                return 0;

            case "EMERGENCY":
                return 5; // Company discretion (Standard is 2-5 days)

            case "UNPAID":
                return 0; // Usually no base entitlement for unpaid leave

            default:
                return 0;
        }
    }

    /**
     * Calculates total years of service.
     */
    public static long serviceYears(LocalDate hireDate, LocalDate today) {
        if (hireDate == null || today.isBefore(hireDate)) return 0;
        return ChronoUnit.YEARS.between(hireDate, today);
    }

    /**
     * Computes final entitlement. 
     * Rules: Prorate only for the year the employee was hired.
     */
    public static EntitlementResult computeEntitlement(String typeCode, LocalDate hireDate, String genderUpper) {
        LocalDate today = LocalDate.now();
        long totalYears = serviceYears(hireDate, today);
        long daysEmployed = (hireDate != null) ? ChronoUnit.DAYS.between(hireDate, today) : 0;
        
        int base = baseEntitlementByType(typeCode, totalYears, genderUpper, daysEmployed);

        // Prorating Logic: Only applies to Annual/Sick for the first year of employment.
        int currentYear = today.getYear();
        boolean hiredThisYear = (hireDate != null && hiredThisYear(hireDate, currentYear));
        String t = (typeCode != null) ? typeCode.trim().toUpperCase() : "";
        
        // Under EA 1955, Paternity/Maternity/Hospitalization are usually NOT prorated.
        boolean isProratable = t.equals("ANNUAL") || t.equals("SICK");

        if (!hiredThisYear || !isProratable) {
            return new EntitlementResult(base, (double) base);
        }

        // EA 1955 Section 60E(1): Entitlement is in proportion to the completed months of service.
        long completedMonths = ChronoUnit.MONTHS.between(hireDate, LocalDate.of(currentYear, 12, 31).plusDays(1));
        
        // Malaysia HR Standard prorating
        double prorated = (completedMonths / 12.0) * base;
        
        // Round to 1 decimal point
        prorated = Math.round(prorated * 10.0) / 10.0;

        return new EntitlementResult(base, prorated);
    }

    private static boolean hiredThisYear(LocalDate hireDate, int currentYear) {
        return hireDate.getYear() == currentYear;
    }

    /**
     * Logic for Carried Forward Leave (Bawa Cuti Ke Tahun Depan).
     * * @param remainingLastYear The balance left at the end of December 31st.
     * @param maxCarryLimit The company's policy limit (e.g., max 5 days or 50% of entitlement).
     * @return The amount allowed to be brought forward to the current year.
     */
    public static double calculateAllowableCarryForward(double remainingLastYear, double maxCarryLimit) {
        if (remainingLastYear <= 0) return 0.0;
        
        // Return the remaining balance but capped at the company's max limit
        return Math.min(remainingLastYear, maxCarryLimit);
    }

    /**
     * Calculates the final available days for the current session.
     * Formula: (Current Year Entitlement + Carried Forward) - (Used + Pending)
     */
    public static double availableDays(double currentEntitlement, double carriedFwd, double used, double pending) {
        double totalPool = currentEntitlement + carriedFwd;
        double available = totalPool - used - pending;
        return Math.max(0, available); // Prevent negative balances
    }
}