import 'package:flutter/material.dart';

import 'app_colors.dart';

/// يفرض لون النص والأيقونات: أبيض ليلاً، أسود نهاراً.
class RiyadaTypographyScope extends StatelessWidget {
  const RiyadaTypographyScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.typographyFor(context);
    final base = DefaultTextStyle.of(context);
    return DefaultTextStyle(
      style: base.style.copyWith(color: color),
      child: IconTheme(
        data: IconTheme.of(context).copyWith(color: color),
        child: child,
      ),
    );
  }
}
