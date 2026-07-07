namespace Riyada.Domain.Entities;

public class OwnerFeeInvoice
{
    public int Id { get; set; }
    public int OwnerId { get; set; }
    public int Amount { get; set; }
    public int TotalHours { get; set; }
    /// <summary>pending | paid | cancelled</summary>
    public string Status { get; set; } = "pending";
    public string Title { get; set; } = "عمولة المنصة";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? PaidAt { get; set; }

    public User? Owner { get; set; }
    public ICollection<OwnerFeeInvoiceItem> Items { get; set; } = new List<OwnerFeeInvoiceItem>();
    public ICollection<PlatformPayment> Payments { get; set; } = new List<PlatformPayment>();
}
