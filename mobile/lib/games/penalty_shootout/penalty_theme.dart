import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../../theme/riyada_theme_extension.dart';

/// ألوان الملعب والمرمى — تتبع الثيم الحالي تلقائياً.
class PenaltyPalette {
  PenaltyPalette(BuildContext context)
      : c = context.colors,
        isDark = context.isDarkMode;

  final RiyadaColors c;
  final bool isDark;

  Color get scaffold => c.background.withValues(alpha: 0.92);

  Color get pitchTop => isDark ? c.primaryLight.withValues(alpha: 0.32) : DesignTokens.neonGreen.withValues(alpha: 0.22);

  Color get pitchBottom => isDark ? c.primary.withValues(alpha: 0.82) : DesignTokens.primary.withValues(alpha: 0.5);

  Color get goalPost => isDark ? c.onInverse : c.onSurface;

  Color get goalNet => goalPost.withValues(alpha: isDark ? 0.18 : 0.12);

  Color get ballFill => isDark ? c.onInverse : Colors.white;

  Color get ballIcon => isDark ? c.onSurface : c.primaryDark;

  Color get ballBorder => c.outlineVariant;

  Color get keeperBody => c.secondary;

  Color get zoneHighlight => c.primary.withValues(alpha: 0.42);

  Color get zoneTap => c.onSurface.withValues(alpha: isDark ? 0.07 : 0.05);

  Color get scoreBoardBg => c.surfaceVariant.withValues(alpha: isDark ? 0.55 : 0.9);

  Color get scoreBoardBorder => c.outline.withValues(alpha: 0.35);

  Color get textPrimary => c.onSurface;

  Color get textMuted => c.onSurfaceVariant;

  Color get accent => c.primary;

  Color get overlayScrim => c.scrimHeavy;

  Color get summaryCard => c.surfaceElevated;
}

/// مسار كرة منحني (قوس) بين نقطتين.
Offset penaltyArcOffset(Offset start, Offset end, double t) {
  final linear = Offset.lerp(start, end, t)!;
  final dist = (end - start).distance;
  final arc = sin(t * pi) * (dist * 0.22 + 28);
  return Offset(linear.dx, linear.dy - arc);
}
