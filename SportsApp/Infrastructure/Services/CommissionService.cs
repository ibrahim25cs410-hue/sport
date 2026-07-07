using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using Riyada.Application.Common;
using Riyada.Domain.Entities;
using Riyada.Infrastructure.Data;

namespace Riyada.Infrastructure.Services;

public class CommissionService
{
    private readonly WalletService _wallets;

    public CommissionService(WalletService wallets) => _wallets = wallets;

    /// <summary>
    /// Processes platform commission when an owner confirms a booking.
    /// Cash bookings debit the owner wallet; online bookings mark commission as settled.
    /// </summary>
    public async Task<(bool Ok, string? Error)> ProcessOnApprovalAsync(
        AppDbContext db,
        Booking booking,
        int ownerId,
        IDbContextTransaction tx,
        CancellationToken ct = default)
    {
        if (booking.IsCommissionPaid) return (true, null);

        var method = PaymentMethods.Normalize(booking.PaymentMethod);

        if (method == PaymentMethods.Online)
        {
            booking.IsCommissionPaid = true;
            await db.SaveChangesAsync(ct);
            return (true, null);
        }

        var commission = FinancialRules.CalculateCommissionFromTotal(booking.TotalPrice);
        var (ok, err) = await _wallets.DeductCommissionAsync(
            db, ownerId, booking.Id, commission, booking.ReferenceCode, tx, ct);
        if (!ok) return (false, err);

        booking.IsCommissionPaid = true;
        await db.SaveChangesAsync(ct);
        return (true, null);
    }
}
