import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firebase_app.dart';
import '../../../core/notifications/booking_notification_coordinator.dart';
import '../../../services/local_notification_service.dart';
import 'booking_push_payload.dart';

/// Background FCM handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await FirebaseAppService.initialize();
  await LocalNotificationService.init();

  final payload = BookingPushPayload.fromMessage(message);
  if (!payload.isBookingStatusChange) return;

  final title = message.notification?.title ?? payload.title;
  final body = message.notification?.body ?? payload.body;
  if (title.isEmpty && body.isEmpty) return;

  await LocalNotificationService.showBookingUpdate(
    id: message.hashCode,
    title: title,
    body: body,
    payload: encodeNotificationPayload(payload),
  );

  if (kDebugMode) {
    debugPrint('FCM background booking: ${payload.type}');
  }
}
