import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../../theme/riyada_theme_extension.dart';

bool _preferBlur(BuildContext context) {
  if (MediaQuery.disableAnimationsOf(context)) return false;
  if (kIsWeb) return false;
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (_) {
    return false;
  }
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = DesignTokens.radiusXl,
    this.padding,
    this.margin,
    this.onTap,
    this.blur = 12,
    this.opacity,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double blur;
  final double? opacity;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fill = opacity != null
        ? (context.isDarkMode ? Colors.white.withValues(alpha: opacity!) : Colors.white.withValues(alpha: opacity! + 0.55))
        : context.glassFill;

    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: context.glassBorder),
        boxShadow: DesignTokens.glowShadow(c.primary, subtle: true),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(DesignTokens.spaceLg),
        child: child,
      ),
    );

    final Widget content;
    if (_preferBlur(context)) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: decorated,
        ),
      );
    } else {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: decorated,
      );
    }

    if (margin != null) {
      return Padding(padding: margin!, child: _maybeTap(context, content));
    }
    return _maybeTap(context, content);
  }

  Widget _maybeTap(BuildContext context, Widget child) {
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: context.accentColor.withValues(alpha: 0.12),
        highlightColor: context.accentColor.withValues(alpha: 0.06),
        child: child,
      ),
    );
  }
}

class GlassFeatureCard extends StatelessWidget {
  const GlassFeatureCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GlassSurface(
      onTap: onTap,
      borderRadius: DesignTokens.radius2xl,
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceMd, horizontal: DesignTokens.spaceSm),
      blur: 0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: DesignTokens.neonGradient,
              boxShadow: DesignTokens.glowShadow(c.primary, subtle: true),
            ),
            child: Icon(icon, color: DesignTokens.onNeon, size: 24),
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.2),
          ),
        ],
      ),
    );
  }
}
