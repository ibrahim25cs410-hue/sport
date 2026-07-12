import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../../theme/riyada_theme_extension.dart';

/// ألوان الملعب والمرمى — مظهر واقعي (سماء، عشب، مرمى).
class PenaltyPalette {
  PenaltyPalette(BuildContext context)
      : c = context.colors,
        isDark = context.isDarkMode;

  final RiyadaColors c;
  final bool isDark;

  Color get scaffold => c.background.withValues(alpha: 0.92);

  Color get skyTop => isDark ? const Color(0xFF0B1A2E) : const Color(0xFF6EC6FF);
  Color get skyHorizon => isDark ? const Color(0xFF1A3A4A) : const Color(0xFFB8E0F5);

  Color get grassLight => isDark ? const Color(0xFF1B5E20) : const Color(0xFF4CAF50);
  Color get grassDark => isDark ? const Color(0xFF0D3B12) : const Color(0xFF2E7D32);
  Color get grassDeep => isDark ? const Color(0xFF06280A) : const Color(0xFF1B5E20);

  Color get pitchTop => grassLight;
  Color get pitchBottom => grassDeep;

  Color get lineWhite => Colors.white.withValues(alpha: isDark ? 0.55 : 0.75);

  Color get goalPost => isDark ? const Color(0xFFF5F5F5) : const Color(0xFFFAFAFA);
  Color get goalPostShadow => Colors.black.withValues(alpha: 0.35);
  Color get goalNet => Colors.white.withValues(alpha: isDark ? 0.22 : 0.28);
  Color get goalNetBack => Colors.black.withValues(alpha: 0.18);

  Color get ballFill => Colors.white;
  Color get ballIcon => const Color(0xFF212121);
  Color get ballBorder => const Color(0xFF9E9E9E);

  Color get keeperBody => c.secondary;

  Color get zoneHighlight => DesignTokens.primaryTeal.withValues(alpha: 0.45);
  Color get zoneTap => Colors.white.withValues(alpha: isDark ? 0.08 : 0.1);

  Color get scoreBoardBg => c.surfaceVariant.withValues(alpha: isDark ? 0.55 : 0.9);
  Color get scoreBoardBorder => c.outline.withValues(alpha: 0.35);

  Color get textPrimary => c.onSurface;
  Color get textMuted => c.onSurfaceVariant;
  Color get accent => DesignTokens.primaryTeal;
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
