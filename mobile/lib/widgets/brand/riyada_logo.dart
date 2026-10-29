import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  static const _pngLogo = 'assets/brand/riyada_logo.png';

  String _iconAsset() => switch (variant) {
    RiyadaLogoVariant.splash => _pngLogo,
    RiyadaLogoVariant.favicon => 'assets/logo/riyada_favicon.svg',
    RiyadaLogoVariant.full => _pngLogo,
    RiyadaLogoVariant.compact => _pngLogo,
  };

  bool get _usesPng =>
      variant == RiyadaLogoVariant.splash ||
      variant == RiyadaLogoVariant.full ||
      variant == RiyadaLogoVariant.compact;

  double get _iconSize => switch (variant) {
    RiyadaLogoVariant.splash => size,
    RiyadaLogoVariant.favicon => size,
    RiyadaLogoVariant.compact => size,
    RiyadaLogoVariant.full => size,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final label = isArabic ? 'رياضة' : 'Riyada';
    final textColor = light ? DesignTokens.textPrimary : c.onSurface;

    final Widget icon;
    if (_usesPng) {
      icon = ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          _iconAsset(),
          width: _iconSize,
          height: _iconSize,
          fit: BoxFit.cover,
          cacheWidth: (_iconSize * pixelRatio).ceil(),
          cacheHeight: (_iconSize * pixelRatio).ceil(),
        ),
      );
    } else {
      icon = SvgPicture.asset(
        _iconAsset(),
        width: _iconSize,
        height: _iconSize,
      );
    }

    // الشعار PNG يحتوي النص مسبقاً — لا نكرّره.
    if (_usesPng ||
        variant == RiyadaLogoVariant.compact ||
        variant == RiyadaLogoVariant.favicon) {
      return icon;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(height: size * 0.18),
        Text(
          label,
          style: TextStyle(
            fontSize: size * 0.24,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: isArabic ? 0 : 0.5,
          ),
        ),
      ],
    );
  }
}

/// @deprecated استخدم [RiyadaLogo] — يبقى للتوافق.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 72,
    this.showLabel = true,
    this.light = false,
  });

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
