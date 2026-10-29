import 'dart:async';

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

/// Splits startup into synchronous app creation and fault-tolerant deferred work.
abstract final class AppBootstrap {
  /// Creates everything needed by [runApp] without waiting on I/O.
  static AppBootstrapResult create() {
    WidgetsFlutterBinding.ensureInitialized();

    final themeProvider = ThemeProvider();
    final localeProvider = LocaleProvider();
    final tokenStorage = TokenStorage();
    final container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(tokenStorage)],
    );
    container.read(globalLoadingProvider.notifier).reset();

    return AppBootstrapResult(
      container: container,
      themeProvider: themeProvider,
      localeProvider: localeProvider,
    );
  }

  /// Starts local restoration and remote services after Flutter paints once.
  static Future<void> initializeDeferred(AppBootstrapResult boot) async {
    _warmUpServer();

    ServiceBootstrap.initialize(boot.container);
    NotificationBootstrap.wire(boot.container);

    final authBootstrap =
        boot.container.read(authProvider.notifier).bootstrap();
    unawaited(_initializePushNotifications(boot.container, authBootstrap));
    unawaited(_safe('Local notifications', LocalNotificationService.init));

    await Future.wait<void>([
      _safe('Theme', boot.themeProvider.load),
      _safe('Locale', boot.localeProvider.load),
      _safe(
        'Arabic date formatting',
        () => initializeDateFormatting('ar', null),
      ),
      _safe(
        'English date formatting',
        () => initializeDateFormatting('en', null),
      ),
      _loadOnboarding(boot.container),
      authBootstrap,
    ]);

    final auth = boot.container.read(authProvider);
    apiLog(
      'Auth bootstrap',
      auth.isLoggedIn ? 'session active → /home' : 'no session → /login',
    );
  }

  static Future<void> _initializePushNotifications(
    ProviderContainer container,
    Future<void> authBootstrap,
  ) async {
    await _safe('Firebase', () async {
      await FirebaseAppService.initialize();
    });
    await _safe('FCM', FcmService.initialize);
    await authBootstrap;
    if (container.read(authProvider).isLoggedIn) {
      await _safe(
        'FCM token sync',
        () =>
            FcmService.syncTokenWithServer(container.read(apiServiceProvider)),
      );
    }
  }

  static Future<void> _loadOnboarding(ProviderContainer container) async {
    final complete = await _safeValue(
      'Onboarding',
      OnboardingService().isComplete,
      fallback: true,
    );
    container.read(onboardingCompleteProvider.notifier).state = complete;
  }

  /// نداء "إيقاظ" غير محجوب — يُطلق طلباً خفيفاً كي يبدأ خادم Render بالإقلاع
  /// بينما يُكمل التطبيق تهيئته، فتصبح أول عملية للمستخدم أسرع.
  static void _warmUpServer() {
    () async {
      try {
        final dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
          ),
        );
        await dio.get<dynamic>('${ApiConfig.baseUrl}/health');
      } catch (_) {
        // متوقع أثناء الإقلاع البارد — الغرض مجرد إيقاظ الخادم.
      }
    }();
  }

  static Future<void> _safe(
    String label,
    Future<void> Function() action,
  ) async {
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
