import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// خطوط العلامة: Cairo للعربية، Inter للإنجليزية.
abstract final class AppTypography {
  static bool isArabic(Locale? locale) => locale?.languageCode == 'ar';

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
    return isArabic(locale) ? GoogleFonts.cairoTextTheme(base) : GoogleFonts.interTextTheme(base);
  }

  static TextStyle appBarTitle(Brightness brightness, [Locale? locale]) {
    final textColor = AppColors.typography(brightness);
    return isArabic(locale)
        ? GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)
        : GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: textColor);
  }
}
