namespace Riyada.Application.DTOs;

public record UserStatsDto(int UpcomingBookings, int PendingBookings, int UnreadNotifications, int TotalHoursBooked);

public record ApiInfoDto(string Name, string Version, string Status, bool DatabaseOk, DateTime ServerTime);
