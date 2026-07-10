namespace Riyada.Application.DTOs;

public record UserDto(int Id, string Name, string Email, string Phone, string Province, string? Image, string Role, int LoyaltyPoints = 0);

public record FieldDto(
    int Id, string Name, string Address, string Phone, string? Image, int PricePerHour, int OwnerId,
    double AverageRating = 0, int ReviewCount = 0, double? Latitude = null, double? Longitude = null);

public record LoginRequest(string Email, string Password);

public record RegisterUserRequest(string Name, string Email, string Phone, string Province, string? Image, string Password);

public record RegisterOwnerRequest(
    string Name, string Email, string Phone, string Password,
    string StadiumName, string StadiumAddress, string StadiumPhone,
    string? StadiumImage, int PricePerHour);

public record CreateBookingResponse(
    int Id,
    string? ReferenceCode,
    string Status,
    string PaymentStatus,
    string PaymentMethod,
    DateTime StartTime,
    int Hours,
    int TotalPrice,
    int DiscountAmount,
    bool IsDiscountApplied,
    int HourlyRate,
    int LoyaltyPoints);

public record CreateBookingRequest(int FieldId, DateTime StartTime, int Hours, string? PaymentMethod = null);

public record AdminWalletTopUpRequest(int OwnerId, int Amount, string? Note = null);

public record WalletStatusDto(int OwnerId, decimal Balance, string Status, string? Message);

public record WalletTransactionDto(
    int Id,
    int Amount,
    string Type,
    string TypeLabel,
    string Description,
    int? BookingId,
    string? BookingReference,
    string? AdminNote,
    DateTime CreatedAt);

public record WalletDetailDto(
    int WalletId,
    int OwnerId,
    decimal Balance,
    string Status,
    DateTime LastUpdated,
    IReadOnlyList<WalletTransactionDto> Transactions);

public record SelectSlotRequest(int FieldId, DateTime StartTime, int Hours);

public record ReleaseSlotRequest(int FieldId, DateTime StartTime, int Hours);

public record BookingActionRequest(int BookingId);

public record CancelBookingRequest(int BookingId);

public record CancelBookingResponse(
    string Message,
    string Tier,
    int PenaltyIqd,
    int OwnerShareIqd,
    int PlatformShareIqd);

public record UpdateProfileRequest(string Name, string Phone, string? Image, string? Password);

public record UpdateFieldRequest(string Name, string Address, string Phone, string? Image, int PricePerHour);

public record CreateFieldRequest(
    string Name,
    string Address,
    string Phone,
    string? Image,
    int PricePerHour,
    double? Latitude = null,
    double? Longitude = null);

public record UpdateDeviceTokenRequest(string Token, string? Platform = null);

public record InitiateBookingPaymentRequest(string Gateway);

public record AdminStatsDto(
    int TotalUsers,
    int TotalOwners,
    int TotalFields,
    int TotalBookings,
    int PaidBookings,
    int TotalRevenueIqd,
    int PlatformCommissionIqd);

public record AdminOwnerDto(int Id, string Name, string Email, string Phone, int FieldCount);

public record AdminFieldDto(int Id, string Name, string Address, int OwnerId, string OwnerName, bool IsActive);

public record AdminPendingBookingDto(
    int Id, string FieldName, string UserName, DateTime StartTime, int Hours, int TotalPrice, string Status);
