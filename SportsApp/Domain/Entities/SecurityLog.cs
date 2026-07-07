namespace Riyada.Domain.Entities;

public class SecurityLog
{
    public int Id { get; set; }
    public int? UserId { get; set; }
    public string EventType { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
    public string? Details { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
}
