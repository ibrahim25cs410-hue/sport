namespace Riyada.Application.Common;

public sealed class InsufficientFundsException : Exception
{
    public const string ErrorCode = "InsufficientFunds";
    public const string UserMessage = "Insufficient balance to cover commission. Please top up.";

    public InsufficientFundsException(int requiredAmountIqd, decimal availableBalanceIqd)
        : base(UserMessage)
    {
        RequiredAmountIqd = requiredAmountIqd;
        AvailableBalanceIqd = availableBalanceIqd;
    }

    public int RequiredAmountIqd { get; }
    public decimal AvailableBalanceIqd { get; }
}
