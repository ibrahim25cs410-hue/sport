namespace Riyada.Application.Common;

/// <summary>Non-sensitive FCM copy — no prices, payment details, or reference codes.</summary>
public static class PushNotificationMessages
{
    public const string DefaultTitle = "Riyada";

    public static string NewBookingForOwner(string fieldName) =>
        $"New booking request for {SanitizeFieldName(fieldName)}!";

    public const string BookingApprovedTitle = "Booking approved";
    public const string BookingApprovedBody = "Your booking was approved.";

    public const string BookingRejectedTitle = "Booking update";
    public const string BookingRejectedBody = "Your booking request was not approved.";

    public const string LowBalanceTitle = "Low balance";
    public const string LowBalanceBody =
        "Your wallet balance is low. Top up to keep receiving bookings.";

    public const string BookingCancelledOwnerTitle = "Booking cancelled";
    public const string BookingCancelledOwnerBody = "A booking on your field was cancelled.";

    private static string SanitizeFieldName(string fieldName)
    {
        var name = fieldName.Trim();
        return name.Length > 60 ? $"{name[..57]}..." : name;
    }
}

public static class PushNotificationEventTypes
{
    public const string BookingPending = "booking_pending";
    public const string BookingApproved = "booking_approved";
    public const string BookingRejected = "booking_rejected";
    public const string BookingCancelled = "booking_cancelled";
    public const string CancellationAbuseWarning = "cancellation_abuse_warning";
    public const string AccountRestricted = "account_restricted";
    public const string WalletLowBalance = "wallet_low_balance";
}

public enum CancellationPushKind
{
    None,
    AbuseWarning,
    AccountRestricted
}
