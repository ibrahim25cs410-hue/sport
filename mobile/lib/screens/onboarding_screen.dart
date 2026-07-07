import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router/app_router.dart';
import '../theme/design_tokens.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/l10n_extension.dart';
import '../widgets/common.dart';
import 'splash_screen.dart' show completeOnboarding;

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(Icons.stadium_rounded, DesignTokens.heroGradient),
    _OnboardPage(Icons.event_available_rounded, null),
    _OnboardPage(Icons.notifications_active_rounded, null),
  ];

  Future<void> _finish() async {
    await completeOnboarding(ref);
    if (!mounted) return;
    context.goWelcome();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final titles = [l10n.onboardTitle1, l10n.onboardTitle2, l10n.onboardTitle3];
    final bodies = [l10n.onboardBody1, l10n.onboardBody2, l10n.onboardBody3];

    return RtlScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _finish,
                child: Text(l10n.onboardSkip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: titles.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space2xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: page.gradient ?? DesignTokens.brandGradient,
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: DesignTokens.cardShadow(c.primary, elevated: true),
                          ),
                          child: Icon(page.icon, size: 56, color: c.onInverse),
                        ),
                        const SizedBox(height: DesignTokens.space2xl),
                        Text(titles[i], style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                        const SizedBox(height: DesignTokens.spaceMd),
                        Text(bodies[i], style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                titles.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? c.primary : c.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceXl),
              child: FilledButton(
                onPressed: () {
                  if (_page < titles.length - 1) {
                    _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
                  } else {
                    _finish();
                  }
                },
                child: Text(_page < titles.length - 1 ? l10n.onboardNext : l10n.onboardStart),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage {
  const _OnboardPage(this.icon, this.gradient);
  final IconData icon;
  final Gradient? gradient;
}
