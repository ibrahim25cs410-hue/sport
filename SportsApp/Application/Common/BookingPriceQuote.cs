namespace Riyada.Application.Common;

/// <summary>Price breakdown for a booking before persistence.</summary>
public record BookingPriceQuote(
    int BasePricePerHour,
    int HourlyRate,
    int Hours,
    int Subtotal,
    int DiscountAmount,
    bool IsDiscountApplied,
    int TotalPrice);
