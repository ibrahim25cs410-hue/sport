namespace Riyada.Domain.Entities;

/// <summary>
/// دفع حجز المستخدم — رموز معاملة فقط، بدون بيانات بطاقة.
/// </summary>
public class BookingPayment
{
    public int Id { get; set; }
    public int BookingId { get; set; }
    public int UserId { get; set; }
    public int Amount { get; set; }
    public string Gateway { get; set; } = "";
    public string TransactionToken { get; set; } = "";
    public string? ProviderReference { get; set; }
    public string? GatewayTransactionId { get; set; }
    public string Status { get; set; } = "initiated";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? VerifiedAt { get; set; }

    public Booking? Booking { get; set; }
    public User? User { get; set; }
}
