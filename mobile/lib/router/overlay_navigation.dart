import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'navigation_keys.dart';

/// تنقّل موثوق فوق الـ Shell عبر الموجّه الجذري.
extension RootOverlayNavigation on BuildContext {
  GoRouter get _rootRouter {
    final rootCtx = rootNavigatorKey.currentContext;
    if (rootCtx != null) {
      return GoRouter.of(rootCtx);
    }
    return GoRouter.of(this);
  }

  Future<T?> pushOverlay<T extends Object?>(String path, {Object? extra}) =>
      _rootRouter.push<T>(path, extra: extra);

  /// احتياطي إذا فشل GoRouter — يدفع شاشة كاملة على الموجّه الجذري.
  Future<T?> pushOverlayScreen<T extends Object?>(Widget screen) {
    final nav = rootNavigatorKey.currentState;
    if (nav != null) {
      return nav.push<T>(MaterialPageRoute(builder: (_) => screen));
    }
    return Navigator.of(this, rootNavigator: true).push<T>(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
