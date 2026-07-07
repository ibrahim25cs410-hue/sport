namespace Riyada.Application.DTOs;

public record OwnerFeeInvoiceDto(
    int Id,
    int Amount,
    int TotalHours,
    string Status,
    string Title,
    DateTime CreatedAt,
    DateTime? PaidAt,
    int BookingCount);

public record OwnerPaymentHistoryDto(
    int Id,
    int InvoiceId,
    int Amount,
    string Gateway,
    string Status,
    DateTime CreatedAt,
    DateTime? VerifiedAt);

public record OwnerPaymentAccountDto(
    int OutstandingAmount,
    int OutstandingHours,
    int TotalPaid,
    List<OwnerFeeInvoiceDto> PendingInvoices,
    List<OwnerFeeInvoiceDto> PaidInvoices,
    List<OwnerPaymentHistoryDto> RecentPayments);

public record InitiatePaymentRequest(int InvoiceId, string Gateway);

public record InitiatePaymentResponse(
    string TransactionToken,
    string Gateway,
    int Amount,
    string? CheckoutUrl);

public record VerifyPaymentRequest(string TransactionToken);

public record VerifyPaymentResponse(
    bool Success,
    string Status,
    int? InvoiceId,
    int OutstandingAmount,
    string Message);
