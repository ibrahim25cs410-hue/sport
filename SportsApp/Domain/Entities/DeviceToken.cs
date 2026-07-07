namespace Riyada.Domain.Entities;

/// <summary>FCM device token registered for push delivery.</summary>
public class DeviceToken
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string Token { get; set; } = string.Empty;
    public string? Platform { get; set; }
    public DateTime LastUpdated { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
}
