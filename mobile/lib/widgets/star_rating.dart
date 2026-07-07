import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/riyada_theme_extension.dart';

class StarRatingDisplay extends StatelessWidget {
  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = 16,
  });

  final double rating;
  final int? reviewCount;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filled = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          return Icon(
            i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < filled ? DesignTokens.accent : c.onSurfaceVariant,
          );
        }),
        if (reviewCount != null) ...[
          const SizedBox(width: 4),
          Text(
            rating > 0 ? rating.toStringAsFixed(1) : '—',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            ' ($reviewCount)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 36,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        final selected = star <= value;
        return IconButton(
          onPressed: () => onChanged(star),
          icon: Icon(
            selected ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: selected ? DesignTokens.accent : context.colors.onSurfaceVariant,
          ),
        );
      }),
    );
  }
}
