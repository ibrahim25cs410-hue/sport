namespace Riyada.Domain.Entities;

/// <summary>
/// Sports field (ملعب). Domain convention: <see cref="Id"/> is referenced as fieldId in API/DTOs.
/// </summary>
public class Field
{
    public int Id { get; set; }
    public int OwnerId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string? Image { get; set; }
    public int PricePerHour { get; set; }
    /// <summary>Base hourly rate before peak-day surcharge.</summary>
    public int BasePrice { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? Owner { get; set; }
    public ICollection<Booking> Bookings { get; set; } = [];
    public ICollection<Review> Reviews { get; set; } = [];
}
