import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/design_tokens.dart';
import '../../theme/riyada_theme_extension.dart';

/// شعار رياضة — أيقونة + نص بأنماط متعددة.
enum RiyadaLogoVariant { full, compact, splash, favicon }

class RiyadaLogo extends StatelessWidget {
  const RiyadaLogo({
    super.key,
    this.variant = RiyadaLogoVariant.full,
    this.size = 72,
    this.light = false,
  });

  final RiyadaLogoVariant variant;
  final double size;
  final bool light;

  String _iconAsset() => switch (variant) {
        RiyadaLogoVariant.splash => 'assets/logo/riyada_splash.svg',
        RiyadaLogoVariant.favicon => 'assets/logo/riyada_favicon.svg',
        _ => 'assets/brand/riyada_icon.svg',
      };

  double get _iconSize => switch (variant) {
        RiyadaLogoVariant.splash => size,
        RiyadaLogoVariant.favicon => size,
        RiyadaLogoVariant.compact => size,
        RiyadaLogoVariant.full => size * 0.72,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final label = isArabic ? 'رياضة' : 'Riyada';
    final textColor = light ? DesignTokens.textPrimary : c.onSurface;
    final fontFamily = isArabic ? GoogleFonts.cairo : GoogleFonts.inter;

    final icon = Container(
      decoration: variant == RiyadaLogoVariant.splash
          ? BoxDecoration(
              boxShadow: DesignTokens.glowShadow(DesignTokens.limeGreen, elevated: true),
              borderRadius: BorderRadius.circular(size * 0.28),
            )
          : null,
      child: SvgPicture.asset(
        _iconAsset(),
        width: _iconSize,
        height: _iconSize,
      ),
    );

    if (variant == RiyadaLogoVariant.compact || variant == RiyadaLogoVariant.favicon) {
      return icon;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        if (variant == RiyadaLogoVariant.full || variant == RiyadaLogoVariant.splash) ...[
          SizedBox(height: size * 0.18),
          Text(
            label,
            style: fontFamily(
              fontSize: variant == RiyadaLogoVariant.splash ? size * 0.28 : size * 0.24,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: isArabic ? 0 : 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// @deprecated استخدم [RiyadaLogo] — يبقى للتوافق.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.showLabel = true, this.light = false});

  final double size;
  final bool showLabel;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return RiyadaLogo(
      variant: showLabel ? RiyadaLogoVariant.full : RiyadaLogoVariant.compact,
      size: size,
      light: light,
    );
  }
}
