import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef LocalNotificationTapHandler = void Function(String? payload);

/// إشعارات محلية — تظهر عند موافقة المالك حتى في الخلفية.
class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static LocalNotificationTapHandler? onNotificationTap;

  static Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> showBookingUpdate({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'riyada_bookings',
        'حجوزات رياضة',
        channelDescription: 'تنبيهات الحجز والموافقة',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }
}
