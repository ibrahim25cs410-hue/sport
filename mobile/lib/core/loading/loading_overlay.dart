import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';
import '../../theme/riyada_brand_colors.dart';
import 'global_loading_provider.dart';

/// Full-screen semi-transparent veil with a centered progress indicator.
class LoadingOverlay extends ConsumerWidget {
  const LoadingOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(globalLoadingProvider);
    final theme = Theme.of(context);
    final textColor = AppColors.typographyFor(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (loading.isVisible)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: ColoredBox(
                color: RiyadaBrandColors.scaffoldNavy.withValues(alpha: 0.55),
                child: Center(
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    color: RiyadaBrandColors.surfaceSlate.withValues(alpha: 0.96),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spaceXl,
                        vertical: DesignTokens.spaceLg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: RiyadaBrandColors.primaryTeal,
                            ),
                          ),
                          if (loading.message != null) ...[
                            const SizedBox(height: DesignTokens.spaceMd),
                            Text(
                              loading.message!,
                              style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
