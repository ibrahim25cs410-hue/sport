using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Riyada.Application.Abstractions;

namespace Riyada.Infrastructure.PaymentGateways;

/// <summary>
/// تحقق بوابة البطاقة (hosted checkout) — استعلام server-to-server فقط.
/// </summary>
public sealed class CardGatewayVerifier(
    IHttpClientFactory httpFactory,
    IConfiguration config,
    IHostEnvironment env,
    ILogger<CardGatewayVerifier> logger) : IPaymentGatewayVerifier
{
    public string Gateway => "card";

    public async Task<GatewayVerificationResult> VerifyTransactionAsync(
        string transactionToken,
        string? providerReference,
        int expectedAmountIqd,
        CancellationToken cancellationToken = default)
    {
        var apiKey = config["PaymentGateways:Card:ApiKey"];
        var baseUrl = config["PaymentGateways:Card:BaseUrl"];

        if (string.IsNullOrWhiteSpace(apiKey) || string.IsNullOrWhiteSpace(baseUrl))
        {
            if (!env.IsDevelopment())
            {
                logger.LogError("Card gateway credentials missing in production.");
                return new GatewayVerificationResult(false, null, "gateway_not_configured");
            }
            return DevelopmentStubVerify(transactionToken, providerReference, expectedAmountIqd);
        }

        try
        {
            var client = httpFactory.CreateClient("CardGateway");
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
            var payload = JsonSerializer.Serialize(new { token = transactionToken });
            using var content = new StringContent(payload, Encoding.UTF8, "application/json");
            using var response = await client.PostAsync($"{baseUrl.TrimEnd('/')}/payments/verify", content, cancellationToken);
            if (!response.IsSuccessStatusCode)
                return new GatewayVerificationResult(false, null, "gateway_http_error");

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
            using var doc = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);
            var root = doc.RootElement;
            var paid = root.TryGetProperty("paid", out var p) && p.GetBoolean();
            var gatewayTxnId = root.TryGetProperty("transactionId", out var t) ? t.GetString() : providerReference;
            var amount = root.TryGetProperty("amount", out var a) && a.TryGetInt32(out var amt) ? amt : 0;

            if (!paid)
                return new GatewayVerificationResult(false, gatewayTxnId, "gateway_status_not_paid");
            if (amount > 0 && amount != expectedAmountIqd)
                return new GatewayVerificationResult(false, gatewayTxnId, "amount_mismatch");
            if (string.IsNullOrWhiteSpace(gatewayTxnId))
                return new GatewayVerificationResult(false, null, "missing_gateway_transaction_id");

            return new GatewayVerificationResult(true, gatewayTxnId, null);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Card gateway verification failed");
            return new GatewayVerificationResult(false, null, "gateway_exception");
        }
    }

    static GatewayVerificationResult DevelopmentStubVerify(
        string transactionToken, string? providerReference, int expectedAmountIqd)
    {
        if (string.IsNullOrWhiteSpace(providerReference) || expectedAmountIqd <= 0)
            return new GatewayVerificationResult(false, null, "invalid_stub_payment");
        return new GatewayVerificationResult(true, $"CARD-DEV-{providerReference}", null);
    }
}
