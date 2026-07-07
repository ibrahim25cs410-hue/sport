namespace Riyada.Application.DTOs;

public record PagedResult<T>(
    IReadOnlyList<T> Items,
    int Page,
    int Limit,
    int TotalCount,
    bool HasNextPage);
