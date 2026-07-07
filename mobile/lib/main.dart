import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;

import 'core/bootstrap/app_bootstrap.dart';
import 'core/notifications/booking_notification_listener.dart';
import 'core/utils/session_key_helper.dart';
import 'core/loading/loading_overlay.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/push_notification_provider.dart';
import 'providers/theme_provider.dart';
import 'router/router_provider.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/riyada_brand_colors.dart';
import 'theme/riyada_motion.dart';
import 'theme/riyada_typography_scope.dart';
import 'widgets/ambient_green_background.dart';
import 'widgets/theme_sync.dart';

Future<void> main() async {
  final boot = await AppBootstrap.run();

  runApp(
    UncontrolledProviderScope(
      container: boot.container,
      child: legacy.MultiProvider(
        providers: [
          legacy.ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
          legacy.ChangeNotifierProvider.value(value: boot.themeProvider),
          legacy.ChangeNotifierProvider.value(value: boot.localeProvider),
        ],
        child: const RiyadaApp(),
      ),
    ),
  );
}

class RiyadaApp extends ConsumerWidget {
  const RiyadaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authInterceptorProvider);
    ref.listen(pushNotificationProvider.select((s) => s.generation), (prev, next) {
      if (prev == next) return;
      final key = watchSessionKey(ref);
      if (key != null) ref.invalidate(userNotificationsProvider(key));
    });
    final router = ref.watch(routerProvider);
    final themeMode = context.watch<ThemeProvider>().themeMode;
    final locale = context.watch<LocaleProvider>().locale;
    final textDirection = context.watch<LocaleProvider>().textDirection;

    return MaterialApp.router(
      title: 'رياضة',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.forLocale(Brightness.light, locale),
      darkTheme: AppTheme.forLocale(Brightness.dark, locale),
      themeMode: themeMode,
      themeAnimationDuration: RiyadaMotion.themeSwitch,
      themeAnimationCurve: RiyadaMotion.themeCurve,
      routerConfig: router,
      builder: (context, child) {
        final base = Theme.of(context);
        final isDark = base.brightness == Brightness.dark;
        final textColor = AppColors.typography(base.brightness);
        final branded = base.copyWith(
          scaffoldBackgroundColor: isDark ? RiyadaBrandColors.scaffoldNavy : base.scaffoldBackgroundColor,
          colorScheme: base.colorScheme.copyWith(
            primary: RiyadaBrandColors.primaryTeal,
            secondary: RiyadaBrandColors.secondaryMint,
            surface: isDark ? RiyadaBrandColors.surfaceSlate : base.colorScheme.surface,
            onSurface: textColor,
            onSurfaceVariant: textColor,
            onPrimary: RiyadaBrandColors.onPrimary,
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: RiyadaBrandColors.primaryTeal,
          ),
        );

        return Theme(
          data: branded,
          child: RiyadaTypographyScope(
            child: ThemeSync(
              child: Directionality(
                textDirection: textDirection,
                child: LoadingOverlay(
                  child: BookingNotificationListener(
                    child: AmbientGreenBackground(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
