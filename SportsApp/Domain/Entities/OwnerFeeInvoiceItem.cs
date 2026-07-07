namespace Riyada.Domain.Entities;

public class OwnerFeeInvoiceItem
{
    public int Id { get; set; }
    public int InvoiceId { get; set; }
    public int BookingId { get; set; }

    public OwnerFeeInvoice? Invoice { get; set; }
    public Booking? Booking { get; set; }
}
