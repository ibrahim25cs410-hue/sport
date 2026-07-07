using System.Collections.Concurrent;

namespace Riyada.Infrastructure.Services;

/// <summary>يتتبع الملاعب الأكثر طلباً لجدولة الـ pre-fetch في الخلفية.</summary>
public sealed class FieldPrefetchCache
{
    private readonly ConcurrentDictionary<int, int> _scheduleHits = new();

    public void RecordScheduleRequest(int fieldId) =>
        _scheduleHits.AddOrUpdate(fieldId, 1, (_, count) => count + 1);

    public IReadOnlyList<int> GetTopFieldIds(int max = 5)
    {
        if (_scheduleHits.IsEmpty) return [];

        return _scheduleHits
            .OrderByDescending(kv => kv.Value)
            .Take(max)
            .Select(kv => kv.Key)
            .ToList();
    }
}
