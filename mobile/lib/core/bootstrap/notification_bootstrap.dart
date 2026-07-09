import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/booking_notification_coordinator.dart';
import '../../data/datasources/remote/fcm_service.dart';
import '../../data/datasources/remote/notification_handler.dart';
import '../../providers/auth_provider.dart';
import '../../providers/push_notification_provider.dart';
import '../../core/di/service_providers.dart';
import '../../services/local_notification_service.dart';

/// Wires FCM + local notification callbacks after [ProviderContainer] is ready.
abstract final class NotificationBootstrap {
  static void wire(ProviderContainer container) {
    NotificationHandler.onForegroundMessage = (message) {
      try {
        container.read(pushNotificationProvider.notifier).handleMessage(message);
      } catch (e, st) {
        debugPrint('FCM foreground handler failed: $e\n$st');
      }
    };

    NotificationHandler.onMessageOpened = (message) {
      try {
        container.read(pushNotificationProvider.notifier).handleMessage(message);
        BookingNotificationCoordinator.handleOpened(container, message);
      } catch (e, st) {
        debugPrint('FCM open handler failed: $e\n$st');
      }
    };

    LocalNotificationService.onNotificationTap = (payload) {
      try {
        final parsed = decodeNotificationPayload(payload);
        if (parsed == null) return;
        final message = RemoteMessage(
          data: {
            'type': parsed.type,
            if (parsed.bookingId != null) 'bookingId': '${parsed.bookingId}',
          },
        );
        container.read(pushNotificationProvider.notifier).handleMessage(message);
        BookingNotificationCoordinator.handleOpened(container, message);
      } catch (e, st) {
        debugPrint('Local notification tap failed: $e\n$st');
      }
    };

    FcmService.onTokenRefresh = (_) async {
      try {
        if (!container.read(authProvider).isLoggedIn) return;
        await FcmService.syncTokenWithServer(container.read(apiServiceProvider));
      } catch (e, st) {
        debugPrint('FCM token refresh sync failed: $e\n$st');
      }
    };

    final socket = container.read(socketServiceProvider);
    socket.notificationStream.listen((notification) {
      try {
        container.read(pushNotificationProvider.notifier).handleSocketNotification(notification);
      } catch (e, st) {
        debugPrint('Socket notification handler failed: $e\n$st');
      }
    });
  }
}
