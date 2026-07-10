import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/notifications/presentation/notifications_screen.dart';
import '../features/owner/presentation/owner_commission_checkout_screen.dart';
import '../features/owner/presentation/owner_dashboard_screen.dart';
import '../features/payment/presentation/payment_methods_screen.dart';
import '../features/payment/presentation/user_booking_checkout_screen.dart';
import '../features/shell/presentation/main_wrapper.dart';
import '../games/penalty_shootout/penalty_menu_screen.dart';
import '../games/penalty_flame/penalty_flame_bridge_screen.dart';
import '../models/booking_checkout_args.dart';
import '../models/field.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../screens/add_field_screen.dart';
import '../screens/booking_history_screen.dart';
import '../features/explore/presentation/field_detail_route_screen.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/register_owner_screen.dart';
import '../screens/register_user_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/welcome_screen.dart';
import 'app_router.dart';
import 'navigation_keys.dart';
import 'page_transitions.dart';

/// يُحدّث الموجّه عند تغيّر حالة المصادقة.
final class AuthRouterRefresh extends ChangeNotifier {
  AuthRouterRefresh(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
    ref.listen(onboardingCompleteProvider, (_, __) => notifyListeners());
  }
}

final authRouterRefreshProvider = Provider<AuthRouterRefresh>((ref) {
  final n = AuthRouterRefresh(ref);
  ref.onDispose(n.dispose);
  return n;
});

String? _homeFor(User user) {
  if (user.isAdmin) return AppRoutes.adminDashboard;
  if (user.isOwner) return AppRoutes.ownerHome;
  return AppRoutes.userHome;
}

bool _isAuthEntryPath(String path) => path == AppRoutes.login ||
    path == AppRoutes.registerUser ||
    path == AppRoutes.registerOwner ||
    path == AppRoutes.welcome ||
    path == AppRoutes.onboarding;

String _initialLocation(AuthState auth, bool onboardingComplete) {
  if (auth.isLoggedIn) return _homeFor(auth.user!) ?? AppRoutes.userHome;
  if (!onboardingComplete) return AppRoutes.onboarding;
  return AppRoutes.welcome;
}

/// Redirects users away from shell routes that do not match their role.
String? _roleShellGuard(User user, String path) {
  if (user.isAdmin) {
    if (path == AppRoutes.userHome || path == AppRoutes.ownerHome) {
      return AppRoutes.adminDashboard;
    }
    return null;
  }
  if (user.isOwner) {
    if (path == AppRoutes.userHome || path == AppRoutes.adminDashboard) {
      return AppRoutes.ownerHome;
    }
    return null;
  }
  if (path == AppRoutes.ownerHome || path == AppRoutes.adminDashboard) {
    return AppRoutes.userHome;
  }
  return null;
}

const _shellPaths = {
  AppRoutes.userHome,
  AppRoutes.ownerHome,
  AppRoutes.adminDashboard,
};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(authRouterRefreshProvider);
  final auth = ref.read(authProvider);
  final onboardingComplete = ref.read(onboardingCompleteProvider);
  final initialLocation = _initialLocation(auth, onboardingComplete);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final onboardingComplete = ref.read(onboardingCompleteProvider);
      final path = state.uri.path;

      if (auth.bootstrapping) {
        return path == AppRoutes.splash ? null : AppRoutes.splash;
      }

      const publicPaths = {
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.registerUser,
        AppRoutes.registerOwner,
      };

      if (!auth.isLoggedIn) {
        if (!onboardingComplete) {
          if (path == AppRoutes.splash || path == AppRoutes.onboarding) return null;
          return AppRoutes.onboarding;
        }
        if (auth.hasStoredToken && path == AppRoutes.userHome) return null;
        if (auth.hasStoredToken && path.startsWith('/field/')) return null;
        if (_shellPaths.contains(path)) return AppRoutes.welcome;
        if (path == AppRoutes.onboarding) return AppRoutes.welcome;
        if (path.startsWith('/field/')) return AppRoutes.login;
        return publicPaths.contains(path) ? null : AppRoutes.welcome;
      }

      final user = auth.user!;

      if (path == AppRoutes.splash || _isAuthEntryPath(path)) {
        return _homeFor(user);
      }

      final roleRedirect = _roleShellGuard(user, path);
      if (roleRedirect != null) return roleRedirect;

      if (user.isAdmin && publicPaths.contains(path)) {
        return AppRoutes.adminDashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => riyadaTransitionPage(child: const SplashScreen(), state: s),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => riyadaTransitionPage(child: const OnboardingScreen(), state: s),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => riyadaTransitionPage(child: const WelcomeScreen(), state: s),
      ),
      GoRoute(
        path: AppRoutes.login,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => riyadaTransitionPage(child: const LoginScreen(), state: s, fromBottom: true),
      ),
      GoRoute(
        path: AppRoutes.registerUser,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => riyadaTransitionPage(child: const RegisterUserScreen(), state: s, fromBottom: true),
      ),
      GoRoute(
        path: AppRoutes.registerOwner,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => riyadaTransitionPage(child: const RegisterOwnerScreen(), state: s, fromBottom: true),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => MainWrapper(shellRouteChild: child),
        routes: [
          GoRoute(
            path: AppRoutes.userHome,
            pageBuilder: (c, s) => noTransitionPage(child: const SizedBox.shrink(), state: s),
          ),
          GoRoute(
            path: AppRoutes.ownerHome,
            pageBuilder: (c, s) => noTransitionPage(child: const SizedBox.shrink(), state: s),
          ),
          GoRoute(
            path: AppRoutes.adminDashboard,
            pageBuilder: (c, s) => noTransitionPage(child: const SizedBox.shrink(), state: s),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.ownerDashboard,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => riyadaTransitionPage(child: const OwnerDashboardScreen(), state: s, fromBottom: true),
      ),
      GoRoute(
        path: AppRoutes.ownerCommissionCheckout,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) =>
            riyadaTransitionPage(child: const OwnerCommissionCheckoutScreen(), state: s, fromBottom: true),
      ),
      GoRoute(
        path: AppRoutes.profile,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => riyadaTransitionPage(child: const ProfileScreen(), state: s, fromBottom: true),
      ),
      GoRoute(
        path: AppRoutes.addField,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => riyadaTransitionPage(child: const AddFieldScreen(), state: s, fromBottom: true),
      ),
      GoRoute(
        path: AppRoutes.bookingHistory,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => riyadaTransitionPage(child: const BookingHistoryScreen(), state: s, fromBottom: true),
      ),
      GoRoute(
        path: AppRoutes.penaltyShootout,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => riyadaTransitionPage(child: const PenaltyMenuScreen(), state: s, fromBottom: true),
      ),
      GoRoute(
        path: AppRoutes.penaltyFlame,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => riyadaTransitionPage(child: const PenaltyFlameBridgeScreen(), state: s, fromBottom: true),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => riyadaTransitionPage(child: const NotificationsScreen(), state: s, fromBottom: true),
      ),
      GoRoute(
        path: AppRoutes.paymentMethods,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (c, s) => riyadaTransitionPage(child: const PaymentMethodsScreen(), state: s, fromBottom: true),
      ),
      GoRoute(
        path: AppRoutes.bookingCheckout,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final args = state.extra as BookingCheckoutArgs?;
          if (args == null) {
            return riyadaTransitionPage(
              child: const _NavigationErrorScreen(message: 'بيانات الدفع غير متوفرة'),
              state: state,
            );
          }
          return riyadaTransitionPage(
            child: UserBookingCheckoutScreen(args: args),
            state: state,
            fromBottom: true,
          );
        },
      ),
      GoRoute(
        path: '/field/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return riyadaTransitionPage(
              child: const _NavigationErrorScreen(message: 'تعذّر فتح الملعب'),
              state: state,
            );
          }
          final extra = state.extra;
          return riyadaTransitionPage(
            child: FieldDetailRouteScreen(
              fieldId: id,
              initialField: extra is Field ? extra : null,
            ),
            state: state,
            fromBottom: true,
          );
        },
      ),
    ],
  );
});

class _NavigationErrorScreen extends StatelessWidget {
  const _NavigationErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.welcome),
                child: const Text('رجوع'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
