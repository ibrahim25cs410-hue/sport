namespace Riyada.Api.Middleware;

/// <summary>
/// يسجّل الطلبات ويضيف X-Request-Id لتتبع الأخطاء.
/// </summary>
public class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestLoggingMiddleware> _logger;

    public RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var requestId = Guid.NewGuid().ToString("N")[..8];
        context.Response.Headers["X-Request-Id"] = requestId;
        context.Items["RequestId"] = requestId;

        var sw = System.Diagnostics.Stopwatch.StartNew();
        await _next(context);
        sw.Stop();

        if (!context.Request.Path.StartsWithSegments("/swagger"))
        {
            _logger.LogInformation(
                "{Method} {Path} => {Status} ({Ms}ms) [{RequestId}]",
                context.Request.Method,
                context.Request.Path,
                context.Response.StatusCode,
                sw.ElapsedMilliseconds,
                requestId);
        }
    }
}

public static class RequestLoggingMiddlewareExtensions
{
    public static IApplicationBuilder UseRequestLogging(this IApplicationBuilder app)
        => app.UseMiddleware<RequestLoggingMiddleware>();
}
