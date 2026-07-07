using Microsoft.EntityFrameworkCore;
using Riyada.Domain.Entities;
using Riyada.Infrastructure.Data;

namespace Riyada.Infrastructure.Services;

public static class ReviewService
{
    public static bool IsValidRating(int rating) => rating is >= 1 and <= 5;

    public static async Task<bool> HasBookedFieldAsync(AppDbContext db, int userId, int fieldId) =>
        await db.Bookings.AsNoTracking().AnyAsync(b =>
            b.UserId == userId && b.FieldId == fieldId && b.Status == "approved");

    public static async Task<(double Average, int Count)> GetFieldRatingAsync(AppDbContext db, int fieldId)
    {
        var stats = await db.Reviews.AsNoTracking()
            .Where(r => r.FieldId == fieldId)
            .GroupBy(_ => 1)
            .Select(g => new { Avg = g.Average(r => r.Rating), Count = g.Count() })
            .FirstOrDefaultAsync();
        return stats is null ? (0, 0) : (stats.Avg, stats.Count);
    }
}
