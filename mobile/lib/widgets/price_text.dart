import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// نص السعر — يبقى أخضر دائماً بغض النظر عن الوضع الليلي/النهاري.
class PriceText extends StatelessWidget {
  const PriceText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  static TextStyle resolveStyle({
    TextStyle? base,
    double fontSize = 17,
    FontWeight fontWeight = FontWeight.w800,
    double? height,
  }) =>
      TextStyle(
        fontSize: base?.fontSize ?? fontSize,
        fontWeight: base?.fontWeight ?? fontWeight,
        height: base?.height ?? height ?? 1.1,
        color: AppColors.priceGreen,
        letterSpacing: base?.letterSpacing,
      );

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: resolveStyle(base: style ?? Theme.of(context).textTheme.titleMedium),
    );
  }
}
