import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../../theme/riyada_motion.dart';
import '../../theme/riyada_theme_extension.dart';

/// إطار أيقونة موحّد — دائري ناعم مع ظل خفيف وحركة اختيار.
class RiyadaIconBadge extends StatelessWidget {
  const RiyadaIconBadge({
    super.key,
    required this.child,
    this.size = RiyadaIconBadgeSize.md,
    this.gradient = true,
    this.selected = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  final Widget child;
  final RiyadaIconBadgeSize size;
  final bool gradient;
  final bool selected;
  final Color? backgroundColor;
  final Color? foregroundColor;

  double get _dim => switch (size) {
        RiyadaIconBadgeSize.sm => 40,
        RiyadaIconBadgeSize.md => 48,
        RiyadaIconBadgeSize.lg => 56,
      };

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;
    final fill = backgroundColor ??
        (gradient
            ? null
            : accent.withValues(alpha: selected ? 0.22 : 0.12));

    return AnimatedScale(
      scale: selected ? 1.06 : 1.0,
      duration: RiyadaMotion.fast,
      curve: RiyadaMotion.standardCurve,
      child: AnimatedContainer(
        duration: RiyadaMotion.medium,
        curve: RiyadaMotion.standardCurve,
        width: _dim,
        height: _dim,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient && fill == null ? DesignTokens.neonGradient : null,
          color: fill,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: selected ? 0.28 : 0.14),
              blurRadius: selected ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: context.isDarkMode ? 0.12 : 0.35),
            width: 1,
          ),
        ),
        child: IconTheme(
          data: IconThemeData(
            color: foregroundColor ?? DesignTokens.onNeon,
            size: _dim * 0.48,
          ),
          child: child,
        ),
      ),
    );
  }
}

enum RiyadaIconBadgeSize { sm, md, lg }
