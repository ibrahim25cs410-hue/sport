import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

/// مسافات مشتركة لمحتوى التبويبات فوق شريط التنقل العائم.
abstract final class ShellLayout {
  static const navBarHeight = 76.0;
  static const navOuterPadding = DesignTokens.spaceLg;

  /// ارتفاع آمن لأسفل القوائم حتى لا يُخفى المحتوى خلف الشريط.
  static double bottomInset(BuildContext context) {
    final safe = MediaQuery.paddingOf(context).bottom;
    return navBarHeight + navOuterPadding + safe + DesignTokens.spaceMd;
  }

  static EdgeInsets listPadding(BuildContext context) =>
      EdgeInsets.only(bottom: bottomInset(context));

  /// حشو أفقي + أسفل للقوائم داخل الـ Shell.
  static EdgeInsets contentPadding(BuildContext context) => EdgeInsets.fromLTRB(
        DesignTokens.spaceLg,
        0,
        DesignTokens.spaceLg,
        bottomInset(context),
      );
}
