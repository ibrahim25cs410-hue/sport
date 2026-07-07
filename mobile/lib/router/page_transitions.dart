import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/riyada_motion.dart';

/// بدون انتقال — للتبويبات داخل الـ Shell.
NoTransitionPage<void> noTransitionPage({required Widget child, required GoRouterState state}) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

/// انتقال fade + slide بين الصفحات.
CustomTransitionPage<T> riyadaTransitionPage<T>({
  required Widget child,
  required GoRouterState state,
  bool fromBottom = false,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: RiyadaMotion.pageForward,
    reverseTransitionDuration: RiyadaMotion.pageReverse,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(parent: animation, curve: RiyadaMotion.standardCurve);
      final offsetTween = fromBottom
          ? Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
          : Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero);

      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: offsetTween.animate(curve),
          child: child,
        ),
      );
    },
  );
}
