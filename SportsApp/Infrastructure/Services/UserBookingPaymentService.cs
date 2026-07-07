using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Riyada.Application.Abstractions;
using Riyada.Application.DTOs;
using Riyada.Domain.Entities;
using Riyada.Infrastructure.Data;

namespace Riyada.Infrastructure.Services;

public class UserBookingPaymentService
{
    private readonly AppDbContext _db;
    private readonly IPaymentGatewayVerifierRouter _gatewayRouter;
    private readonly ILogger<UserBookingPaymentService> _logger;

    public UserBookingPaymentService(
        AppDbContext db,
        IPaymentGatewayVerifierRouter gatewayRouter,
        ILogger<UserBookingPaymentService> logger)
    {
        _db = db;
        _gatewayRouter = gatewayRouter;
        _logger = logger;
    }

    public async Task<(InitiatePaymentResponse? Result, string? Error)> InitiateAsync(
        int userId, int bookingId, string gateway)
    {
        gateway = gateway.Trim().ToLowerInvariant();
        if (gateway is not ("zaincash" or "card"))
            return (null, "بوابة دفع غير مدعومة");

        var booking = await _db.Bookings
            .Include(b => b.Field)
            .FirstOrDefaultAsync(b => b.Id == bookingId && b.UserId == userId);
        if (booking is null) return (null, "الحجز غير موجود");
        if (booking.Status is not "pending")
            return (null, "لا يمكن الدفع لهذا الحجز");
        if (booking.PaymentStatus == "paid")
            return (null, "تم الدفع مسبقاً");
        if (booking.TotalPrice <= 0)
            return (null, "لا يوجد مبلغ مستحق");

        var hasActive = await _db.BookingPayments.AnyAsync(p =>
            p.BookingId == bookingId && p.Status == "initiated" && p.CreatedAt > DateTime.UtcNow.AddMinutes(-30));
        if (hasActive)
            return (null, "توجد عملية دفع قيد المعالجة");

        var token = $"BTXN-{Guid.NewGuid():N}";
        var providerRef = gateway == "zaincash" ? $"ZC-{Guid.NewGuid():N}"[..20] : $"CARD-{Guid.NewGuid():N}"[..20];
        var payment = new BookingPayment
        {
            BookingId = booking.Id,
            UserId = userId,
            Amount = booking.TotalPrice,
            Gateway = gateway,
            TransactionToken = token,
            ProviderReference = providerRef,
            Status = "initiated",
            CreatedAt = DateTime.UtcNow
        };
        _db.BookingPayments.Add(payment);
        await _db.SaveChangesAsync();

        var checkoutUrl = gateway == "zaincash"
            ? $"https://checkout.zaincash.iq/pay?token={token}"
            : $"https://checkout.riyada.iq/card?token={token}";

        return (new InitiatePaymentResponse(token, gateway, booking.TotalPrice, checkoutUrl), null);
    }

    public async Task<(VerifyPaymentResponse? Result, string? Error)> VerifyAsync(int userId, string transactionToken)
    {
        transactionToken = transactionToken.Trim();
        if (string.IsNullOrEmpty(transactionToken))
            return (null, "رمز المعاملة مطلوب");

        await using var tx = await _db.Database.BeginTransactionAsync();
        try
        {
            var payment = await _db.BookingPayments
                .Include(p => p.Booking)
                .FirstOrDefaultAsync(p => p.TransactionToken == transactionToken && p.UserId == userId);
            if (payment is null) return (null, "معاملة غير موجودة");

            if (payment.Status == "verified")
            {
                await tx.CommitAsync();
                return (new VerifyPaymentResponse(true, "paid", payment.BookingId, 0, "تم الدفع مسبقاً"), null);
            }
            if (payment.Status == "failed")
                return (null, "فشلت عملية الدفع");

            if (payment.Booking?.PaymentStatus == "paid")
            {
                payment.Status = "verified";
                payment.VerifiedAt = DateTime.UtcNow;
                await _db.SaveChangesAsync();
                await tx.CommitAsync();
                return (new VerifyPaymentResponse(true, "paid", payment.BookingId, 0, "تم الدفع"), null);
            }

            var verifier = _gatewayRouter.Resolve(payment.Gateway);
            var gatewayResult = await verifier.VerifyTransactionAsync(
                payment.TransactionToken,
                payment.ProviderReference,
                payment.Amount);

            if (!gatewayResult.Success)
            {
                payment.Status = "failed";
                await _db.SaveChangesAsync();
                await tx.CommitAsync();
                return (null, gatewayResult.FailureReason ?? "فشل التحقق من الدفع");
            }

            var gatewayTxnId = gatewayResult.GatewayTransactionId!;
            var duplicate = await _db.BookingPayments.AnyAsync(p =>
                p.GatewayTransactionId == gatewayTxnId && p.Id != payment.Id);
            if (duplicate)
            {
                payment.Status = "failed";
                await _db.SaveChangesAsync();
                await tx.CommitAsync();
                return (null, "معاملة مكررة");
            }

            payment.Status = "verified";
            payment.VerifiedAt = DateTime.UtcNow;
            payment.GatewayTransactionId = gatewayTxnId;
            if (payment.Booking is not null)
                payment.Booking.PaymentStatus = "paid";

            await _db.SaveChangesAsync();
            await tx.CommitAsync();
            _logger.LogInformation("Booking {BookingId} paid via {Gateway}", payment.BookingId, payment.Gateway);
            return (new VerifyPaymentResponse(true, "paid", payment.BookingId, 0, "تم الدفع بنجاح"), null);
        }
        catch
        {
            await tx.RollbackAsync();
            throw;
        }
    }
}
