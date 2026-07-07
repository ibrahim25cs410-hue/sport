using System.Net;
using System.Text.Json;
using Riyada.Application.Common;

namespace Riyada.Api.Middleware;

/// <summary>
/// يلتقط الأخطاء غير المعالجة ويرجع JSON موحّد لـ Flutter.
/// </summary>
public class ExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionMiddleware> _logger;

    public ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ غير معالج: {Path}", context.Request.Path);
            var status = HttpStatusCode.InternalServerError;
            var message = "حدث خطأ في الخادم، يرجى المحاولة لاحقاً.";
            var code = "SERVER_ERROR";

            if (ex is BadHttpRequestException)
            {
                status = HttpStatusCode.BadRequest;
                message = "طلب غير صالح — تحقق من البيانات المرسلة.";
                code = "BAD_REQUEST";
            }
            else if (ex is InsufficientFundsException ife)
            {
                status = HttpStatusCode.PaymentRequired;
                message = ife.Message;
                code = InsufficientFundsException.ErrorCode;
            }
            else if (ex is ServiceUnavailableException sue)
            {
                status = HttpStatusCode.ServiceUnavailable;
                message = sue.Message;
                code = ServiceUnavailableException.ErrorCode;
            }

            await WriteErrorAsync(context, status, message, code);
        }
    }

    public static async Task WriteErrorAsync(HttpContext context, HttpStatusCode status, string message, string code)
    {
        if (context.Response.HasStarted) return;

        context.Response.StatusCode = (int)status;
        context.Response.ContentType = "application/json; charset=utf-8";
        await context.Response.WriteAsync(JsonSerializer.Serialize(new { message, code }));
    }
}

public static class ExceptionMiddlewareExtensions
{
    public static IApplicationBuilder UseGlobalExceptionHandler(this IApplicationBuilder app)
        => app.UseMiddleware<ExceptionMiddleware>();
}
