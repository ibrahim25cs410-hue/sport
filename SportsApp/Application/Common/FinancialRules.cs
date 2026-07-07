namespace Riyada.Application.Common;

public static class FinancialRules
{
    /// <summary>نسبة عمولة المنصة (10%).</summary>
    public const decimal PlatformCommissionRate = 0.10m;

    public const int MinBookingHours = 1;
    public const int MaxBookingHours = 2;
    public const int CancelWindowHours = 24;

    /// <summary>إلغاء مجاني إذا بقي 24 ساعة أو أكثر قبل الموعد.</summary>
    public const int FreeCancellationHours = 24;

    /// <summary>غرامة إلغاء متأخر إذا بقي 12 ساعة أو أقل.</summary>
    public const int LateCancellationHours = 12;

    public const int LateCancellationPenaltyIqd = 5000;
    public const int LateCancellationOwnerShareIqd = 2500;
    public const int LateCancellationPlatformShareIqd = 2500;

    /// <summary>FCM alert when owner wallet drops below this amount (IQD).</summary>
    public const int WalletLowBalanceAlertThresholdIqd = 5000;

    /// 9:00 ص — 12:00 م (منتصف الليل)
    public const int OpenHour = 9;
    public const int CloseHour = 24;

    /// <summary>Thu–Sat surcharge per hour (IQD).</summary>
    public const int PeakDaySurchargePerHourIqd = 3000;

    public const int LoyaltyPointsForDiscount = 10;

    public const decimal LoyaltyDiscountRate = 0.10m;

    public static bool IsPeakPricingDay(DateTime date) =>
        date.DayOfWeek is DayOfWeek.Thursday or DayOfWeek.Friday or DayOfWeek.Saturday;

    public static int HourlyRate(int basePricePerHour, DateTime date) =>
        basePricePerHour + (IsPeakPricingDay(date) ? PeakDaySurchargePerHourIqd : 0);

    public static BookingPriceQuote CalculateBookingPrice(
        int basePricePerHour, DateTime date, int hours, int loyaltyPoints = 0)
    {
        var hourly = HourlyRate(basePricePerHour, date);
        var subtotal = hourly * hours;
        var applyDiscount = loyaltyPoints >= LoyaltyPointsForDiscount;
        var discount = applyDiscount ? RoundIqd(subtotal * LoyaltyDiscountRate) : 0;
        return new BookingPriceQuote(
            basePricePerHour,
            hourly,
            hours,
            subtotal,
            discount,
            applyDiscount,
            subtotal - discount);
    }

    /// <summary>عمولة المنصة = (سعر الساعة × عدد الساعات) × 10%.</summary>
    public static int CalculateCommission(int pricePerHour, int hours) =>
        RoundIqd((decimal)pricePerHour * hours * PlatformCommissionRate);

    /// <summary>عمولة المنصة من إجمالي الحجز (سعر الساعة × الساعات).</summary>
    public static int CalculateCommissionFromTotal(int totalPrice) =>
        RoundIqd((decimal)totalPrice * PlatformCommissionRate);

    public static int RoundIqd(decimal amount) =>
        (int)decimal.Round(amount, 0, MidpointRounding.AwayFromZero);
}
