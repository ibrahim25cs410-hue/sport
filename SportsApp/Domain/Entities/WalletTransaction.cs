namespace Riyada.Domain.Entities;

public class WalletTransaction
{
    public int Id { get; set; }
    public int WalletId { get; set; }
    /// <summary>Positive = credit, negative = debit (IQD).</summary>
    public int Amount { get; set; }
    public string Type { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    /// <summary>Admin-provided reason for manual credits (AdminCredit only).</summary>
    public string? AdminNote { get; set; }
    public int? BookingId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Wallet? Wallet { get; set; }
    public Booking? Booking { get; set; }
}

public static class WalletTransactionTypes
{
    public const string CommissionDebit = "commission_debit";
    public const string AdminCredit = "admin_credit";
    public const string SystemAdjustment = "system_adjustment";

    public const string CancellationCredit = "cancellation_credit";

    /// <summary>Legacy rows — mapped to <see cref="AdminCredit"/> in API responses.</summary>
    public const string LegacyAdminTopUp = "admin_top_up";
    public const string LegacyOwnerTopUp = "owner_top_up";

    public static string Normalize(string type) => type switch
    {
        LegacyAdminTopUp or LegacyOwnerTopUp => AdminCredit,
        _ => type
    };

    public static string Label(string type) => Normalize(type) switch
    {
        CommissionDebit => "خصم عمولة",
        AdminCredit => "شحن إداري",
        CancellationCredit => "حصة إلغاء متأخر",
        SystemAdjustment => "تعديل نظام",
        _ => type
    };

    public static bool IsAllowedCreditType(string type) =>
        Normalize(type) is AdminCredit or SystemAdjustment or CancellationCredit;
}
