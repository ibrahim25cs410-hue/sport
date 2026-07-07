namespace Riyada.Domain.Entities;

/// <summary>
/// سجل دفع خارجي — يخزّن رموز المعاملة فقط، بدون بيانات بطاقة.
/// </summary>
public class PlatformPayment
{
    public int Id { get; set; }
    public int InvoiceId { get; set; }
    public int OwnerId { get; set; }
    public int Amount { get; set; }
    /// <summary>zaincash | card</summary>
    public string Gateway { get; set; } = "";
    public string TransactionToken { get; set; } = "";
    public string? ProviderReference { get; set; }
    /// <summary>معرّف المعاملة من بوابة الدفع — فريد لمنع التكرار (Idempotency).</summary>
    public string? GatewayTransactionId { get; set; }
    /// <summary>initiated | verified | failed</summary>
    public string Status { get; set; } = "initiated";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? VerifiedAt { get; set; }

    public OwnerFeeInvoice? Invoice { get; set; }
    public User? Owner { get; set; }
}
