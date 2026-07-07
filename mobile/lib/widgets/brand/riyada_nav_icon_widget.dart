import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'riyada_nav_icon.dart';

/// أيقونة SVG للتنقل — لون ديناميكي عبر currentColor.
class RiyadaNavIconWidget extends StatelessWidget {
  const RiyadaNavIconWidget({
    super.key,
    required this.icon,
    required this.color,
    this.size = 24,
    this.selected = false,
  });

  final RiyadaNavIcon icon;
  final Color color;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: SvgPicture.asset(
        icon.assetPath,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
