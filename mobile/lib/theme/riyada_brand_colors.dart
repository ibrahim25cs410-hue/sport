import 'package:flutter/material.dart';

/// RIYADA shared brand palette: black, white and sport green.
abstract final class RiyadaBrandColors {
  static const primaryTeal = Color(0xFF16A34A);
  static const secondaryMint = Color(0xFF4ADE80);
  static const scaffoldNavy = Color(0xFF080A09);
  static const surfaceSlate = Color(0xFF141715);
  static const surfaceSlateElevated = Color(0xFF202521);
  static const onSurfaceWhite = Color(0xFFFFFFFF);
  static const onSurfaceMuted = Color(0xFFA3ADA5);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onSecondary = Color(0xFF07130A);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryTeal, secondaryMint],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [scaffoldNavy, surfaceSlate, Color(0xFF174A2B)],
    stops: [0.0, 0.58, 1.0],
  );

  static LinearGradient ambientBackgroundGradient(bool isDark) =>
      LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: isDark
            ? [scaffoldNavy, const Color(0xFF0D120F), const Color(0xFF111A13)]
            : [const Color(0xFFF0F7F1), const Color(0xFFF8FAF8), const Color(0xFFFFFFFF)],
        stops: const [0.0, 0.55, 1.0],
      );
}
