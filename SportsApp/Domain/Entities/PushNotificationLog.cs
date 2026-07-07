namespace Riyada.Domain.Entities;

public class PushNotificationLog
{
    public int Id { get; set; }
    public int? UserId { get; set; }
    /// <summary>Masked token tail for debugging — never store full FCM tokens in logs.</summary>
    public string DeviceTokenPreview { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string EventType { get; set; } = string.Empty;
    public string Status { get; set; } = "pending";
    public string? ProviderMessageId { get; set; }
    public string? Error { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
}
