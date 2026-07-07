namespace Riyada.Domain.Entities;

public class User
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Province { get; set; } = "نينوى";
    public string? Image { get; set; }
    public string PasswordHash { get; set; } = string.Empty;
    public string Role { get; set; } = "user"; // user | owner | admin
    /// <summary>active | banned</summary>
    public string AccountStatus { get; set; } = "active";
    public int LoyaltyPoints { get; set; }
    public int OutstandingPenaltyIqd { get; set; }
    public string? FcmToken { get; set; }

    public ICollection<DeviceToken> DeviceTokens { get; set; } = [];
    public ICollection<Field> OwnedFields { get; set; } = [];
    public ICollection<Booking> Bookings { get; set; } = [];
    public ICollection<Notification> Notifications { get; set; } = [];
    public ICollection<Review> Reviews { get; set; } = [];
}
