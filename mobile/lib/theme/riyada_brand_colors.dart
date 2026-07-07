import 'package:flutter/material.dart';

/// Official Riyada brand palette — extracted from the app icon identity.
abstract final class RiyadaBrandColors {
  /// Primary / active elements — vibrant teal from the logo leg gradient.
  static const primaryTeal = Color(0xFF00B494);

  /// Secondary / highlights — bright mint accent.
  static const secondaryMint = Color(0xFF00E5C1);

  /// Scaffold background — deep navy from the icon backdrop.
  static const scaffoldNavy = Color(0xFF0B1E36);

  /// Surface / cards — dark slate blue for depth.
  static const surfaceSlate = Color(0xFF132A4A);

  /// Elevated surfaces — slightly lighter slate.
  static const surfaceSlateElevated = Color(0xFF1A3558);

  /// Typography & icons on dark surfaces.
  static const onSurfaceWhite = Color(0xFFFFFFFF);

  /// Muted text on dark surfaces.
  static const onSurfaceMuted = Color(0xFFB8C5D6);

  /// Text on teal-filled buttons.
  static const onPrimary = Color(0xFFFFFFFF);

  /// Text on mint accents.
  static const onSecondary = Color(0xFF0B1E36);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryTeal, secondaryMint],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [scaffoldNavy, surfaceSlate, primaryTeal],
    stops: [0.0, 0.55, 1.0],
  );

  static LinearGradient ambientBackgroundGradient(bool isDark) => LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: isDark
            ? [scaffoldNavy, const Color(0xFF0D243F), const Color(0xFF0F2E4A)]
            : [const Color(0xFFE6F7F4), const Color(0xFFF0FAF8), const Color(0xFFF8FAFC)],
        stops: const [0.0, 0.55, 1.0],
      );
}
