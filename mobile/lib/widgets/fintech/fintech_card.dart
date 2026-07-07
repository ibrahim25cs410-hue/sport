import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

/// بطاقة ناعمة بأسلوب Fintech — Material 3 مع زوايا مستديرة وارتفاع خفيف.
class FintechCard extends StatelessWidget {
  const FintechCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DesignTokens.spaceLg),
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceSm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    return RepaintBoundary(child: card);
  }
}
