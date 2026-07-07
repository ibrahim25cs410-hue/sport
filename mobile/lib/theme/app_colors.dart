import 'package:flutter/material.dart';

/// ألوان دلالية للنصوص والأسعار — مصدر واحد للوضع الليلي/النهاري.
abstract final class AppColors {
  /// لون السعر — أخضر ثابت في الوضعين.
  static const priceGreen = Color(0xFF22C55E);

  /// @deprecated استخدم [priceGreen].
  static const primaryGreen = priceGreen;

  /// كل النصوص في الوضع الليلي.
  static const textDarkMode = Color(0xFFFFFFFF);

  /// كل النصوص في الوضع النهاري.
  static const textLightMode = Color(0xFF000000);

  static Color typography(Brightness brightness) =>
      brightness == Brightness.dark ? textDarkMode : textLightMode;

  static Color typographyFor(BuildContext context) =>
      typography(Theme.of(context).brightness);
}
