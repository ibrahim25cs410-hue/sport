import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../games/penalty_shootout/penalty_launcher.dart';
import '../games/penalty_flame/penalty_flame_launcher.dart';
import '../models/booking_checkout_args.dart';
import '../models/field.dart';
import 'overlay_navigation.dart';

/// مسارات التطبيق — التوجيه الفعلي في [routerProvider].
abstract final class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';
  static const login = '/login';
  static const registerUser = '/register/user';
  static const registerOwner = '/register/owner';
  static const userHome = '/home';
  static const ownerHome = '/owner';
  static const ownerDashboard = '/owner/dashboard';
  static const ownerCommissionCheckout = '/owner/commission-checkout';
  static const adminDashboard = '/admin-dashboard';
  static const profile = '/profile';
  static const addField = '/owner/add-field';
  static const bookingHistory = '/history';
  static const penaltyShootout = '/games/penalty';
  static const penaltyFlame = '/games/penalty-flame';
  static const notifications = '/notifications';
  static const paymentMethods = '/payment-methods';
  static const bookingCheckout = '/booking/checkout';
  static String field(int id) => '/field/$id';
}

extension AppNavigation on BuildContext {
  GoRouter get _router => GoRouter.of(this);

  void goSplash() => _router.go(AppRoutes.splash);
  void goOnboarding() => _router.go(AppRoutes.onboarding);
  void goWelcome() => _router.go(AppRoutes.welcome);

  void goLogin() => pushOverlay(AppRoutes.login);
  void goRegisterUser() => pushOverlay(AppRoutes.registerUser);
  void goRegisterOwner() => pushOverlay(AppRoutes.registerOwner);

  void goUserHome() => _router.go(AppRoutes.userHome);
  void goOwnerHome() => _router.go(AppRoutes.ownerHome);
  void goAdminDashboard() => _router.go(AppRoutes.adminDashboard);

  void goOwnerDashboard() => pushOverlay(AppRoutes.ownerDashboard);
  void goOwnerCommissionCheckout() => pushOverlay(AppRoutes.ownerCommissionCheckout);
  void goProfile() => pushOverlay(AppRoutes.profile);
  void goAddField() => pushOverlay(AppRoutes.addField);

  void goBookingHistory() => pushOverlay(AppRoutes.bookingHistory);
  void goNotifications() => pushOverlay(AppRoutes.notifications);
  void goPaymentMethods() => pushOverlay(AppRoutes.paymentMethods);
  void goPenaltyShootout() => openPenaltyGame(this);
  void goPenaltyFlame() => openPenaltyFlameGame(this);

  Future<bool?> goBookingCheckout(BookingCheckoutArgs args) =>
      pushOverlay<bool>(AppRoutes.bookingCheckout, extra: args);

  Future<void> goField(Field field) => pushOverlay(AppRoutes.field(field.id), extra: field);

  void goWelcomeClearStack() => _router.go(AppRoutes.welcome);

  void goLoginClearStack() => _router.go(AppRoutes.login);

  void popResult<T extends Object?>([T? result]) {
    if (_router.canPop()) {
      _router.pop(result);
    } else {
      final nav = Navigator.of(this, rootNavigator: true);
      if (nav.canPop()) nav.pop(result);
    }
  }

  /// بعد تسجيل الدخول — انتقل للوجهة الصحيحة حسب الدور الفعلي في الجلسة.
  void goHomeAfterAuth({bool? isAdmin, bool? isOwner}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Prefer explicit flags, but never block owner navigation.
      if (isAdmin == true) {
        goAdminDashboard();
        return;
      }
      if (isOwner == true) {
        goOwnerHome();
        return;
      }
      goUserHome();
    });
  }
}
