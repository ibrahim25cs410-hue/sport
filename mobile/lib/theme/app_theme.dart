import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/error_messages.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'design_tokens.dart';
import 'riyada_theme_extension.dart';

/// واجهة توافق — تفويض إلى Design Tokens.
abstract final class AppTheme {
  static const primary = DesignTokens.primary;
  static const primaryGreen = AppColors.primaryGreen;
  static const primaryLight = DesignTokens.primaryLight;
  static const primaryDark = DesignTokens.primaryDark;
  static const accent = DesignTokens.accent;
  static const surface = DesignTokens.lightBackground;
  static const cardBg = DesignTokens.lightSurface;
  static const textSecondary = DesignTokens.lightOnSurfaceVariant;
  static const error = DesignTokens.error;
  static const success = DesignTokens.success;
  static const darkSurface = DesignTokens.darkBackground;
  static const darkCard = DesignTokens.darkSurface;
  static const darkTextSecondary = DesignTokens.darkOnSurfaceVariant;

  static LinearGradient gradientFor(int seed) => DesignTokens.gradientFor(seed);

  static ThemeData get light => forLocale(Brightness.light, const Locale('ar'));
  static ThemeData get dark => forLocale(Brightness.dark, const Locale('ar'));

  static final Map<String, ThemeData> _cache = {};

  static ThemeData forLocale(Brightness brightness, Locale locale) {
    final key = '${brightness.name}_${locale.languageCode}';
    return _cache.putIfAbsent(key, () => _build(brightness, locale));
  }

  static ThemeData _build(Brightness brightness, [Locale? locale]) {
    final isDark = brightness == Brightness.dark;
    final tokens = isDark ? RiyadaColors.dark : RiyadaColors.light;
    final textColor = AppColors.typography(brightness);
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      primaryContainer: tokens.primary.withValues(alpha: isDark ? 0.22 : 0.12),
      onPrimaryContainer: textColor,
      secondary: tokens.secondary,
      onSecondary: tokens.onPrimary,
      secondaryContainer: tokens.secondary.withValues(alpha: 0.15),
      onSecondaryContainer: textColor,
      tertiary: tokens.accent,
      onTertiary: tokens.onAccent,
      tertiaryContainer: tokens.accent.withValues(alpha: 0.18),
      onTertiaryContainer: textColor,
      error: tokens.error,
      onError: tokens.onPrimary,
      errorContainer: tokens.error.withValues(alpha: 0.12),
      onErrorContainer: tokens.error,
      surface: tokens.surface,
      onSurface: textColor,
      surfaceContainerHighest: tokens.surfaceVariant,
      onSurfaceVariant: textColor,
      outline: tokens.outline,
      outlineVariant: tokens.outlineVariant,
      shadow: tokens.shadow,
      scrim: tokens.scrimMedium,
      inverseSurface: tokens.primaryDark,
      onInverseSurface: tokens.onInverse,
      inversePrimary: tokens.primaryLight,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: [tokens],
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    final textTheme = AppTypography.textTheme(brightness, locale).apply(
      bodyColor: textColor,
      displayColor: textColor,
    );

    final shapeMd = RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd));
    final shapeLg = RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusLg));

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surface,
        foregroundColor: textColor,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.appBarTitle(brightness, locale),
        iconTheme: IconThemeData(color: textColor, size: 22),
        actionsIconTheme: IconThemeData(color: textColor, size: 22),
        shape: isDark
            ? null
            : const Border(bottom: BorderSide(color: DesignTokens.lightOutlineVariant, width: 1)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: tokens.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: tokens.shadow,
        indicatorColor: tokens.primary.withValues(alpha: isDark ? 0.28 : 0.14),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? tokens.primary : textColor,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? tokens.primary : textColor,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: DesignTokens.onNeon,
          disabledBackgroundColor: tokens.primary.withValues(alpha: 0.35),
          disabledForegroundColor: tokens.onPrimary.withValues(alpha: 0.7),
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceXl, vertical: DesignTokens.spaceMd),
          shape: shapeMd,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.surfaceElevated,
          foregroundColor: tokens.primary,
          elevation: 0,
          shadowColor: tokens.shadow,
          minimumSize: const Size(0, 48),
          shape: shapeMd,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.primary,
          minimumSize: const Size(double.infinity, 54),
          side: BorderSide(color: tokens.primary.withValues(alpha: 0.55), width: 1.5),
          shape: shapeMd,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textColor,
          highlightColor: tokens.onPrimary.withValues(alpha: 0.12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: tokens.shadowStrong,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
        titleTextStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: textColor),
        contentTextStyle: TextStyle(fontSize: 14, height: 1.5, color: textColor),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radius2xl)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(color: tokens.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(color: tokens.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(color: tokens.error.withValues(alpha: 0.7)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(color: tokens.error, width: 2),
        ),
        filled: true,
        fillColor: isDark ? tokens.surfaceVariant : tokens.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: 15),
        labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: textColor),
        prefixIconColor: textColor,
        suffixIconColor: textColor,
      ),
      cardTheme: CardThemeData(
        color: tokens.card,
        elevation: isDark ? 0 : 1,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          side: BorderSide(color: tokens.outlineVariant.withValues(alpha: isDark ? 0.5 : 0.65)),
        ),
        shadowColor: isDark ? tokens.shadow : Colors.black.withValues(alpha: 0.06),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.primaryLight,
        textColor: textColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
        shape: shapeLg,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceVariant,
        selectedColor: tokens.primary,
        disabledColor: tokens.surfaceVariant.withValues(alpha: 0.5),
        checkmarkColor: tokens.onPrimary,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor),
        secondaryLabelStyle: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm, vertical: DesignTokens.spaceXs),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
        side: BorderSide(color: tokens.outlineVariant),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: tokens.accent,
        textColor: tokens.onAccent,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
        backgroundColor: isDark ? tokens.surfaceElevated : tokens.primaryDark,
        contentTextStyle: const TextStyle(color: DesignTokens.onInverse, fontWeight: FontWeight.w500),
      ),
      dividerTheme: DividerThemeData(color: tokens.outlineVariant, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: tokens.primary,
        linearTrackColor: tokens.surfaceVariant,
        circularTrackColor: tokens.surfaceVariant,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? tokens.primaryLight : null),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? tokens.primaryLight.withValues(alpha: 0.4) : null,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: tokens.primary,
        foregroundColor: tokens.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusLg)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

void showAppSnackBar(BuildContext context, Object message, {bool isError = false}) {
  final c = context.colors;
  final text = isError ? friendlyErrorMessage(message) : message.toString();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: c.onPrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: c.onPrimary, fontWeight: FontWeight.w500))),
        ],
      ),
      backgroundColor: isError ? c.error : c.primaryDark,
      duration: Duration(seconds: isError ? 4 : 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
      margin: const EdgeInsets.all(DesignTokens.spaceLg),
    ),
  );
}

void showAppWarningSnackBar(BuildContext context, String message) {
  final c = context.colors;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(color: c.onPrimary, fontWeight: FontWeight.w600)),
      backgroundColor: c.warningSurface,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusSm)),
      margin: const EdgeInsets.all(DesignTokens.spaceLg),
    ),
  );
}

void showAppError(BuildContext context, Object error) =>
    showAppSnackBar(context, error, isError: true);

Color themedCardColor(BuildContext context) => context.colors.card;

Color themedSecondaryText(BuildContext context) => Theme.of(context).colorScheme.onSurface;
