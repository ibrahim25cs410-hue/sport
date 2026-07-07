using System.Security.Claims;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.RateLimiting;

namespace Riyada.Api.Security;

public static class RateLimitingExtensions
{
    public const string PaymentsPolicy = "payments";
    public const string BookingsWritePolicy = "bookings-write";
    public const string AuthPolicy = "auth";

    public static IServiceCollection AddRiyadaRateLimiting(this IServiceCollection services, IConfiguration config)
    {
        var paymentsLimit = config.GetValue("RateLimiting:Payments:PermitLimit", 15);
        var paymentsWindow = config.GetValue("RateLimiting:Payments:WindowSeconds", 60);
        var bookingsLimit = config.GetValue("RateLimiting:Bookings:PermitLimit", 30);
        var bookingsWindow = config.GetValue("RateLimiting:Bookings:WindowSeconds", 60);
        var authLimit = config.GetValue("RateLimiting:Auth:PermitLimit", 10);
        var authWindow = config.GetValue("RateLimiting:Auth:WindowSeconds", 60);

        services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
            options.OnRejected = async (context, token) =>
            {
                var retryAfter = context.Lease.TryGetMetadata(MetadataName.RetryAfter, out var metadata) && metadata is TimeSpan ts
                    ? ((int)ts.TotalSeconds).ToString()
                    : paymentsWindow.ToString();
                context.HttpContext.Response.Headers.RetryAfter = retryAfter;
                await context.HttpContext.Response.WriteAsJsonAsync(
                    new { message = "طلبات كثيرة — حاول لاحقاً", code = "rate_limit_exceeded" }, token);
            };

            options.AddPolicy(PaymentsPolicy, httpContext =>
                RateLimitPartition.GetFixedWindowLimiter(
                    PartitionKey(httpContext),
                    _ => new FixedWindowRateLimiterOptions
                    {
                        AutoReplenishment = true,
                        PermitLimit = paymentsLimit,
                        Window = TimeSpan.FromSeconds(paymentsWindow),
                        QueueLimit = 0
                    }));

            options.AddPolicy(BookingsWritePolicy, httpContext =>
                RateLimitPartition.GetFixedWindowLimiter(
                    PartitionKey(httpContext),
                    _ => new FixedWindowRateLimiterOptions
                    {
                        AutoReplenishment = true,
                        PermitLimit = bookingsLimit,
                        Window = TimeSpan.FromSeconds(bookingsWindow),
                        QueueLimit = 0
                    }));

            options.AddPolicy(AuthPolicy, httpContext =>
                RateLimitPartition.GetFixedWindowLimiter(
                    IpPartitionKey(httpContext),
                    _ => new FixedWindowRateLimiterOptions
                    {
                        AutoReplenishment = true,
                        PermitLimit = authLimit,
                        Window = TimeSpan.FromSeconds(authWindow),
                        QueueLimit = 0
                    }));
        });

        return services;
    }

    static string PartitionKey(HttpContext ctx) =>
        ctx.User.Identity?.IsAuthenticated == true
            ? $"user:{ctx.User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "unknown"}"
            : IpPartitionKey(ctx);

    static string IpPartitionKey(HttpContext ctx) =>
        $"ip:{ctx.Connection.RemoteIpAddress?.ToString() ?? "unknown"}";
}
