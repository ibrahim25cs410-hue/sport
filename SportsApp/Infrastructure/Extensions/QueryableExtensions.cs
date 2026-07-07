using Microsoft.EntityFrameworkCore;

namespace Riyada.Infrastructure.Extensions;

/// <summary>امتدادات قراءة فقط — أداء أفضل لعمليات GET.</summary>
public static class QueryableExtensions
{
    public static IQueryable<T> AsReadOnly<T>(this IQueryable<T> query) where T : class =>
        query.AsNoTracking();
}
