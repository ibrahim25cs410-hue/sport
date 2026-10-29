import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography uses the platform font so authentication remains usable offline.
abstract final class AppTypography {
  static TextTheme textTheme(Brightness brightness, [Locale? locale]) {
    final textColor = AppColors.typography(brightness);
    final base = TextTheme(
      displaySmall: TextStyle(fontWeight: FontWeight.w800, fontSize: 36, height: 1.15, color: textColor, letterSpacing: -0.5),
      displayMedium: TextStyle(fontWeight: FontWeight.w800, fontSize: 32, height: 1.15, color: textColor),
      displayLarge: TextStyle(fontWeight: FontWeight.w800, fontSize: 40, height: 1.1, color: textColor),
      headlineLarge: TextStyle(fontWeight: FontWeight.w800, fontSize: 32, height: 1.2, color: textColor),
      headlineMedium: TextStyle(fontWeight: FontWeight.w700, fontSize: 24, height: 1.25, color: textColor),
      headlineSmall: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: textColor),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: textColor),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textColor),
      titleSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: textColor),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: textColor),
      bodySmall: TextStyle(fontSize: 12, height: 1.4, color: textColor),
      labelLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2, color: textColor),
      labelMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor),
      labelSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 0.3, color: textColor),
    );
    return base;
  }

  static TextStyle appBarTitle(Brightness brightness, [Locale? locale]) {
    final textColor = AppColors.typography(brightness);
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: textColor,
    );
  }
}
