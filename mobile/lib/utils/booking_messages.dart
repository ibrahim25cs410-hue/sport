import '../core/booking/booking_result.dart';
import '../exceptions/booking_cancellation_exception.dart';
import '../l10n/app_localizations.dart';
import 'error_messages.dart';
import 'realtime_l10n.dart';

/// رسائل أخطاء الحجز للمستخدم (SnackBar / حوار).
String bookingFailureMessage(AppLocalizations l10n, BookingFailure failure) {
  return switch (failure.code) {
    BookingFailureCode.cancelWindowClosed => l10n.cancelWindowError,
    BookingFailureCode.accountRestricted => _accountRestrictedMessage(l10n, failure),
    BookingFailureCode.slotUnavailable => l10n.slotJustBooked,
    BookingFailureCode.invalidHours => failure.messageKey == 'outsideHours'
        ? l10n.bookingOutsideHours
        : l10n.bookingInvalidHours,
    BookingFailureCode.pastTime => l10n.bookingPastTime,
    BookingFailureCode.conflict => slotConflictMessage(l10n, failure.messageKey ?? 'slotJustBooked'),
    BookingFailureCode.unknown => friendlyErrorMessage(failure.cause),
  };
}

String _accountRestrictedMessage(AppLocalizations l10n, BookingFailure failure) {
  final cause = failure.cause;
  if (cause is BookingCancellationException && cause.message != null) {
    return cause.message!;
  }
  return l10n.accountRestrictedError;
}
