import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import '../../theme/design_tokens.dart';
import '../../theme/riyada_theme_extension.dart';
import '../price_text.dart';

/// ميزة ملعب مع أيقونة خطية ونص صغير (نسبة 1:1).
class StadiumAmenity {
  const StadiumAmenity({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// بطاقة ملعب أفقية — ألوان من الثيم لدعم الوضع الليلي/النهاري.
class StadiumCard extends StatelessWidget {
  const StadiumCard({
    super.key,
    required this.name,
    required this.address,
    required this.priceLabel,
    required this.bookLabel,
    required this.onTap,
    this.image,
    this.imageGradient,
    this.rating,
    this.badgeLabel,
    this.amenities = const [],
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.height = 168,
    this.imageWidth = 148,
  });

  final String name;
  final String address;
  final String priceLabel;
  final String bookLabel;
  final VoidCallback onTap;
  final ImageProvider? image;
  final Gradient? imageGradient;
  final double? rating;
  final String? badgeLabel;
  final List<StadiumAmenity> amenities;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final double height;
  final double imageWidth;

  static final _radius = DesignTokens.radiusLg;
  static const _featureSize = 12.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final cardColor = theme.cardTheme.color ?? scheme.surface;
    final textTheme = theme.textTheme;
    final accent = scheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: context.isDarkMode ? 0.45 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: accent.withValues(alpha: context.isDarkMode ? 0.06 : 0.04),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius),
              child: Row(
                children: [
                  _ImagePanel(
                    width: imageWidth,
                    image: image,
                    fallbackGradient: imageGradient ??
                        LinearGradient(
                          colors: [scheme.surfaceContainerHighest, accent.withValues(alpha: 0.35)],
                        ),
                    isRtl: isRtl,
                    cardColor: cardColor,
                    rating: rating,
                    badgeLabel: badgeLabel,
                    isFavorite: isFavorite,
                    onFavoriteToggle: onFavoriteToggle,
                    accent: accent,
                    onAccent: scheme.onPrimary,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.2),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(LineIcons.mapMarker, size: 14, color: textTheme.bodySmall?.color),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(height: 1.3),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (amenities.isNotEmpty) ...[
                            Wrap(
                              spacing: 12,
                              runSpacing: 4,
                              children: amenities
                                  .take(4)
                                  .map((a) => _FeatureChip(amenity: a, accent: accent, textColor: textTheme.bodySmall?.color))
                                  .toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: PriceText(
                                  priceLabel,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.1),
                                ),
                              ),
                              _BookChip(label: bookLabel, onTap: onTap, accent: context.accentColor, onAccent: scheme.onPrimary),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePanel extends StatelessWidget {
  const _ImagePanel({
    required this.width,
    required this.image,
    required this.fallbackGradient,
    required this.isRtl,
    required this.cardColor,
    required this.accent,
    required this.onAccent,
    this.rating,
    this.badgeLabel,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final double width;
  final ImageProvider? image;
  final Gradient fallbackGradient;
  final bool isRtl;
  final Color cardColor;
  final Color accent;
  final Color onAccent;
  final double? rating;
  final String? badgeLabel;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final fadeBegin = isRtl ? Alignment.centerLeft : Alignment.centerRight;
    final fadeEnd = isRtl ? Alignment.centerRight : Alignment.centerLeft;
    final overlay = Theme.of(context).colorScheme.scrim.withValues(alpha: 0.55);

    return SizedBox(
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null)
            Image(image: image!, fit: BoxFit.cover)
          else
            DecoratedBox(
              decoration: BoxDecoration(gradient: fallbackGradient),
              child: Center(
                child: Icon(LineIcons.futbol, size: 48, color: onAccent.withValues(alpha: 0.35)),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: fadeBegin,
                end: fadeEnd,
                colors: [Colors.transparent, cardColor.withValues(alpha: 0.92)],
                stops: const [0.35, 1.0],
              ),
            ),
          ),
          if (onFavoriteToggle != null)
            PositionedDirectional(
              top: 8,
              start: 8,
              child: _IconCircle(
                icon: isFavorite ? LineIcons.heartAlt : LineIcons.heart,
                iconColor: isFavorite ? Theme.of(context).colorScheme.error : onAccent,
                background: overlay,
                onTap: onFavoriteToggle,
              ),
            ),
          if (rating != null)
            PositionedDirectional(
              top: 8,
              end: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rating!.toStringAsFixed(1),
                      style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w800, color: onAccent),
                    ),
                    const SizedBox(width: 3),
                    Icon(LineIcons.starAlt, size: 11, color: onAccent),
                  ],
                ),
              ),
            ),
          if (badgeLabel != null)
            Positioned(
              bottom: 8,
              right: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeLabel!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.w700, color: onAccent),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.amenity, required this.accent, required this.textColor});

  final StadiumAmenity amenity;
  final Color accent;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    const size = StadiumCard._featureSize;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(amenity.icon, size: size, color: accent.withValues(alpha: 0.9)),
        const SizedBox(width: 4),
        Text(
          amenity.label,
          style: GoogleFonts.cairo(fontSize: size, color: textColor, height: 1.0),
        ),
      ],
    );
  }
}

class _BookChip extends StatelessWidget {
  const _BookChip({required this.label, required this.onTap, required this.accent, required this.onAccent});

  final String label;
  final VoidCallback onTap;
  final Color accent;
  final Color onAccent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w800, color: onAccent),
          ),
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.icon, required this.iconColor, required this.background, this.onTap});

  final IconData icon;
  final Color iconColor;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 16, color: iconColor),
        ),
      ),
    );
  }
}
