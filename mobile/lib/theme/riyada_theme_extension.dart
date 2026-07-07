import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'design_tokens.dart';

/// ألوان دلالية تُقرأ من Theme — بدلاً من قيم صلبة في المكوّنات.
@immutable
class RiyadaColors extends ThemeExtension<RiyadaColors> {
  const RiyadaColors({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.accent,
    required this.accentMuted,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceElevated,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.success,
    required this.warning,
    required this.warningSurface,
    required this.error,
    required this.info,
    required this.neutral,
    required this.onPrimary,
    required this.onAccent,
    required this.onInverse,
    required this.onInverseMuted,
    required this.scrimLight,
    required this.scrimMedium,
    required this.scrimHeavy,
    required this.shadow,
    required this.shadowStrong,
    required this.card,
  });

  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color accent;
  final Color accentMuted;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceElevated;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color success;
  final Color warning;
  final Color warningSurface;
  final Color error;
  final Color info;
  final Color neutral;
  final Color onPrimary;
  final Color onAccent;
  final Color onInverse;
  final Color onInverseMuted;
  final Color scrimLight;
  final Color scrimMedium;
  final Color scrimHeavy;
  final Color shadow;
  final Color shadowStrong;
  final Color card;

  static const light = RiyadaColors(
    primary: DesignTokens.primaryTeal,
    primaryLight: DesignTokens.secondaryMint,
    primaryDark: DesignTokens.scaffoldNavy,
    secondary: DesignTokens.secondary,
    accent: DesignTokens.accent,
    accentMuted: DesignTokens.accentMuted,
    background: DesignTokens.lightBackground,
    surface: DesignTokens.lightSurface,
    surfaceVariant: DesignTokens.lightSurfaceVariant,
    surfaceElevated: DesignTokens.lightSurfaceElevated,
    onSurface: AppColors.textLightMode,
    onSurfaceVariant: AppColors.textLightMode,
    outline: DesignTokens.lightOutline,
    outlineVariant: DesignTokens.lightOutlineVariant,
    success: DesignTokens.success,
    warning: DesignTokens.warning,
    warningSurface: DesignTokens.warningSurface,
    error: DesignTokens.error,
    info: DesignTokens.info,
    neutral: DesignTokens.neutral,
    onPrimary: DesignTokens.onPrimary,
    onAccent: DesignTokens.onAccent,
    onInverse: DesignTokens.onInverse,
    onInverseMuted: DesignTokens.onInverseMuted,
    scrimLight: DesignTokens.scrimLight,
    scrimMedium: DesignTokens.scrimMedium,
    scrimHeavy: DesignTokens.scrimHeavy,
    shadow: Color(0x1A84CC16),
    shadowStrong: Color(0x3384CC16),
    card: DesignTokens.lightSurface,
  );

  static const dark = RiyadaColors(
    primary: DesignTokens.primaryTeal,
    primaryLight: DesignTokens.secondaryMint,
    primaryDark: DesignTokens.scaffoldNavy,
    secondary: DesignTokens.surfaceSlate,
    accent: DesignTokens.secondaryMint,
    accentMuted: DesignTokens.accentMuted,
    background: DesignTokens.scaffoldNavy,
    surface: DesignTokens.surfaceSlate,
    surfaceVariant: DesignTokens.darkSurfaceVariant,
    surfaceElevated: DesignTokens.darkSurfaceElevated,
    onSurface: DesignTokens.textPrimary,
    onSurfaceVariant: DesignTokens.textPrimary,
    outline: DesignTokens.darkOutline,
    outlineVariant: DesignTokens.darkOutlineVariant,
    success: DesignTokens.success,
    warning: DesignTokens.warningSurface,
    warningSurface: DesignTokens.warningSurface,
    error: DesignTokens.error,
    info: DesignTokens.info,
    neutral: DesignTokens.neutral,
    onPrimary: DesignTokens.onPrimary,
    onAccent: DesignTokens.onAccent,
    onInverse: DesignTokens.onInverse,
    onInverseMuted: DesignTokens.onInverseMuted,
    scrimLight: DesignTokens.scrimLight,
    scrimMedium: DesignTokens.scrimMedium,
    scrimHeavy: DesignTokens.scrimHeavy,
    shadow: DesignTokens.shadow,
    shadowStrong: DesignTokens.shadowStrong,
    card: DesignTokens.surfaceSlate,
  );

  @override
  RiyadaColors copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? secondary,
    Color? accent,
    Color? accentMuted,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceElevated,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? outline,
    Color? outlineVariant,
    Color? success,
    Color? warning,
    Color? warningSurface,
    Color? error,
    Color? info,
    Color? neutral,
    Color? onPrimary,
    Color? onAccent,
    Color? onInverse,
    Color? onInverseMuted,
    Color? scrimLight,
    Color? scrimMedium,
    Color? scrimHeavy,
    Color? shadow,
    Color? shadowStrong,
    Color? card,
  }) =>
      RiyadaColors(
        primary: primary ?? this.primary,
        primaryLight: primaryLight ?? this.primaryLight,
        primaryDark: primaryDark ?? this.primaryDark,
        secondary: secondary ?? this.secondary,
        accent: accent ?? this.accent,
        accentMuted: accentMuted ?? this.accentMuted,
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceVariant: surfaceVariant ?? this.surfaceVariant,
        surfaceElevated: surfaceElevated ?? this.surfaceElevated,
        onSurface: onSurface ?? this.onSurface,
        onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
        outline: outline ?? this.outline,
        outlineVariant: outlineVariant ?? this.outlineVariant,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        warningSurface: warningSurface ?? this.warningSurface,
        error: error ?? this.error,
        info: info ?? this.info,
        neutral: neutral ?? this.neutral,
        onPrimary: onPrimary ?? this.onPrimary,
        onAccent: onAccent ?? this.onAccent,
        onInverse: onInverse ?? this.onInverse,
        onInverseMuted: onInverseMuted ?? this.onInverseMuted,
        scrimLight: scrimLight ?? this.scrimLight,
        scrimMedium: scrimMedium ?? this.scrimMedium,
        scrimHeavy: scrimHeavy ?? this.scrimHeavy,
        shadow: shadow ?? this.shadow,
        shadowStrong: shadowStrong ?? this.shadowStrong,
        card: card ?? this.card,
      );

  @override
  RiyadaColors lerp(ThemeExtension<RiyadaColors>? other, double t) {
    if (other is! RiyadaColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return RiyadaColors(
      primary: l(primary, other.primary),
      primaryLight: l(primaryLight, other.primaryLight),
      primaryDark: l(primaryDark, other.primaryDark),
      secondary: l(secondary, other.secondary),
      accent: l(accent, other.accent),
      accentMuted: l(accentMuted, other.accentMuted),
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceVariant: l(surfaceVariant, other.surfaceVariant),
      surfaceElevated: l(surfaceElevated, other.surfaceElevated),
      onSurface: l(onSurface, other.onSurface),
      onSurfaceVariant: l(onSurfaceVariant, other.onSurfaceVariant),
      outline: l(outline, other.outline),
      outlineVariant: l(outlineVariant, other.outlineVariant),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      warningSurface: l(warningSurface, other.warningSurface),
      error: l(error, other.error),
      info: l(info, other.info),
      neutral: l(neutral, other.neutral),
      onPrimary: l(onPrimary, other.onPrimary),
      onAccent: l(onAccent, other.onAccent),
      onInverse: l(onInverse, other.onInverse),
      onInverseMuted: l(onInverseMuted, other.onInverseMuted),
      scrimLight: l(scrimLight, other.scrimLight),
      scrimMedium: l(scrimMedium, other.scrimMedium),
      scrimHeavy: l(scrimHeavy, other.scrimHeavy),
      shadow: l(shadow, other.shadow),
      shadowStrong: l(shadowStrong, other.shadowStrong),
      card: l(card, other.card),
    );
  }
}

extension RiyadaThemeContext on BuildContext {
  RiyadaColors get colors => Theme.of(this).extension<RiyadaColors>() ?? RiyadaColors.light;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// لون النص الأساسي — أبيض ليلاً، أسود نهاراً.
  Color get typographyColor => AppColors.typographyFor(this);

  /// لون السعر — أخضر ثابت.
  Color get priceColor => AppColors.priceGreen;

  /// لون التمييز للأزرار والتبويبات النشطة.
  Color get accentColor => DesignTokens.primaryTeal;

  /// أيقونات/نص غير نشط — نفس لون النص بشفافية خفيفة للسلاسة البصرية.
  Color get inactiveColor => typographyColor.withValues(alpha: 0.62);

  /// لون تعبئة الزجاج — يتكيف مع الوضع الليلي/النهاري.
  Color get glassFill => isDarkMode ? Colors.white.withValues(alpha: 0.1) : colors.surface.withValues(alpha: 0.94);

  /// حدود الزجاج.
  Color get glassBorder => isDarkMode ? DesignTokens.glassBorder : colors.outline.withValues(alpha: 0.55);

  /// تدرّج البانر المالي — يتكيف مع الوضع الليلي/النهاري.
  LinearGradient get heroBannerGradient {
    final c = colors;
    if (isDarkMode) return DesignTokens.heroGradient;
    return LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [c.primaryDark, c.primary, c.primaryLight],
    );
  }
}
