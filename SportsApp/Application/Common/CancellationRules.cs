namespace Riyada.Application.Common;

/// <summary>نتيجة تقييم سياسة الإلغاء قبل تنفيذ الإلغاء.</summary>
public enum CancellationTier
{
    /// <summary>لا يمكن الإلغاء (انتهى الموعد أو حالة غير نشطة).</summary>
    NotAllowed = 0,
    /// <summary>إلغاء مجاني — قبل الموعد بـ 24 ساعة أو أكثر (وبين 12–24 ساعة).</summary>
    Free = 1,
    /// <summary>إلغاء متأخر — قبل الموعد بـ 12 ساعة أو أقل → غرامة 5,000 د.ع.</summary>
    LatePenalty = 2,
}

public record CancellationOutcome(
    CancellationTier Tier,
    int PenaltyIqd,
    int OwnerShareIqd,
    int PlatformShareIqd)
{
    public static CancellationOutcome Free() => new(CancellationTier.Free, 0, 0, 0);

    public static CancellationOutcome Late() => new(
        CancellationTier.LatePenalty,
        FinancialRules.LateCancellationPenaltyIqd,
        FinancialRules.LateCancellationOwnerShareIqd,
        FinancialRules.LateCancellationPlatformShareIqd);
}

public static class CancellationRules
{
    public static CancellationOutcome Evaluate(DateTime startTime, DateTime? now = null)
    {
        var hours = (BookingClock.ToUtc(startTime) - (now is null ? BookingClock.UtcNow : BookingClock.ToUtc(now.Value))).TotalHours;
        if (hours <= 0)
            return new CancellationOutcome(CancellationTier.NotAllowed, 0, 0, 0);
        if (hours <= FinancialRules.LateCancellationHours)
            return CancellationOutcome.Late();
        return CancellationOutcome.Free();
    }
}
