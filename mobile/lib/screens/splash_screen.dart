import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../router/app_router.dart';
import '../services/onboarding_service.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/l10n_extension.dart';
import '../widgets/common.dart';

/// Branded splash — routes to home, welcome, or onboarding after bootstrap.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final onboardingDone = ref.watch(onboardingCompleteProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted || auth.bootstrapping) return;
      if (auth.isLoggedIn) {
        final user = auth.user!;
        context.goHomeAfterAuth(isAdmin: user.isAdmin, isOwner: user.isOwner);
        return;
      }
      if (!onboardingDone) {
        context.goOnboarding();
        return;
      }
      context.goWelcomeClearStack();
    });

    final l10n = context.l10n;
    final c = context.colors;
    return Scaffold(
      body: BrandGradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const RiyadaLogo(variant: RiyadaLogoVariant.splash, size: 180, light: true),
              const SizedBox(height: 12),
              Text(l10n.appTagline, style: TextStyle(color: c.onInverseMuted, fontSize: 15)),
              const SizedBox(height: 24),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(color: c.onInverse, strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Marks onboarding complete and updates app state.
Future<void> completeOnboarding(WidgetRef ref) async {
  await OnboardingService().markComplete();
  ref.read(onboardingCompleteProvider.notifier).state = true;
}
