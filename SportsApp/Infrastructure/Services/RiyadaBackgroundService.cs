using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Riyada.Application.Common;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Riyada.Application.Abstractions;
using Riyada.Application.DTOs;
using Riyada.Infrastructure.Data;
using Riyada.Infrastructure.Extensions;

namespace Riyada.Infrastructure.Services;

/// <summary>
/// مهام خلفية: أقفال الأوقات + pre-fetch + إكمال الحجوزات المنتهية.
/// </summary>
public sealed class RiyadaBackgroundService : BackgroundService
{
    private static readonly TimeSpan LockSweepInterval = TimeSpan.FromSeconds(15);
    private static readonly TimeSpan PrefetchInterval = TimeSpan.FromMinutes(2);
    private static readonly TimeSpan CompleteBookingsInterval = TimeSpan.FromMinutes(5);

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly SlotLockService _locks;
    private readonly FieldPrefetchCache _prefetchCache;
    private readonly ILogger<RiyadaBackgroundService> _logger;

    public RiyadaBackgroundService(
        IServiceScopeFactory scopeFactory,
        SlotLockService locks,
        FieldPrefetchCache prefetchCache,
        ILogger<RiyadaBackgroundService> logger)
    {
        _scopeFactory = scopeFactory;
        _locks = locks;
        _prefetchCache = prefetchCache;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var lockTimer = new PeriodicTimer(LockSweepInterval);
        using var prefetchTimer = new PeriodicTimer(PrefetchInterval);
        using var completeTimer = new PeriodicTimer(CompleteBookingsInterval);

        var lockTick = lockTimer.WaitForNextTickAsync(stoppingToken).AsTask();
        var prefetchTick = prefetchTimer.WaitForNextTickAsync(stoppingToken).AsTask();
        var completeTick = completeTimer.WaitForNextTickAsync(stoppingToken).AsTask();

        while (!stoppingToken.IsCancellationRequested)
        {
            var completed = await Task.WhenAny(lockTick, prefetchTick, completeTick);
            if (completed.IsCanceled) break;

            if (completed == lockTick)
            {
                await SweepExpiredLocksAsync(stoppingToken);
                lockTick = lockTimer.WaitForNextTickAsync(stoppingToken).AsTask();
            }
            else if (completed == prefetchTick)
            {
                await PrefetchPopularSchedulesAsync(stoppingToken);
                prefetchTick = prefetchTimer.WaitForNextTickAsync(stoppingToken).AsTask();
            }
            else
            {
                await CompleteExpiredBookingsAsync(stoppingToken);
                completeTick = completeTimer.WaitForNextTickAsync(stoppingToken).AsTask();
            }
        }
    }

    async Task SweepExpiredLocksAsync(CancellationToken ct)
    {
        var expired = _locks.PurgeExpiredAndCollect();
        if (expired.Count == 0) return;

        using var scope = _scopeFactory.CreateScope();
        var publisher = scope.ServiceProvider.GetService<IBookingRealtimePublisher>();
        if (publisher is null) return;

        foreach (var entry in expired)
        {
            try
            {
                await publisher.PublishSlotReleaseAsync(
                    entry.FieldId,
                    new SlotReleaseEvent(entry.FieldId, entry.StartTime, entry.Hours));
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to publish slot release for field {FieldId}", entry.FieldId);
            }
        }

        _logger.LogDebug("Released {Count} expired slot lock(s)", expired.Count);
    }

    async Task PrefetchPopularSchedulesAsync(CancellationToken ct)
    {
        var topIds = _prefetchCache.GetTopFieldIds(5);
        if (topIds.Count == 0) return;

        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        foreach (var fieldId in topIds)
        {
            if (ct.IsCancellationRequested) break;
            try
            {
                var exists = await db.Fields.AsReadOnly().AnyAsync(f => f.Id == fieldId && f.IsActive, ct);
                if (!exists) continue;

                var bookings = await db.Bookings.AsReadOnly()
                    .Where(b => b.FieldId == fieldId && b.Status != "cancelled" && b.Status != "rejected")
                    .Where(b => b.StartTime >= DateTime.Today && b.StartTime < DateTime.Today.AddDays(7))
                    .ToListAsync(ct);

                _ = BookingService.BuildWeekSchedule(fieldId, bookings, _locks);
                _logger.LogDebug("Pre-fetched schedule for field {FieldId}", fieldId);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Schedule pre-fetch failed for field {FieldId}", fieldId);
            }
        }
    }

    async Task CompleteExpiredBookingsAsync(CancellationToken ct)
    {
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var now = BookingClock.UtcNow;

        var expired = await db.Bookings
            .Where(b => b.Status == "approved" && (b.EndTime != default ? b.EndTime : b.StartTime.AddHours(b.Hours)) < now)
            .ToListAsync(ct);

        if (expired.Count == 0) return;

        foreach (var booking in expired)
            booking.Status = "completed";

        await db.SaveChangesAsync(ct);
        _logger.LogInformation("Marked {Count} booking(s) as completed", expired.Count);
    }
}
