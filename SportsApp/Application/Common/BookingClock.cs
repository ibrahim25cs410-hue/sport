namespace Riyada.Application.Common;

/// <summary>UTC clock and Iraq (Asia/Baghdad) field-local time for booking rules.</summary>
public static class BookingClock
{
    private static readonly TimeZoneInfo IraqZone = ResolveIraqZone();

    public static DateTime UtcNow => DateTime.UtcNow;

    public static DateTime ToUtc(DateTime value)
    {
        if (value.Kind == DateTimeKind.Utc) return value;
        if (value.Kind == DateTimeKind.Local) return value.ToUniversalTime();
        return TimeZoneInfo.ConvertTimeToUtc(
            DateTime.SpecifyKind(value, DateTimeKind.Unspecified), IraqZone);
    }

    public static DateTime ToFieldLocal(DateTime value)
    {
        if (value.Kind == DateTimeKind.Unspecified) return value;
        return TimeZoneInfo.ConvertTimeFromUtc(ToUtc(value), IraqZone);
    }

    public static DateTime FieldLocalNow => ToFieldLocal(UtcNow);

    public static DateTime FieldToday => FieldLocalNow.Date;

    private static TimeZoneInfo ResolveIraqZone()
    {
        try
        {
            return TimeZoneInfo.FindSystemTimeZoneById(
                OperatingSystem.IsWindows() ? "Arab Standard Time" : "Asia/Baghdad");
        }
        catch
        {
            return TimeZoneInfo.CreateCustomTimeZone("Asia/Baghdad", TimeSpan.FromHours(3), "Iraq", "Iraq");
        }
    }
}
