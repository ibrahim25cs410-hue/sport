namespace Riyada.Application.DTOs;

public record TimeSlotDto(
    DateTime StartTime,
    DateTime EndTime,
    bool IsAvailable,
    string? Status,
    DateTime? HeldUntil = null);

public record DayScheduleDto(DateTime Date, List<TimeSlotDto> Slots);

public record ActiveBookingDto(
    int Id, string? ReferenceCode, string FieldName, string FieldPhone, string? FieldImage, string FieldAddress,
    DateTime StartTime, DateTime EndTime, int Hours, int TotalPrice, string Status, string PaymentStatus,
    double RemainingHours, bool CanCancel);

public record OwnerBookingDto(
    int Id, string? ReferenceCode, string UserName, string UserPhone, string UserEmail,
    DateTime StartTime, int Hours, int TotalPrice, string Status);

public record OwnerDashboardDto(
    FieldDto Field, List<OwnerBookingDto> Bookings,
    int TotalRevenue, int AppCommission, int NetRevenue, int PendingCount,
    int? BookingsPage = null, int? BookingsLimit = null, int? BookingsTotalCount = null, bool? BookingsHasNextPage = null);

public record NotificationDto(int Id, int UserId, string Title, string Message, bool IsRead, DateTime CreatedAt);
