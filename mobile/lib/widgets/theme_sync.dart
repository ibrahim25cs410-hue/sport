import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// يزامن شريط الحالة وشريط التنقل مع الثيم الحالي.
class ThemeSync extends StatelessWidget {
  const ThemeSync({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlay = isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: child,
    );
  }
}
