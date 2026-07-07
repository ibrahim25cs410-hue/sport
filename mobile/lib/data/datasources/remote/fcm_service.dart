import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/firebase_app.dart';
import '../../../services/api_client.dart';
import 'fcm_background_handler.dart';
import 'notification_handler.dart';

typedef FcmTokenRefreshHandler = Future<void> Function(String token);

/// Registers FCM tokens with the API and delegates message display to [NotificationHandler].
abstract final class FcmService {
  static String? _cachedToken;
  static FcmTokenRefreshHandler? onTokenRefresh;

  static Future<void> initialize() async {
    if (!FirebaseAppService.isReady) {
      if (kDebugMode) debugPrint('FCM skipped: Firebase not configured');
      return;
    }
    try {
      final messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _cachedToken = await messaging.getToken();
      if (kDebugMode) debugPrint('FCM token: $_cachedToken');

      FirebaseMessaging.onMessage.listen(NotificationHandler.handleForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(NotificationHandler.handleOpened);

      final initial = await messaging.getInitialMessage();
      if (initial != null) NotificationHandler.handleOpened(initial);

      messaging.onTokenRefresh.listen((token) async {
        _cachedToken = token;
        if (kDebugMode) debugPrint('FCM token refreshed');
        if (onTokenRefresh != null) {
          await onTokenRefresh!(token);
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('FCM init skipped: $e');
    }
  }

  /// Uploads the device token after login or on every app launch.
  static Future<void> syncTokenWithServer(ApiClient client) async {
    if (!FirebaseAppService.isReady) return;
    try {
      final token = _cachedToken ?? await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      _cachedToken = token;
      await client.dio.post('/users/update-token', data: {
        'token': token,
        'platform': _platformName(),
      });
      if (kDebugMode) debugPrint('FCM token registered on server');
    } catch (e) {
      if (kDebugMode) debugPrint('FCM server registration failed: $e');
    }
  }

  static String? _platformName() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return null;
  }
}
