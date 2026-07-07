using Riyada.Domain.Entities;

namespace Riyada.Application.Common;

public static class CancellationAbuseRules
{
    public const int MaxCancellationsPer24Hours = 5;
    public const int WarningCancellationCount = 4;

    public const string BanErrorMessage = "Account restricted due to excessive cancellations.";
    public const string BanReason = "Excessive cancellations";

    public const string WarningTitle = "Cancellation warning";
    public const string WarningMessage =
        "Warning: You have 4 cancellations today. One more will result in account suspension.";

    public static bool IsExempt(User user) =>
        user.Role.Equals("admin", StringComparison.OrdinalIgnoreCase);

    public static bool IsBanned(User user) =>
        user.AccountStatus.Equals(UserAccountStatuses.Banned, StringComparison.OrdinalIgnoreCase);
}
