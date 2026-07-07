using System.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Riyada.Application.Common;
using Riyada.Application.DTOs;
using Riyada.Domain.Entities;
using Riyada.Infrastructure.Data;

namespace Riyada.Infrastructure.Services;

public static class BookingService
{
    private static readonly string[] BlockingStatuses = ["pending", "approved"];

    public static bool IsValidHours(int hours) =>
        hours is >= FinancialRules.MinBookingHours and <= FinancialRules.MaxBookingHours;

    public static bool IsValidProvince(string province) =>
        province.Trim().Equals("نينوى", StringComparison.OrdinalIgnoreCase);

    public static DateTime EndTime(DateTime start, int hours) => start.AddHours(hours);

    public static int ResolveBasePrice(Field field) =>
        field.BasePrice > 0 ? field.BasePrice : field.PricePerHour;

    /// <summary>Dynamic hourly rate + optional 10% loyalty discount at 10 points.</summary>
    public static BookingPriceQuote CalculatePrice(int basePricePerHour, DateTime date, int hours, int loyaltyPoints = 0) =>
        FinancialRules.CalculateBookingPrice(basePricePerHour, date, hours, loyaltyPoints);

    public static async Task<BookingPriceQuote> CalculatePriceAsync(
        AppDbContext db, int fieldId, DateTime date, int hours, int loyaltyPoints, CancellationToken ct = default)
    {
        var field = await db.Fields.AsNoTracking().FirstOrDefaultAsync(f => f.Id == fieldId, ct)
            ?? throw new InvalidOperationException("الملعب غير موجود");
        return CalculatePrice(ResolveBasePrice(field), date, hours, loyaltyPoints);
    }

    public static void ApplyLoyaltyAfterApproval(User user, Booking booking)
    {
        if (booking.IsDiscountApplied)
            user.LoyaltyPoints = 0;
        else
            user.LoyaltyPoints += 1;
    }

    public static bool IntervalsOverlap(DateTime start, DateTime end, DateTime otherStart, DateTime otherEnd) =>
        start < otherEnd && end > otherStart;

    public static bool IsWithinOperatingHours(DateTime start, int hours)
    {
        var localStart = BookingClock.ToFieldLocal(start);
        if (localStart.Hour < FinancialRules.OpenHour) return false;
        if (localStart.Hour >= FinancialRules.CloseHour) return false;
        var end = EndTime(localStart, hours);
        var midnight = localStart.Date.AddDays(1);
        return end <= midnight;
    }

    /// <summary>يمكن الإلغاء قبل موعد الحجز لحجوزات pending/approved.</summary>
    public static bool CanCancelBooking(string status, DateTime startTime) =>
        BlockingStatuses.Contains(status) && BookingClock.ToUtc(startTime) > BookingClock.UtcNow;

    public static CancellationOutcome EvaluateCancellation(DateTime startTime) =>
        CancellationRules.Evaluate(startTime);

    public static async Task<(bool Ok, string? Error, CancellationOutcome? Outcome, CancellationPushKind PushKind)> TryCancelBookingAsync(
        AppDbContext db,
        WalletService wallets,
        Booking booking,
        User user,
        CancellationToken ct = default)
    {
        if (!CanCancelBooking(booking.Status, booking.StartTime))
            return (false, "لا يمكن الإلغاء", null, CancellationPushKind.None);

        if (CancellationAbuseRules.IsBanned(user))
            return (false, CancellationAbuseRules.BanErrorMessage, null, CancellationPushKind.None);

        var outcome = EvaluateCancellation(booking.StartTime);
        if (outcome.Tier == CancellationTier.NotAllowed)
            return (false, "لا يمكن الإلغاء", null, CancellationPushKind.None);

        await using var tx = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable, ct);
        try
        {
            int? priorCancelledCount = null;
            if (!CancellationAbuseRules.IsExempt(user))
            {
                priorCancelledCount = await CountRecentCancellationsAsync(db, user.Id, booking.Id, ct);

                if (priorCancelledCount >= CancellationAbuseRules.MaxCancellationsPer24Hours - 1)
                {
                    user.AccountStatus = UserAccountStatuses.Banned;
                    db.SecurityLogs.Add(new SecurityLog
                    {
                        UserId = user.Id,
                        EventType = SecurityLogEventTypes.AccountBanned,
                        Reason = CancellationAbuseRules.BanReason,
                        Details =
                            $"Prior cancellations in 24h: {priorCancelledCount}; blocked booking #{booking.Id}",
                        CreatedAt = DateTime.UtcNow
                    });
                    await db.SaveChangesAsync(ct);
                    await tx.CommitAsync(ct);
                    return (false, CancellationAbuseRules.BanErrorMessage, null, CancellationPushKind.AccountRestricted);
                }
            }

            booking.Status = "cancelled";
            booking.CancelledAt = DateTime.UtcNow;

            if (outcome.Tier == CancellationTier.LatePenalty)
            {
                booking.CancellationPenaltyIqd = outcome.PenaltyIqd;
                booking.CancellationOwnerShareIqd = outcome.OwnerShareIqd;
                booking.CancellationPlatformShareIqd = outcome.PlatformShareIqd;
                user.OutstandingPenaltyIqd += outcome.PenaltyIqd;

                if (booking.Field is not null)
                {
                    var (creditOk, creditErr) = await wallets.CreditCancellationShareAsync(
                        db,
                        booking.Field.OwnerId,
                        outcome.OwnerShareIqd,
                        booking.Id,
                        booking.ReferenceCode,
                        tx,
                        ct);
                    if (!creditOk)
                    {
                        await tx.RollbackAsync(ct);
                        return (false, creditErr ?? "تعذّر تسجيل حصة المالك", null, CancellationPushKind.None);
                    }
                }
            }

            var pushKind = priorCancelledCount == CancellationAbuseRules.WarningCancellationCount - 1
                ? CancellationPushKind.AbuseWarning
                : CancellationPushKind.None;

            if (pushKind == CancellationPushKind.AbuseWarning)
            {
                db.Notifications.Add(new Notification
                {
                    UserId = user.Id,
                    Title = CancellationAbuseRules.WarningTitle,
                    Message = CancellationAbuseRules.WarningMessage,
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow
                });
            }

            await db.SaveChangesAsync(ct);
            await tx.CommitAsync(ct);
            return (true, null, outcome, pushKind);
        }
        catch
        {
            await tx.RollbackAsync(ct);
            throw;
        }
    }

    private static Task<int> CountRecentCancellationsAsync(
        AppDbContext db, int userId, int excludeBookingId, CancellationToken ct)
    {
        var windowStart = DateTime.UtcNow.AddHours(-24);
        return db.Bookings.CountAsync(b =>
            b.UserId == userId &&
            b.Id != excludeBookingId &&
            b.Status == "cancelled" &&
            b.CancelledAt != null &&
            b.CancelledAt >= windowStart, ct);
    }

    public static double RemainingHours(DateTime startTime, DateTime endTime)
    {
        var now = BookingClock.UtcNow;
        var start = BookingClock.ToUtc(startTime);
        var end = BookingClock.ToUtc(endTime);
        if (now >= end) return 0;
        if (now <= start) return (end - start).TotalHours;
        return (end - now).TotalHours;
    }

    public static (int Total, int Commission, int Net) CalculateOwnerFinancials(IEnumerable<Booking> approved)
    {
        var list = approved.ToList();
        var total = list.Sum(b => b.TotalPrice);
        var commission = list.Sum(b => FinancialRules.CalculateCommissionFromTotal(b.TotalPrice));
        return (total, commission, total - commission);
    }

    public static async Task<bool> HasFieldConflictAsync(
        AppDbContext db, int fieldId, DateTime start, DateTime end, int? excludeId = null)
    {
        return await db.Bookings
            .Where(b => b.FieldId == fieldId && (b.Status == "pending" || b.Status == "approved"))
            .Where(b => !excludeId.HasValue || b.Id != excludeId.Value)
            .Where(b => b.StartTime < end &&
                (b.EndTime != default ? b.EndTime > start : b.StartTime.AddHours(b.Hours) > start))
            .AnyAsync();
    }

    public static async Task<(Booking? Booking, string? Error, string? ErrorCode)> TryCreateBookingWithLockAsync(
        AppDbContext db,
        SlotLockService locks,
        int userId,
        int fieldId,
        DateTime startTime,
        int hours,
        int basePricePerHour,
        int loyaltyPoints,
        string paymentMethod = PaymentMethods.Online)
    {
        if (!IsValidHours(hours)) return (null, "الحد الأقصى: ساعتان", null);
        if (BookingClock.ToUtc(startTime) <= BookingClock.UtcNow)
            return (null, "لا يمكن الحجز في وقت ماضٍ", null);
        if (!IsWithinOperatingHours(startTime, hours))
            return (null, $"أوقات العمل {FinancialRules.OpenHour}:00 - {FinancialRules.CloseHour}:00", null);

        if (!locks.IsHeldBy(fieldId, startTime, hours, userId))
            return (null, "الوقت لم يعد محجوزاً لك", "ConflictError");

        var recentlyTaken = await db.Bookings.AnyAsync(b =>
            b.FieldId == fieldId &&
            b.StartTime == startTime &&
            b.Hours == hours &&
            b.UserId != userId &&
            (b.Status == "pending" || b.Status == "approved") &&
            b.CreatedAt >= DateTime.UtcNow.AddSeconds(-30));
        if (recentlyTaken)
            return (null, "الملعب تم حجزه للتو", "ConflictError");

        var end = EndTime(startTime, hours);
        await using var tx = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        try
        {
            if (await HasFieldConflictAsync(db, fieldId, startTime, end))
            {
                await tx.RollbackAsync();
                return (null, "هذا الوقت محجوز مسبقاً", "ConflictError");
            }

            var method = PaymentMethods.Normalize(paymentMethod);
            var quote = CalculatePrice(basePricePerHour, startTime, hours, loyaltyPoints);
            var booking = new Booking
            {
                UserId = userId,
                FieldId = fieldId,
                StartTime = startTime,
                EndTime = end,
                Hours = hours,
                Status = "pending",
                TotalPrice = quote.TotalPrice,
                DiscountAmount = quote.DiscountAmount,
                IsDiscountApplied = quote.IsDiscountApplied,
                PaymentMethod = method,
                PaymentStatus = method == PaymentMethods.Cash ? "paid" : "unpaid",
                IsCommissionPaid = false
            };
            db.Bookings.Add(booking);
            await db.SaveChangesAsync();
            booking.ReferenceCode = GenerateReferenceCode(booking.Id);
            await db.SaveChangesAsync();
            await tx.CommitAsync();
            locks.ForceRelease(fieldId, startTime, hours);
            return (booking, null, null);
        }
        catch (DbUpdateException)
        {
            await tx.RollbackAsync();
            return (null, "هذا الوقت محجوز مسبقاً", "ConflictError");
        }
        catch (Exception ex) when (IsConcurrencyConflict(ex))
        {
            await tx.RollbackAsync();
            return (null, "هذا الوقت محجوز مسبقاً", "ConflictError");
        }
        catch
        {
            await tx.RollbackAsync();
            throw;
        }
    }

    public static async Task<(Booking? Booking, string? Error)> TryCreateBookingAsync(
        AppDbContext db, int userId, int fieldId, DateTime startTime, int hours, int basePricePerHour,
        int loyaltyPoints = 0,
        string paymentMethod = PaymentMethods.Online)
    {
        if (!IsValidHours(hours)) return (null, "الحد الأقصى: ساعتان");
        if (BookingClock.ToUtc(startTime) <= BookingClock.UtcNow)
            return (null, "لا يمكن الحجز في وقت ماضٍ");
        if (!IsWithinOperatingHours(startTime, hours))
            return (null, $"أوقات العمل {FinancialRules.OpenHour}:00 - {FinancialRules.CloseHour}:00");

        var end = EndTime(startTime, hours);
        await using var tx = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        try
        {
            if (await HasFieldConflictAsync(db, fieldId, startTime, end))
            {
                await tx.RollbackAsync();
                return (null, "هذا الوقت محجوز مسبقاً");
            }

            var method = PaymentMethods.Normalize(paymentMethod);
            var quote = CalculatePrice(basePricePerHour, startTime, hours, loyaltyPoints);
            var booking = new Booking
            {
                UserId = userId,
                FieldId = fieldId,
                StartTime = startTime,
                EndTime = end,
                Hours = hours,
                Status = "pending",
                TotalPrice = quote.TotalPrice,
                DiscountAmount = quote.DiscountAmount,
                IsDiscountApplied = quote.IsDiscountApplied,
                PaymentMethod = method,
                PaymentStatus = method == PaymentMethods.Cash ? "paid" : "unpaid",
                IsCommissionPaid = false
            };
            db.Bookings.Add(booking);
            await db.SaveChangesAsync();
            booking.ReferenceCode = GenerateReferenceCode(booking.Id);
            await db.SaveChangesAsync();
            await tx.CommitAsync();
            return (booking, null);
        }
        catch (DbUpdateException)
        {
            await tx.RollbackAsync();
            return (null, "هذا الوقت محجوز مسبقاً");
        }
        catch (Exception ex) when (IsConcurrencyConflict(ex))
        {
            await tx.RollbackAsync();
            return (null, "هذا الوقت محجوز مسبقاً");
        }
        catch
        {
            await tx.RollbackAsync();
            throw;
        }
    }

    public static async Task<(bool Ok, string? Error, bool Changed)> TryApproveBookingAsync(
        AppDbContext db,
        Booking booking,
        CommissionService commission,
        int ownerId)
    {
        var status = (booking.Status ?? string.Empty).Trim().ToLowerInvariant();
        if (status == "approved") return (true, null, false);
        if (status != "pending") return (false, "لا يمكن الموافقة على هذا الحجز", false);
        if (booking.PaymentStatus != "paid")
            return (false, "لم يُدفع الحجز بعد — انتظر دفع اللاعب", false);

        var end = booking.EndTime != default ? booking.EndTime : EndTime(booking.StartTime, booking.Hours);

        await using var tx = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        try
        {
            var tracked = await db.Bookings.FirstAsync(b => b.Id == booking.Id);
            var trackedStatus = (tracked.Status ?? string.Empty).Trim().ToLowerInvariant();
            if (trackedStatus != "pending")
            {
                await tx.RollbackAsync();
                return trackedStatus == "approved" ? (true, null, false) : (false, "لا يمكن الموافقة على هذا الحجز", false);
            }

            if (await HasFieldConflictAsync(db, tracked.FieldId, tracked.StartTime, end, tracked.Id))
            {
                await tx.RollbackAsync();
                return (false, "تعارض مع حجز آخر في نفس الوقت", false);
            }

            var method = PaymentMethods.Normalize(tracked.PaymentMethod);
            if (method == PaymentMethods.Cash)
            {
                var commissionIqd = FinancialRules.CalculateCommissionFromTotal(tracked.TotalPrice);
                var wallet = await db.Wallets.FirstOrDefaultAsync(w => w.OwnerId == ownerId);
                var balance = wallet?.Balance ?? 0;
                if (balance < commissionIqd)
                    throw new InsufficientFundsException(commissionIqd, balance);
            }

            tracked.Status = "approved";

            var bookingUser = await db.Users.FirstAsync(u => u.Id == tracked.UserId);
            ApplyLoyaltyAfterApproval(bookingUser, tracked);

            var (commissionOk, commissionErr) = await commission.ProcessOnApprovalAsync(db, tracked, ownerId, tx);
            if (!commissionOk)
            {
                await tx.RollbackAsync();
                return (false, commissionErr ?? "تعذّر خصم العمولة من المحفظة", false);
            }

            await db.SaveChangesAsync();
            await tx.CommitAsync();
            booking.Status = "approved";
            return (true, null, true);
        }
        catch
        {
            await tx.RollbackAsync();
            throw;
        }
    }

    public static List<DayScheduleDto> BuildWeekSchedule(
        int fieldId,
        List<Booking> bookings,
        SlotLockService? locks = null)
    {
        var active = bookings.Where(b => b.FieldId == fieldId && BlockingStatuses.Contains(b.Status)).ToList();
        var schedule = new List<DayScheduleDto>();
        var today = BookingClock.FieldToday;
        for (var day = 0; day < 7; day++)
        {
            var date = today.AddDays(day);
            var slots = new List<TimeSlotDto>();
            for (var hour = FinancialRules.OpenHour; hour < FinancialRules.CloseHour; hour++)
            {
                var start = date.AddHours(hour);
                if (BookingClock.ToUtc(start) <= BookingClock.UtcNow) continue;
                foreach (var dur in new[] { 1, 2 })
                {
                    if (!IsWithinOperatingHours(start, dur)) continue;
                    var end = EndTime(start, dur);
                    var conflict = active.Any(b =>
                    {
                        var be = b.EndTime != default ? b.EndTime : EndTime(b.StartTime, b.Hours);
                        return IntervalsOverlap(start, end, b.StartTime, be);
                    });
                    if (conflict)
                    {
                        slots.Add(new TimeSlotDto(start, end, false, "booked"));
                        continue;
                    }

                    var held = locks?.Get(fieldId, start, dur);
                    if (held is not null)
                    {
                        slots.Add(new TimeSlotDto(start, end, false, "held", held.ExpiresAt));
                        continue;
                    }

                    slots.Add(new TimeSlotDto(start, end, true, null));
                }
            }
            schedule.Add(new DayScheduleDto(date, slots));
        }
        return schedule;
    }

    public static string GenerateReferenceCode(int bookingId) =>
        $"RY-{BookingClock.UtcNow:yyyyMMdd}-{bookingId:D4}";

    private static bool IsConcurrencyConflict(Exception ex) =>
        ex.Message.Contains("database is locked", StringComparison.OrdinalIgnoreCase) ||
        ex.Message.Contains("serialization", StringComparison.OrdinalIgnoreCase);

    public static async Task NotifyAsync(AppDbContext db, int userId, string title, string message)
    {
        db.Notifications.Add(new Notification
        {
            UserId = userId, Title = title, Message = message,
            IsRead = false, CreatedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync();
    }

    public static void QueueNotifyOwner(
        IServiceScopeFactory scopeFactory,
        int ownerId,
        string title,
        string message,
        string eventType)
    {
        _ = Task.Run(async () =>
        {
            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var notifications = scope.ServiceProvider.GetRequiredService<NotificationService>();
                await notifications.NotifyOwnerAsync(ownerId, title, message, eventType);
            }
            catch
            {
                // Push is best-effort — must not break booking flow
            }
        });
    }

    public static void QueueNotifyUser(
        IServiceScopeFactory scopeFactory,
        int userId,
        string title,
        string message,
        string eventType)
    {
        _ = Task.Run(async () =>
        {
            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var notifications = scope.ServiceProvider.GetRequiredService<NotificationService>();
                await notifications.NotifyUserAsync(userId, title, message, eventType);
            }
            catch
            {
                // Push is best-effort — must not break booking flow
            }
        });
    }

}
