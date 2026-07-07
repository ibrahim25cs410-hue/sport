import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/notifications/booking_notification_coordinator.dart';
import '../../../services/local_notification_service.dart';
import 'booking_push_payload.dart';

typedef NotificationTapHandler = void Function(RemoteMessage message);

/// Displays FCM payloads when the app is in the foreground and routes taps.
abstract final class NotificationHandler {
  static NotificationTapHandler? onMessageOpened;
  static NotificationTapHandler? onForegroundMessage;

  static void handleForeground(RemoteMessage message) {
    onForegroundMessage?.call(message);
    final payload = BookingPushPayload.fromMessage(message);
    final title = _title(message);
    final body = _body(message);
    if (title.isEmpty && body.isEmpty) return;
    LocalNotificationService.showBookingUpdate(
      id: message.hashCode,
      title: title,
      body: body,
      payload: encodeNotificationPayload(payload),
    );
  }

  static void handleOpened(RemoteMessage message) {
    onMessageOpened?.call(message);
    onForegroundMessage?.call(message);
  }

  static String _title(RemoteMessage message) =>
      message.notification?.title ?? message.data['title'] ?? 'Riyada';

  static String _body(RemoteMessage message) =>
      message.notification?.body ?? message.data['body'] ?? '';
}
