import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../config/api_config.dart';
import '../firebase/firebase_app.dart';
import '../loading/global_loading_provider.dart';
import '../../data/datasources/remote/fcm_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/local_notification_service.dart';
import '../../services/onboarding_service.dart';
import '../../services/token_storage.dart';
import '../../utils/api_logger.dart';
import 'notification_bootstrap.dart';
import 'service_bootstrap.dart';

/// Result of cold-start initialization — consumed by [main].
class AppBootstrapResult {
  const AppBootstrapResult({
    required this.container,
    required this.themeProvider,
    required this.localeProvider,
  });

  final ProviderContainer container;
  final ThemeProvider themeProvider;
  final LocaleProvider localeProvider;
}

/// Ordered, fault-tolerant app startup. Never throws — logs and continues.
abstract final class AppBootstrap {
  static Future<AppBootstrapResult> run() async {
    WidgetsFlutterBinding.ensureInitialized();

    // إيقاظ خادم Render مبكراً (بدون انتظار) لتقليل تأخير "الإقلاع البارد".
    _warmUpServer();

    await _safe('Firebase', () async {
      await FirebaseAppService.initialize();
    });
    await _safe('FCM', FcmService.initialize);
    await _safe('Arabic date formatting', () => initializeDateFormatting('ar', null));
    await _safe('English date formatting', () => initializeDateFormatting('en', null));

    final themeProvider = ThemeProvider();
    final localeProvider = LocaleProvider();
    await Future.wait<void>([
      _safe('Theme', themeProvider.load),
      _safe('Locale', localeProvider.load),
      _safe('Local notifications', LocalNotificationService.init),
    ]);

    final tokenStorage = TokenStorage();
    final onboardingComplete = await _safeValue(
      'Onboarding',
      OnboardingService().isComplete,
      fallback: false,
    );
    final container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(tokenStorage)],
    );
    container.read(onboardingCompleteProvider.notifier).state = onboardingComplete;

    container.read(globalLoadingProvider.notifier).reset();

    await container.read(authProvider.notifier).bootstrap();
    final auth = container.read(authProvider);
    apiLog(
      'Auth bootstrap',
      auth.isLoggedIn ? 'session active → /home' : 'no session → /login',
    );

    ServiceBootstrap.initialize(container);
    NotificationBootstrap.wire(container);

    return AppBootstrapResult(
      container: container,
      themeProvider: themeProvider,
      localeProvider: localeProvider,
    );
  }

  /// نداء "إيقاظ" غير محجوب — يُطلق طلباً خفيفاً كي يبدأ خادم Render بالإقلاع
  /// بينما يُكمل التطبيق تهيئته، فتصبح أول عملية للمستخدم أسرع.
  static void _warmUpServer() {
    () async {
      try {
        final dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ));
        await dio.get<dynamic>('${ApiConfig.baseUrl}/health');
      } catch (_) {
        // متوقع أثناء الإقلاع البارد — الغرض مجرد إيقاظ الخادم.
      }
    }();
  }

  static Future<void> _safe(String label, Future<void> Function() action) async {
    try {
      await action();
    } catch (e, st) {
      debugPrint('$label init skipped: $e\n$st');
    }
  }

  static Future<T> _safeValue<T>(
    String label,
    Future<T> Function() action, {
    required T fallback,
  }) async {
    try {
      return await action();
    } catch (e, st) {
      debugPrint('$label init skipped: $e\n$st');
      return fallback;
    }
  }
}
