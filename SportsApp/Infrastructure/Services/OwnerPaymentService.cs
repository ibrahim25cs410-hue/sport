using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Riyada.Application.Abstractions;
using Riyada.Application.Common;
using Riyada.Application.DTOs;
using Riyada.Domain.Entities;
using Riyada.Infrastructure.Data;

namespace Riyada.Infrastructure.Services;

public class OwnerPaymentService
{
    private readonly AppDbContext _db;
    private readonly IPaymentGatewayVerifierRouter _gatewayRouter;
    private readonly ILogger<OwnerPaymentService> _logger;

    public OwnerPaymentService(
        AppDbContext db,
        IPaymentGatewayVerifierRouter gatewayRouter,
        ILogger<OwnerPaymentService> logger)
    {
        _db = db;
        _gatewayRouter = gatewayRouter;
        _logger = logger;
    }

    public async Task<OwnerPaymentAccountDto> GetAccountAsync(int ownerId)
    {
        await SyncPendingInvoiceAsync(ownerId);
        var pending = await LoadInvoicesAsync(ownerId, "pending");
        var paid = await LoadInvoicesAsync(ownerId, "paid");
        var payments = await _db.PlatformPayments.AsNoTracking()
            .Where(p => p.OwnerId == ownerId)
            .OrderByDescending(p => p.CreatedAt)
            .Take(20)
            .Select(p => new OwnerPaymentHistoryDto(
                p.Id, p.InvoiceId, p.Amount, p.Gateway, p.Status, p.CreatedAt, p.VerifiedAt))
            .ToListAsync();

        var outstanding = pending.Sum(i => i.Amount);
        var outstandingHours = pending.Sum(i => i.TotalHours);
        var totalPaid = paid.Sum(i => i.Amount);

        return new OwnerPaymentAccountDto(
            outstanding, outstandingHours, totalPaid, pending, paid, payments);
    }

    public async Task<(InitiatePaymentResponse? Result, string? Error)> InitiateAsync(
        int ownerId, int invoiceId, string gateway)
    {
        gateway = gateway.Trim().ToLowerInvariant();
        if (gateway is not ("zaincash" or "card"))
            return (null, "بوابة دفع غير مدعومة");

        await SyncPendingInvoiceAsync(ownerId);
        var invoice = await _db.OwnerFeeInvoices
            .FirstOrDefaultAsync(i => i.Id == invoiceId && i.OwnerId == ownerId);
        if (invoice is null) return (null, "الفاتورة غير موجودة");
        if (invoice.Status != "pending") return (null, "الفاتورة مدفوعة أو مغلقة");
        if (invoice.Amount <= 0) return (null, "لا يوجد مبلغ مستحق");

        // منع تعدد جلسات دفع نشطة لنفس الفاتورة.
        var hasActive = await _db.PlatformPayments.AnyAsync(p =>
            p.InvoiceId == invoice.Id && p.Status == "initiated" && p.CreatedAt > DateTime.UtcNow.AddMinutes(-30));
        if (hasActive)
            return (null, "توجد عملية دفع قيد المعالجة — أكملها أو انتظر");

        var token = $"TXN-{Guid.NewGuid():N}";
        var providerRef = gateway == "zaincash" ? $"ZC-{Guid.NewGuid():N}"[..20] : $"CARD-{Guid.NewGuid():N}"[..20];
        var payment = new PlatformPayment
        {
            InvoiceId = invoice.Id,
            OwnerId = ownerId,
            Amount = invoice.Amount,
            Gateway = gateway,
            TransactionToken = token,
            ProviderReference = providerRef,
            Status = "initiated",
            CreatedAt = DateTime.UtcNow
        };
        _db.PlatformPayments.Add(payment);
        await _db.SaveChangesAsync();

        var checkoutUrl = gateway == "zaincash"
            ? $"https://checkout.zaincash.iq/pay?token={token}"
            : $"https://checkout.riyada.iq/card?token={token}";

        return (new InitiatePaymentResponse(token, gateway, invoice.Amount, checkoutUrl), null);
    }

    /// <summary>
    /// يتحقق حصراً عبر بوابة الدفع (server-to-server) — لا يُقبل تأكيد من التطبيق وحده.
    /// </summary>
    public async Task<(VerifyPaymentResponse? Result, string? Error)> VerifyAsync(int ownerId, string transactionToken)
    {
        transactionToken = transactionToken.Trim();
        if (string.IsNullOrEmpty(transactionToken))
            return (null, "رمز المعاملة مطلوب");

        await using var tx = await _db.Database.BeginTransactionAsync();
        try
        {
            var payment = await _db.PlatformPayments
                .Include(p => p.Invoice)
                .ThenInclude(i => i!.Items)
                .FirstOrDefaultAsync(p => p.TransactionToken == transactionToken && p.OwnerId == ownerId);
            if (payment is null) return (null, "معاملة غير موجودة");

            // Idempotency: إعادة نفس الطلب تُرجع النتيجة دون إعادة الخصم.
            if (payment.Status == "verified")
            {
                await tx.CommitAsync();
                var account = await GetAccountAsync(ownerId);
                return (new VerifyPaymentResponse(true, "paid", payment.InvoiceId, account.OutstandingAmount, "تم الدفع مسبقاً"), null);
            }
            if (payment.Status == "failed")
                return (null, "فشلت عملية الدفع");

            if (payment.Invoice?.Status == "paid")
            {
                payment.Status = "failed";
                await _db.SaveChangesAsync();
                await tx.CommitAsync();
                return (null, "الفاتورة مدفوعة مسبقاً");
            }

            var verifier = _gatewayRouter.Resolve(payment.Gateway);
            var gatewayResult = await verifier.VerifyTransactionAsync(
                payment.TransactionToken,
                payment.ProviderReference,
                payment.Amount);

            if (!gatewayResult.Success)
            {
                _logger.LogWarning(
                    "Gateway rejected payment {Token}: {Reason}",
                    payment.TransactionToken[..Math.Min(12, payment.TransactionToken.Length)],
                    gatewayResult.FailureReason);
                payment.Status = "failed";
                await _db.SaveChangesAsync();
                await tx.CommitAsync();
                return (null, "تعذّر التحقق من الدفع مع بوابة الدفع");
            }

            // Idempotency: منع استخدام نفس معرّف بوابة الدفع مرتين.
            var gatewayTxnId = gatewayResult.GatewayTransactionId!;
            var duplicate = await _db.PlatformPayments.AnyAsync(p =>
                p.GatewayTransactionId == gatewayTxnId && p.Id != payment.Id);
            if (duplicate)
            {
                payment.Status = "failed";
                await _db.SaveChangesAsync();
                await tx.CommitAsync();
                _logger.LogWarning("Duplicate gateway transaction id {GatewayTxnId}", gatewayTxnId);
                return (null, "معاملة مكررة — تم رفضها");
            }

            payment.GatewayTransactionId = gatewayTxnId;
            payment.Status = "verified";
            payment.VerifiedAt = DateTime.UtcNow;
            if (payment.Invoice is not null)
            {
                payment.Invoice.Status = "paid";
                payment.Invoice.PaidAt = DateTime.UtcNow;
            }
            await _db.SaveChangesAsync();
            await tx.CommitAsync();

            var updated = await GetAccountAsync(ownerId);
            return (new VerifyPaymentResponse(
                true, "paid", payment.InvoiceId, updated.OutstandingAmount, "تم الدفع بنجاح"), null);
        }
        catch
        {
            await tx.RollbackAsync();
            throw;
        }
    }

    async Task SyncPendingInvoiceAsync(int ownerId)
    {
        var fieldIds = await _db.Fields.AsNoTracking()
            .Where(f => f.OwnerId == ownerId)
            .Select(f => f.Id)
            .ToListAsync();
        if (fieldIds.Count == 0) return;

        var invoicedBookingIds = await _db.OwnerFeeInvoiceItems.AsNoTracking()
            .Where(i => i.Invoice!.OwnerId == ownerId && i.Invoice.Status != "cancelled")
            .Select(i => i.BookingId)
            .ToListAsync();

        var unsettled = await _db.Bookings.AsNoTracking()
            .Where(b => fieldIds.Contains(b.FieldId) && b.Status == "approved" && !invoicedBookingIds.Contains(b.Id))
            .OrderBy(b => b.StartTime)
            .ToListAsync();

        if (unsettled.Count == 0) return;

        var pending = await _db.OwnerFeeInvoices
            .Include(i => i.Items)
            .FirstOrDefaultAsync(i => i.OwnerId == ownerId && i.Status == "pending");

        if (pending is null)
        {
            pending = new OwnerFeeInvoice
            {
                OwnerId = ownerId,
                Status = "pending",
                Title = "عمولة المنصة المستحقة",
                CreatedAt = DateTime.UtcNow
            };
            _db.OwnerFeeInvoices.Add(pending);
        }

        foreach (var booking in unsettled)
        {
            pending.Items.Add(new OwnerFeeInvoiceItem { BookingId = booking.Id });
        }

        var bookingIds = pending.Items.Select(i => i.BookingId).ToList();
        var allBookings = await _db.Bookings.AsNoTracking()
            .Where(b => bookingIds.Contains(b.Id))
            .ToListAsync();
        RecalculateInvoice(pending, allBookings);

        await _db.SaveChangesAsync();
    }

    static void RecalculateInvoice(OwnerFeeInvoice invoice, List<Booking> bookings)
    {
        invoice.TotalHours = bookings.Sum(b => b.Hours);
        invoice.Amount = bookings.Sum(b => FinancialRules.CalculateCommissionFromTotal(b.TotalPrice));
    }

    async Task<List<OwnerFeeInvoiceDto>> LoadInvoicesAsync(int ownerId, string status)
    {
        var invoices = await _db.OwnerFeeInvoices.AsNoTracking()
            .Include(i => i.Items)
            .Where(i => i.OwnerId == ownerId && i.Status == status)
            .OrderByDescending(i => status == "paid" ? i.PaidAt : i.CreatedAt)
            .ToListAsync();

        return invoices.Select(i => new OwnerFeeInvoiceDto(
            i.Id, i.Amount, i.TotalHours, i.Status, i.Title, i.CreatedAt, i.PaidAt, i.Items.Count)).ToList();
    }
}
