using System.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.DependencyInjection;
using Riyada.Application.Common;
using Riyada.Application.DTOs;
using Riyada.Domain.Entities;
using Riyada.Infrastructure.Data;

namespace Riyada.Infrastructure.Services;

public class WalletService
{
    private readonly IServiceScopeFactory _scopeFactory;

    public WalletService(IServiceScopeFactory scopeFactory) => _scopeFactory = scopeFactory;
    public async Task<Wallet> GetOrCreateAsync(AppDbContext db, int ownerId, CancellationToken ct = default)
    {
        var wallet = await db.Wallets.FirstOrDefaultAsync(w => w.OwnerId == ownerId, ct);
        if (wallet is not null) return wallet;

        wallet = new Wallet { OwnerId = ownerId, Balance = 0, LastUpdated = DateTime.UtcNow };
        db.Wallets.Add(wallet);
        await db.SaveChangesAsync(ct);
        return wallet;
    }

    public async Task<WalletStatusDto> GetStatusAsync(AppDbContext db, int ownerId, CancellationToken ct = default)
    {
        var wallet = await GetOrCreateAsync(db, ownerId, ct);
        var blocked = wallet.Balance <= 0;
        return new WalletStatusDto(
            ownerId,
            wallet.Balance,
            blocked ? "blocked" : "active",
            blocked ? "رصيد المحفظة غير كافٍ لاستقبال حجوزات جديدة" : null);
    }

    public async Task<bool> IsOwnerEligibleForBookingsAsync(AppDbContext db, int ownerId, CancellationToken ct = default)
    {
        var wallet = await db.Wallets.AsNoTracking().FirstOrDefaultAsync(w => w.OwnerId == ownerId, ct);
        if (wallet is null) return false;
        return wallet.Balance > 0;
    }

    public async Task<WalletDetailDto> GetDetailAsync(AppDbContext db, int ownerId, int take = 100, CancellationToken ct = default)
    {
        var wallet = await GetOrCreateAsync(db, ownerId, ct);
        var rows = await db.WalletTransactions.AsNoTracking()
            .Where(t => t.WalletId == wallet.Id)
            .OrderByDescending(t => t.CreatedAt)
            .Take(take)
            .Select(t => new
            {
                t.Id,
                t.Amount,
                t.Type,
                t.Description,
                t.AdminNote,
                t.BookingId,
                BookingReference = t.Booking != null ? t.Booking.ReferenceCode : null,
                t.CreatedAt
            })
            .ToListAsync(ct);

        var txs = rows.Select(t =>
        {
            var normalized = WalletTransactionTypes.Normalize(t.Type);
            var adminNote = t.AdminNote
                ?? (normalized == WalletTransactionTypes.AdminCredit ? t.Description : null);
            return new WalletTransactionDto(
                t.Id,
                t.Amount,
                normalized,
                WalletTransactionTypes.Label(t.Type),
                t.Description,
                t.BookingId,
                t.BookingReference,
                adminNote,
                t.CreatedAt);
        }).ToList();

        var status = wallet.Balance <= 0 ? "blocked" : "active";
        return new WalletDetailDto(wallet.Id, wallet.OwnerId, wallet.Balance, status, wallet.LastUpdated, txs);
    }

    public async Task<(bool Ok, string? Error)> AdminCreditAsync(
        AppDbContext db,
        int ownerId,
        int amountIqd,
        string? adminNote,
        CancellationToken ct = default)
    {
        var note = string.IsNullOrWhiteSpace(adminNote)
            ? "شحن يدوي من الإدارة"
            : adminNote.Trim();
        var description = $"شحن محفظة — {note}";
        return await CreditAsync(
            db, ownerId, amountIqd, WalletTransactionTypes.AdminCredit, description, note, null, null, ct);
    }

    private async Task<(bool Ok, string? Error)> CreditAsync(
        AppDbContext db,
        int ownerId,
        int amountIqd,
        string type,
        string description,
        string? adminNote,
        int? bookingId,
        IDbContextTransaction? existingTx,
        CancellationToken ct = default)
    {
        if (amountIqd <= 0) return (false, "المبلغ غير صالح");
        if (!WalletTransactionTypes.IsAllowedCreditType(type))
            return (false, "نوع المعاملة غير مسموح");

        var ownsTx = existingTx is null;
        await using var tx = ownsTx
            ? await db.Database.BeginTransactionAsync(IsolationLevel.Serializable, ct)
            : null;

        try
        {
            var wallet = await db.Wallets.FirstOrDefaultAsync(w => w.OwnerId == ownerId, ct)
                         ?? new Wallet { OwnerId = ownerId, Balance = 0, LastUpdated = DateTime.UtcNow };

            if (wallet.Id == 0) db.Wallets.Add(wallet);

            wallet.Balance += amountIqd;
            wallet.LastUpdated = DateTime.UtcNow;

            db.WalletTransactions.Add(new WalletTransaction
            {
                Wallet = wallet,
                Amount = amountIqd,
                Type = type,
                Description = description,
                AdminNote = WalletTransactionTypes.Normalize(type) == WalletTransactionTypes.AdminCredit
                    ? adminNote
                    : null,
                BookingId = bookingId,
                CreatedAt = DateTime.UtcNow
            });

            await db.SaveChangesAsync(ct);
            if (ownsTx) await tx!.CommitAsync(ct);
            return (true, null);
        }
        catch
        {
            if (ownsTx) await tx!.RollbackAsync(ct);
            throw;
        }
    }

    public async Task<(bool Ok, string? Error)> DeductCommissionAsync(
        AppDbContext db,
        int ownerId,
        int bookingId,
        int commissionIqd,
        string? bookingReference,
        IDbContextTransaction existingTx,
        CancellationToken ct = default)
    {
        if (commissionIqd <= 0) return (true, null);

        var wallet = await db.Wallets.FirstOrDefaultAsync(w => w.OwnerId == ownerId, ct);
        if (wallet is null)
        {
            wallet = new Wallet { OwnerId = ownerId, Balance = 0, LastUpdated = DateTime.UtcNow };
            db.Wallets.Add(wallet);
            await db.SaveChangesAsync(ct);
        }

        var refLabel = string.IsNullOrWhiteSpace(bookingReference)
            ? $"#{bookingId}"
            : bookingReference.Trim();

        var balanceBefore = wallet.Balance;
        if (balanceBefore < commissionIqd)
            throw new InsufficientFundsException(commissionIqd, balanceBefore);

        wallet.Balance -= commissionIqd;
        wallet.LastUpdated = DateTime.UtcNow;

        db.WalletTransactions.Add(new WalletTransaction
        {
            WalletId = wallet.Id,
            Amount = -commissionIqd,
            Type = WalletTransactionTypes.CommissionDebit,
            Description = $"عمولة منصة 10% — حجز نقدي {refLabel}",
            BookingId = bookingId,
            CreatedAt = DateTime.UtcNow
        });

        await db.SaveChangesAsync(ct);
        QueueLowBalanceAlertIfNeeded(ownerId, balanceBefore, wallet.Balance);
        return (true, null);
    }

    public async Task<(bool Ok, string? Error)> CreditCancellationShareAsync(
        AppDbContext db,
        int ownerId,
        int amountIqd,
        int bookingId,
        string? bookingReference,
        IDbContextTransaction existingTx,
        CancellationToken ct = default)
    {
        var refLabel = string.IsNullOrWhiteSpace(bookingReference)
            ? $"#{bookingId}"
            : bookingReference.Trim();
        var description = $"حصة إلغاء متأخر — حجز {refLabel}";
        return await CreditAsync(
            db,
            ownerId,
            amountIqd,
            WalletTransactionTypes.CancellationCredit,
            description,
            null,
            bookingId,
            existingTx,
            ct);
    }

    private void QueueLowBalanceAlertIfNeeded(int ownerId, decimal balanceBefore, decimal balanceAfter)
    {
        var threshold = FinancialRules.WalletLowBalanceAlertThresholdIqd;
        if (balanceBefore >= threshold && balanceAfter < threshold)
        {
            _ = Task.Run(async () =>
            {
                try
                {
                    await using var scope = _scopeFactory.CreateAsyncScope();
                    var notifications = scope.ServiceProvider.GetRequiredService<NotificationService>();
                    await notifications.NotifyOwnerAsync(
                        ownerId,
                        PushNotificationMessages.LowBalanceTitle,
                        PushNotificationMessages.LowBalanceBody,
                        PushNotificationEventTypes.WalletLowBalance);
                }
                catch
                {
                    // Best-effort alert
                }
            });
        }
    }
}
