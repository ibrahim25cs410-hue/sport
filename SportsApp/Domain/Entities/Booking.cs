namespace Riyada.Domain.Entities;

public class Booking
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int FieldId { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public int Hours { get; set; }
    public string Status { get; set; } = "pending";
    /// <summary>unpaid | paid</summary>
    public string PaymentStatus { get; set; } = "unpaid";
    /// <summary>cash | online</summary>
    public string PaymentMethod { get; set; } = PaymentMethods.Online;
    public bool IsCommissionPaid { get; set; }
    public int TotalPrice { get; set; }
    public int DiscountAmount { get; set; }
    public bool IsDiscountApplied { get; set; }
    public string? ReferenceCode { get; set; }
    public int CancellationPenaltyIqd { get; set; }
    public int CancellationOwnerShareIqd { get; set; }
    public int CancellationPlatformShareIqd { get; set; }
    public DateTime? CancelledAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
    public Field? Field { get; set; }
}
