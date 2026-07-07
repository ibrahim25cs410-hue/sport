using System.Collections.Concurrent;

namespace Riyada.Infrastructure.Services;

/// <summary>قفل مؤقت للأوقات أثناء اختيار المستخدم (Temporary Lock Strategy).</summary>
public sealed class SlotLockService
{
    public static readonly TimeSpan DefaultTtl = TimeSpan.FromSeconds(60);
    private readonly ConcurrentDictionary<string, SlotLockEntry> _locks = new();

    private static string Key(int fieldId, DateTime startTime, int hours) =>
        $"{fieldId}:{startTime:O}:{hours}";

    public bool TryAcquire(int fieldId, DateTime startTime, int hours, int userId, TimeSpan? ttl = null)
    {
        PurgeExpired();
        var key = Key(fieldId, startTime, hours);
        var expires = DateTime.UtcNow.Add(ttl ?? DefaultTtl);

        if (_locks.TryGetValue(key, out var existing))
        {
            if (existing.ExpiresAt > DateTime.UtcNow && existing.UserId != userId)
                return false;
        }

        _locks[key] = new SlotLockEntry(fieldId, startTime, hours, userId, expires);
        return true;
    }

    public bool IsHeldBy(int fieldId, DateTime startTime, int hours, int userId)
    {
        PurgeExpired();
        var key = Key(fieldId, startTime, hours);
        return _locks.TryGetValue(key, out var entry)
               && entry.ExpiresAt > DateTime.UtcNow
               && entry.UserId == userId;
    }

    public bool IsHeldByOther(int fieldId, DateTime startTime, int hours, int userId)
    {
        PurgeExpired();
        var key = Key(fieldId, startTime, hours);
        return _locks.TryGetValue(key, out var entry)
               && entry.ExpiresAt > DateTime.UtcNow
               && entry.UserId != userId;
    }

    public void Release(int fieldId, DateTime startTime, int hours, int userId)
    {
        var key = Key(fieldId, startTime, hours);
        if (_locks.TryGetValue(key, out var entry) && entry.UserId == userId)
            _locks.TryRemove(key, out _);
    }

    public void ForceRelease(int fieldId, DateTime startTime, int hours) =>
        _locks.TryRemove(Key(fieldId, startTime, hours), out _);

    public SlotLockEntry? Get(int fieldId, DateTime startTime, int hours)
    {
        PurgeExpired();
        var key = Key(fieldId, startTime, hours);
        return _locks.TryGetValue(key, out var entry) ? entry : null;
    }

    private void PurgeExpired() => PurgeExpiredAndCollect();

    /// <summary>يزيل الأقفال المنتهية ويعيدها لبث ReleaseSlot.</summary>
    public IReadOnlyList<SlotLockEntry> PurgeExpiredAndCollect()
    {
        var released = new List<SlotLockEntry>();
        var now = DateTime.UtcNow;
        foreach (var kv in _locks)
        {
            if (kv.Value.ExpiresAt <= now && _locks.TryRemove(kv.Key, out var entry))
                released.Add(entry);
        }
        return released;
    }
}

public sealed record SlotLockEntry(
    int FieldId,
    DateTime StartTime,
    int Hours,
    int UserId,
    DateTime ExpiresAt);
