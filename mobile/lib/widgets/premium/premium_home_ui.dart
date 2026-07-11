import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../../theme/riyada_motion.dart';
import '../../theme/riyada_theme_extension.dart';
import '../../utils/l10n_extension.dart';
import '../brand/riyada_icon_badge.dart';
import 'glass_surface.dart';

/// شريط علوي: تحية + موقع (يمين) | إشعارات (يسار في RTL).
class PremiumHomeAppBar extends StatelessWidget {
  const PremiumHomeAppBar({
    super.key,
    required this.userName,
    required this.onNotifications,
    this.unreadCount = 0,
  });

  final String userName;
  final VoidCallback onNotifications;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final firstName = userName.split(' ').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, DesignTokens.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.hello(firstName),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                GlassSurface(
                  borderRadius: DesignTokens.radiusLg,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  blur: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 18, color: DesignTokens.primaryTeal),
                      const SizedBox(width: 6),
                      Text(l10n.provinceNineveh, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: context.inactiveColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.spaceMd),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onNotifications,
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              child: GlassSurface(
                borderRadius: DesignTokens.radiusLg,
                padding: const EdgeInsets.all(10),
                blur: 0,
                child: Badge(
                  isLabelVisible: unreadCount > 0,
                  backgroundColor: DesignTokens.primaryTeal,
                  label: Text('$unreadCount', style: const TextStyle(color: DesignTokens.onNeon, fontSize: 10)),
                  child: const Icon(Icons.notifications_none_rounded, color: DesignTokens.primaryTeal, size: 26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// شريط بحث كبير مع زر فلتر.
class PremiumSearchBar extends StatelessWidget {
  const PremiumSearchBar({
    super.key,
    required this.onChanged,
    required this.onFilter,
    this.onClear,
    this.hasQuery = false,
    this.hasActiveFilters = false,
  });

  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;
  final VoidCallback? onClear;
  final bool hasQuery;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
      child: Row(
        children: [
          Expanded(
            child: GlassSurface(
              borderRadius: DesignTokens.radius2xl,
              padding: EdgeInsets.zero,
              blur: 0,
              child: TextField(
                onChanged: onChanged,
                style: TextStyle(color: context.typographyColor, fontSize: 15),
                decoration: InputDecoration(
                  hintText: l10n.searchFieldsExtended,
                  hintStyle: TextStyle(color: context.inactiveColor),
                  prefixIcon: Icon(Icons.search_rounded, color: context.accentColor, size: 26),
                  suffixIcon: hasQuery ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: onClear) : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                ),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spaceSm),
          Material(
            color: DesignTokens.primaryTeal,
            shape: const CircleBorder(),
            elevation: 0,
            shadowColor: DesignTokens.primaryTeal.withValues(alpha: 0.4),
            child: InkWell(
              onTap: onFilter,
              customBorder: const CircleBorder(),
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: DesignTokens.glowShadow(DesignTokens.primaryTeal, subtle: true),
                  border: hasActiveFilters
                      ? Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2)
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.tune_rounded, color: DesignTokens.onNeon, size: 24),
                    if (hasActiveFilters)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بانر بطول كامل مع كاروسيل.
class PremiumHeroBanner extends StatefulWidget {
  const PremiumHeroBanner({super.key, required this.onBook});

  final VoidCallback onBook;

  @override
  State<PremiumHeroBanner> createState() => _PremiumHeroBannerState();
}

class _PremiumHeroBannerState extends State<PremiumHeroBanner> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slides = [
      (l10n.heroBookSeconds, l10n.heroSlide1Subtitle, DesignTokens.stadiumNightGradient),
      (l10n.heroSlide2Title, l10n.heroSlide2Subtitle, DesignTokens.fieldGradients[1]),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceLg, DesignTokens.spaceLg, DesignTokens.spaceSm),
      child: SizedBox(
        height: 200,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: _page,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: slides.length,
              itemBuilder: (context, i) {
                final (title, subtitle, colors) = slides[i];
                const radius = DesignTokens.radiusXl; // 24 — smooth modern card corners
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: DesignTokens.glowShadow(DesignTokens.primaryTeal, elevated: true),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [colors[0], colors[1]],
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CustomPaint(painter: _StadiumNightPainter()),
                          Padding(
                            padding: const EdgeInsets.all(DesignTokens.spaceXl),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.15),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13, height: 1.35),
                                ),
                                const Spacer(),
                                FilledButton(
                                  onPressed: widget.onBook,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: DesignTokens.primaryTeal,
                                    foregroundColor: DesignTokens.onNeon,
                                    minimumSize: const Size(0, 44),
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusLg)),
                                  ),
                                  child: Text(l10n.bookNow, style: const TextStyle(fontWeight: FontWeight.w800)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active ? DesignTokens.primaryTeal : Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: active ? DesignTokens.glowShadow(DesignTokens.primaryTeal, subtle: true) : null,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _StadiumNightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final flood = Paint()..color = Colors.white.withValues(alpha: 0.06);
    for (var x = 0.0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x + 14, size.height * 0.45), flood);
    }
    final pitch = Paint()..color = Colors.black.withValues(alpha: 0.25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.15, size.height * 0.35, size.width * 0.7, size.height * 0.45),
        const Radius.circular(16),
      ),
      pitch,
    );
    final ball = Paint()..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.72), 36, ball);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

    /// شبكة الميزات (5 بطاقات زجاجية أفقية).
class PremiumFeaturesGrid extends StatelessWidget {
  const PremiumFeaturesGrid({
    super.key,
    required this.onOffers,
    required this.onBookings,
    required this.onAvailable,
    required this.onCertified,
    required this.onSupport,
  });

  final VoidCallback onOffers;
  final VoidCallback onBookings;
  final VoidCallback onAvailable;
  final VoidCallback onCertified;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (Icons.sports_soccer_rounded, l10n.penaltyShootout, onOffers),
      (Icons.event_available_rounded, l10n.myBookings, onBookings),
      (Icons.bolt_rounded, l10n.availableNow, onAvailable),
      (Icons.verified_user_rounded, l10n.quickCertified, onCertified),
      (Icons.headset_mic_rounded, l10n.featureSupport, onSupport),
    ];

    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (icon, label, onTap) = items[i];
          return SizedBox(
            width: 100,
            child: GlassFeatureCard(icon: icon, label: label, onTap: onTap),
          );
        },
      ),
    );
  }
}

/// بانر العروض الترويجي.
class PremiumPromoBanner extends StatelessWidget {
  const PremiumPromoBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceLg, DesignTokens.spaceLg, DesignTokens.spaceMd),
      child: GlassSurface(
        borderRadius: DesignTokens.radius3xl,
        padding: const EdgeInsets.all(DesignTokens.spaceXl),
        blur: 0,
        child: Row(
          children: [
            RiyadaIconBadge(
              size: RiyadaIconBadgeSize.lg,
              child: const Icon(Icons.sports_soccer_rounded),
            ),
            const SizedBox(width: DesignTokens.spaceLg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.promoTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(l10n.promoSubtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: DesignTokens.primaryTeal,
                foregroundColor: DesignTokens.onNeon,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(l10n.promoCta),
            ),
          ],
        ),
      ),
    );
  }
}

/// شريط تنقل سفلي حديث (5 تبويبات).
class PremiumBottomNav extends StatelessWidget {
  const PremiumBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.labels,
    this.icons,
    this.selectedIcons,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<String> labels;
  final List<IconData>? icons;
  final List<IconData>? selectedIcons;

  static const _defaultIcons = [
    Icons.home_rounded,
    Icons.event_note_outlined,
    Icons.favorite_border_rounded,
    Icons.person_outline_rounded,
    Icons.grid_view_rounded,
  ];

  static const _defaultSelectedIcons = [
    Icons.home_rounded,
    Icons.event_note_rounded,
    Icons.favorite_rounded,
    Icons.person_rounded,
    Icons.grid_view_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final icons = this.icons ?? _defaultIcons;
    final selectedIcons = this.selectedIcons ?? _defaultSelectedIcons;
    final muted = context.inactiveColor;
    final selectedColor = context.accentColor;

    return ClipRRect(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceElevated.withValues(alpha: 0.95),
          border: Border(top: BorderSide(color: context.glassBorder)),
          boxShadow: DesignTokens.navBarShadow(c.primary),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: List.generate(icons.length, (i) {
                final selected = i == selectedIndex;
                return Expanded(
                  child: InkWell(
                    onTap: () => onSelected(i),
                    child: AnimatedContainer(
                      duration: RiyadaMotion.medium,
                      curve: RiyadaMotion.standardCurve,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: RiyadaMotion.medium,
                            curve: RiyadaMotion.standardCurve,
                            padding: EdgeInsets.all(selected ? 8 : 0),
                            decoration: selected
                                ? BoxDecoration(
                                    color: DesignTokens.primaryTeal.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                                    boxShadow: DesignTokens.glowShadow(DesignTokens.primaryTeal, subtle: true),
                                  )
                                : null,
                            child: Icon(
                              selected ? selectedIcons[i] : icons[i],
                              color: selected ? selectedColor : muted,
                              size: selected ? 26 : 24,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? selectedColor : muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
