using System.Net.Http.Headers;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Riyada.Application.Abstractions;

namespace Riyada.Infrastructure.PaymentGateways;

/// <summary>
/// تحقق زين كاش عبر API المزوّد — المفاتيح من appsettings/متغيرات البيئة فقط.
/// </summary>
public sealed class ZainCashGatewayVerifier(
    IHttpClientFactory httpFactory,
    IConfiguration config,
    IHostEnvironment env,
    ILogger<ZainCashGatewayVerifier> logger) : IPaymentGatewayVerifier
{
    public string Gateway => "zaincash";

    public async Task<GatewayVerificationResult> VerifyTransactionAsync(
        string transactionToken,
        string? providerReference,
        int expectedAmountIqd,
        CancellationToken cancellationToken = default)
    {
        var apiKey = config["PaymentGateways:ZainCash:ApiKey"];
        var baseUrl = config["PaymentGateways:ZainCash:BaseUrl"];

        if (string.IsNullOrWhiteSpace(apiKey) || string.IsNullOrWhiteSpace(baseUrl))
        {
            if (!env.IsDevelopment())
            {
                logger.LogError("ZainCash gateway credentials missing in production.");
                return new GatewayVerificationResult(false, null, "gateway_not_configured");
            }
            return DevelopmentStubVerify(transactionToken, providerReference, expectedAmountIqd);
        }

        try
        {
            var client = httpFactory.CreateClient("ZainCash");
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
            var url = $"{baseUrl.TrimEnd('/')}/transaction/status?token={Uri.EscapeDataString(transactionToken)}";
            using var response = await client.GetAsync(url, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning("ZainCash verify HTTP {Status} for token prefix {Prefix}",
                    response.StatusCode, transactionToken[..Math.Min(8, transactionToken.Length)]);
                return new GatewayVerificationResult(false, null, "gateway_http_error");
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
            using var doc = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);
            var root = doc.RootElement;
            var status = root.TryGetProperty("status", out var s) ? s.GetString() : null;
            var gatewayTxnId = root.TryGetProperty("id", out var id) ? id.GetString() : providerReference;
            var amount = root.TryGetProperty("amount", out var a) && a.TryGetInt32(out var amt) ? amt : 0;

            if (!string.Equals(status, "success", StringComparison.OrdinalIgnoreCase)
                && !string.Equals(status, "completed", StringComparison.OrdinalIgnoreCase))
            {
                return new GatewayVerificationResult(false, gatewayTxnId, "gateway_status_not_paid");
            }

            if (amount > 0 && amount != expectedAmountIqd)
            {
                logger.LogWarning("ZainCash amount mismatch: expected {Expected}, got {Actual}", expectedAmountIqd, amount);
                return new GatewayVerificationResult(false, gatewayTxnId, "amount_mismatch");
            }

            if (string.IsNullOrWhiteSpace(gatewayTxnId))
                return new GatewayVerificationResult(false, null, "missing_gateway_transaction_id");

            return new GatewayVerificationResult(true, gatewayTxnId, null);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "ZainCash verification failed");
            return new GatewayVerificationResult(false, null, "gateway_exception");
        }
    }

    static GatewayVerificationResult DevelopmentStubVerify(
        string transactionToken, string? providerReference, int expectedAmountIqd)
    {
        if (string.IsNullOrWhiteSpace(providerReference) || expectedAmountIqd <= 0)
            return new GatewayVerificationResult(false, null, "invalid_stub_payment");
        return new GatewayVerificationResult(true, $"ZC-DEV-{providerReference}", null);
    }
}
