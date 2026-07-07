namespace Riyada.Application.Common;

/// <summary>Parses and clamps list query parameters for paginated API endpoints.</summary>
public static class Pagination
{
    public const int DefaultLimit = 20;
    public const int MaxLimit = 100;
    public const int LegacyMaxItems = 100;

    public static (int Page, int Limit, bool Explicit) Parse(int? page, int? limit)
    {
        var explicitRequest = page is not null || limit is not null;
        var p = page is null or < 1 ? 1 : page.Value;
        var l = limit is null or < 1 ? DefaultLimit : Math.Min(limit.Value, MaxLimit);
        return (p, l, explicitRequest);
    }
}
