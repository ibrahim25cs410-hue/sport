import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

import '../models/field.dart';
import '../theme/design_tokens.dart';
import '../utils/field_image.dart';
import '../utils/format.dart';
import '../utils/l10n_extension.dart';
import 'premium/stadium_card.dart';

/// بطاقة ملعب — بيانات حقيقية فقط (بدون وعود وهمية).
class FieldCard extends StatelessWidget {
  const FieldCard({
    super.key,
    required this.field,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final Field field;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rating = field.reviewCount > 0 ? field.averageRating : null;
    final cacheWidth = (148 * MediaQuery.devicePixelRatioOf(context)).ceil();

    return StadiumCard(
      name: field.name,
      address: field.address,
      priceLabel: '${formatMoney(field.pricePerHour)} ${l10n.perHour}',
      bookLabel: l10n.bookNow,
      onTap: onTap,
      image: fieldImageProvider(field, cacheWidth: cacheWidth),
      imageGradient: DesignTokens.gradientFor(field.id),
      rating: rating,
      isFavorite: isFavorite,
      onFavoriteToggle: onFavoriteToggle,
      amenities:
          rating != null
              ? [
                StadiumAmenity(
                  icon: LineIcons.star,
                  label: '${rating.toStringAsFixed(1)} (${field.reviewCount})',
                ),
              ]
              : const [],
    );
  }
}
