import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// خلفية عامة بتمويه أخضر ناعم — بدل الأسود/الأبيض الصافي.
class AmbientGreenBackground extends StatelessWidget {
  const AmbientGreenBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: DesignTokens.ambientBackgroundGradient(isDark),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _GlowBlob(
            top: -72,
            right: -48,
            size: 260,
            color: DesignTokens.primaryTeal.withValues(
              alpha: isDark ? 0.20 : 0.14,
            ),
          ),
          _GlowBlob(
            bottom: -96,
            left: -64,
            size: 300,
            color: DesignTokens.secondaryMint.withValues(
              alpha: isDark ? 0.12 : 0.10,
            ),
          ),
          _GlowBlob(
            top: MediaQuery.sizeOf(context).height * 0.35,
            left: -80,
            size: 200,
            color: DesignTokens.primaryTeal.withValues(
              alpha: isDark ? 0.07 : 0.06,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.size,
    required this.color,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final double? top;
  final double size;
  final Color color;
  final double? left;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: color.a * 0.45),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
      ),
    );
  }
}
