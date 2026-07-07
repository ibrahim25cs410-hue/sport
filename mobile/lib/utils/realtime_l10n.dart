import '../l10n/app_localizations.dart';
import '../models/realtime_booking_event.dart';

String localizeRealtimeTitle(AppLocalizations l10n, String key) => switch (key) {
      'rtTitleNewBooking' => l10n.rtTitleNewBooking,
      'rtTitleBookingPending' => l10n.rtTitleBookingPending,
      'rtTitleBookingApproved' => l10n.rtTitleBookingApproved,
      'rtTitleBookingRejected' => l10n.rtTitleBookingRejected,
      'rtTitleBookingCancelled' => l10n.rtTitleBookingCancelled,
      _ => key,
    };

String localizeRealtimeMessage(AppLocalizations l10n, BookingUpdatedEvent event) {
  String arg(String name, [String fallback = '']) => event.messageArgs[name] ?? fallback;
  return switch (event.messageKey) {
    'rtMsgNewBooking' => l10n.rtMsgNewBooking(
        arg('userName'),
        arg('dateTime'),
        arg('referenceCode'),
      ),
    'rtMsgBookingPending' => l10n.rtMsgBookingPending(arg('referenceCode')),
    'rtMsgBookingApproved' => l10n.rtMsgBookingApproved(
        arg('fieldName'),
        arg('referenceCode'),
      ),
    'rtMsgBookingRejected' => l10n.rtMsgBookingRejected(arg('fieldName')),
    'rtMsgBookingCancelled' => l10n.rtMsgBookingCancelled(
        arg('dateTime'),
        arg('fieldName'),
      ),
    _ => event.messageKey,
  };
}

String localizeRealtimeSnackBar(AppLocalizations l10n, BookingUpdatedEvent event) {
  final title = localizeRealtimeTitle(l10n, event.titleKey);
  final body = localizeRealtimeMessage(l10n, event);
  return '$title — $body';
}

String slotConflictMessage(AppLocalizations l10n, String messageKey) => switch (messageKey) {
      'slotUnderSelection' => l10n.slotUnderSelection,
      'slotJustBooked' => l10n.slotJustBooked,
      'slotLockExpired' => l10n.slotLockExpired,
      _ => l10n.slotJustBooked,
    };
