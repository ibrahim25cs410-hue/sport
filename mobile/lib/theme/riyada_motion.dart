import 'package:flutter/animation.dart';

/// Shared motion tokens — keep transitions consistent app-wide.
abstract final class RiyadaMotion {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 380);

  static const themeSwitch = Duration(milliseconds: 350);
  static const pageForward = Duration(milliseconds: 280);
  static const pageReverse = Duration(milliseconds: 220);

  static const standardCurve = Curves.easeOutCubic;
  static const emphasizedCurve = Curves.fastOutSlowIn;
  static const themeCurve = Curves.easeInOutCubic;
}
