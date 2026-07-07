using Riyada.Application.Abstractions;

namespace Riyada.Infrastructure.PaymentGateways;

public sealed class PaymentGatewayVerifierRouter(IEnumerable<IPaymentGatewayVerifier> verifiers) : IPaymentGatewayVerifierRouter
{
    private readonly Dictionary<string, IPaymentGatewayVerifier> _map =
        verifiers.ToDictionary(v => v.Gateway, StringComparer.OrdinalIgnoreCase);

    public IPaymentGatewayVerifier Resolve(string gateway)
    {
        if (!_map.TryGetValue(gateway.Trim(), out var verifier))
            throw new InvalidOperationException($"Unsupported payment gateway: {gateway}");
        return verifier;
    }
}
