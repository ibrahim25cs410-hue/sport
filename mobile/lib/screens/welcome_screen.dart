import 'package:flutter/material.dart';
import '../router/app_router.dart';
import '../theme/design_tokens.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/l10n_extension.dart';
import '../widgets/common.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return RtlScaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
      ),
      body: BrandGradientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.only(bottom: viewInsets.bottom),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: DesignTokens.spaceLg),
                            const AppLogo(size: 96, light: true),
                            const SizedBox(height: DesignTokens.spaceSm),
                            Text(
                              l10n.taglineLong,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: c.onInverseMuted),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: DesignTokens.spaceLg),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                FeatureChip(icon: Icons.bolt_rounded, label: l10n.featureInstant),
                                FeatureChip(icon: Icons.notifications_active_outlined, label: l10n.featureNotify),
                                FeatureChip(icon: Icons.verified_user_outlined, label: l10n.featureTrusted),
                              ],
                            ),
                            const SizedBox(height: DesignTokens.spaceLg),
                          ],
                        ),
                      ),
                      RiyadaBottomPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.startNow,
                              style: Theme.of(context).textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.chooseAccountType,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: DesignTokens.spaceLg),
                            FilledButton.icon(
                              onPressed: () => context.goRegisterUser(),
                              icon: const Icon(Icons.person_add_rounded),
                              label: Text(l10n.registerUserCta),
                            ),
                            const SizedBox(height: DesignTokens.spaceSm),
                            OutlinedButton.icon(
                              onPressed: () => context.goRegisterOwner(),
                              icon: const Icon(Icons.storefront_rounded),
                              label: Text(l10n.registerOwnerCta),
                            ),
                            const SizedBox(height: DesignTokens.spaceMd),
                            TextButton(
                              onPressed: () => context.goLogin(),
                              child: Text(l10n.alreadyHaveAccount),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
