namespace Riyada.Application.Abstractions;

/// <summary>
/// نتيجة التحقق من بوابة الدفع — المصدر الوحيد الموثوق لتأكيد الدفع (ليس التطبيق).
/// </summary>
public sealed record GatewayVerificationResult(
    bool Success,
    string? GatewayTransactionId,
    string? FailureReason);

/// <summary>
/// يتحقق من حالة المعاملة مباشرةً مع مزوّد الدفع (زين كاش / بوابة البطاقة).
/// </summary>
public interface IPaymentGatewayVerifier
{
    string Gateway { get; }
    Task<GatewayVerificationResult> VerifyTransactionAsync(
        string transactionToken,
        string? providerReference,
        int expectedAmountIqd,
        CancellationToken cancellationToken = default);
}

public interface IPaymentGatewayVerifierRouter
{
    IPaymentGatewayVerifier Resolve(string gateway);
}
