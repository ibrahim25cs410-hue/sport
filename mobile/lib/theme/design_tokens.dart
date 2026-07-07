import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'riyada_brand_colors.dart';

/// Design Tokens — مصدر واحد للألوان والمسافات والظلال.
abstract final class DesignTokens {
  // ── Brand identity (Riyada logo 2026) ──
  static const primaryTeal = RiyadaBrandColors.primaryTeal;
  static const secondaryMint = RiyadaBrandColors.secondaryMint;
  static const scaffoldNavy = RiyadaBrandColors.scaffoldNavy;
  static const surfaceSlate = RiyadaBrandColors.surfaceSlate;

  static const navyBlue = scaffoldNavy;
  static const limeGreen = primaryTeal;
  /// @deprecated Use [primaryTeal] — kept for gradual migration.
  static const neonGreen = primaryTeal;
  static const secondaryNeon = secondaryMint;
  static const onNeon = RiyadaBrandColors.onSecondary;
  static const priceGreen = AppColors.priceGreen;
  static const sportAccent = primaryTeal;
  static const textPrimary = AppColors.textDarkMode;
  static const textSecondary = AppColors.textDarkMode;
  static const cardDark = surfaceSlate;

  // ── Brand (semantic) ──
  static const primary = primaryTeal;
  static const primaryLight = secondaryMint;
  static const primaryDark = scaffoldNavy;
  static const secondary = surfaceSlate;
  static const accent = secondaryMint;
  static const accentMuted = Color(0xFF66EDD4);

  // ── Semantic ──
  static const success = primaryTeal;
  static const warning = Color(0xFFB45309);
  static const warningSurface = Color(0xFFEA580C);
  static const error = Color(0xFFDC2626);
  static const info = Color(0xFF1D4ED8);
  static const neutral = Color(0xFF64748B);

  // ── On-color ──
  static const onPrimary = RiyadaBrandColors.onPrimary;
  static const onInverse = RiyadaBrandColors.onSurfaceWhite;
  static const onInverseMuted = Color(0xFF99F0E0);
  static const onAccent = RiyadaBrandColors.onSecondary;

  // ── Overlays & shadows ──
  static const scrimLight = Color(0x33000000);
  static const scrimMedium = Color(0x66000000);
  static const scrimHeavy = Color(0x99000000);
  static const shadow = Color(0x0F00B494);
  static const shadowStrong = Color(0x1F00B494);
  static const glassBorder = Color(0x33FFFFFF);

  // ── Light mode surfaces ──
  static const lightBackground = Color(0xFFF0FAF5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFF1F5F9);
  static const lightSurfaceElevated = Color(0xFFFFFFFF);
  static const lightOnSurface = AppColors.textLightMode;
  static const lightOnSurfaceVariant = AppColors.textLightMode;
  static const lightOutline = Color(0xFFCBD5E1);
  static const lightOutlineVariant = Color(0xFFE2E8F0);

  // ── Dark mode premium (logo palette) ──
  static const darkBackground = scaffoldNavy;
  static const darkSurface = surfaceSlate;
  static const darkSurfaceVariant = Color(0xFF1A3558);
  static const darkSurfaceElevated = RiyadaBrandColors.surfaceSlateElevated;
  static const darkOnSurface = textPrimary;
  static const darkOnSurfaceVariant = textSecondary;
  static const darkOutline = Color(0xFF2A4568);
  static const darkOutlineVariant = Color(0xFF1E3A5C);

  // ── Gradients ──
  static const brandGradient = RiyadaBrandColors.brandGradient;

  static const neonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryTeal, secondaryMint],
  );

  static const heroGradient = RiyadaBrandColors.heroGradient;

  /// Ambient navy/teal background for the app shell.
  static LinearGradient ambientBackgroundGradient(bool isDark) =>
      RiyadaBrandColors.ambientBackgroundGradient(isDark);

  static const stadiumNightGradient = [scaffoldNavy, surfaceSlate];

  static const fieldGradients = [
    [Color(0xFF0B0F14), Color(0xFF1E5631)],
    [Color(0xFF0F766E), Color(0xFF2DD4BF)],
    [Color(0xFF1E3A5F), Color(0xFF3B82F6)],
    [Color(0xFF4C1D95), Color(0xFF8B5CF6)],
    [Color(0xFF78350F), Color(0xFFF59E0B)],
  ];

  // ── Radius (20–30px premium) ──
  static const radiusXs = 10.0;
  static const radiusSm = 14.0;
  static const radiusMd = 18.0;
  static const radiusLg = 22.0;
  static const radiusXl = 24.0;
  static const radius2xl = 28.0;
  static const navBarRadius = radius2xl;
  static const navIconStroke = 1.75;
  static const radius3xl = 30.0;

  // ── Spacing ──
  static const spaceXs = 4.0;
  static const spaceSm = 8.0;
  static const spaceMd = 12.0;
  static const spaceLg = 16.0;
  static const spaceXl = 24.0;
  static const space2xl = 32.0;

  static Color glassFill([double opacity = 0.12]) =>
      Colors.white.withValues(alpha: opacity);

  static LinearGradient gradientFor(int seed) {
    final g = fieldGradients[seed.abs() % fieldGradients.length];
    return LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: g,
    );
  }

  static List<BoxShadow> cardShadow(Color tint, {bool elevated = false}) => [
        BoxShadow(
          color: tint.withValues(alpha: elevated ? 0.22 : 0.12),
          blurRadius: elevated ? 28 : 18,
          offset: Offset(0, elevated ? 12 : 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> glowShadow(Color tint, {bool elevated = false, bool subtle = false}) => [
        BoxShadow(
          color: tint.withValues(alpha: subtle ? 0.15 : (elevated ? 0.35 : 0.25)),
          blurRadius: elevated ? 32 : 20,
          spreadRadius: subtle ? 0 : 1,
        ),
      ];

  static List<BoxShadow> navBarShadow(Color tint) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.1),
          blurRadius: 24,
          offset: const Offset(0, -6),
        ),
      ];
}
