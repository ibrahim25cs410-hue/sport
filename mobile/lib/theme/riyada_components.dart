import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'riyada_theme_extension.dart';

/// خلفية بتدرج العلامة التجارية.
class BrandGradientBackground extends StatelessWidget {
  const BrandGradientBackground({super.key, required this.child, this.gradient});

  final Widget child;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient ?? DesignTokens.brandGradient),
      child: child,
    );
  }
}

/// لوحة سفلية منحنية للشاشات الترحيبية.
class RiyadaBottomPanel extends StatelessWidget {
  const RiyadaBottomPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceXl,
        DesignTokens.space2xl,
        DesignTokens.spaceXl,
        DesignTokens.spaceXl,
      ),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radius2xl)),
        boxShadow: DesignTokens.cardShadow(c.primary, elevated: true),
      ),
      child: child,
    );
  }
}

/// شريط تنقل سفلي مع ظل علوي.
class RiyadaNavigationBar extends StatelessWidget {
  const RiyadaNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        border: Border(top: BorderSide(color: c.outlineVariant.withValues(alpha: 0.7))),
        boxShadow: DesignTokens.navBarShadow(c.primary),
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
        ),
      ),
    );
  }
}

/// رأس SliverAppBar بتدرج موحّد.
class RiyadaHeroSliverAppBar extends StatelessWidget {
  const RiyadaHeroSliverAppBar({
    super.key,
    required this.title,
    this.expandedHeight = 128,
    this.actions,
  });

  final Widget title;
  final double expandedHeight;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),
        title: title,
        background: const DecoratedBox(decoration: BoxDecoration(gradient: DesignTokens.heroGradient)),
      ),
      actions: actions,
    );
  }
}

/// بطاقة بظل احترافي.
class RiyadaSurfaceCard extends StatelessWidget {
  const RiyadaSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.elevated = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final content = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: c.outlineVariant.withValues(alpha: context.isDarkMode ? 0.45 : 0.75)),
        boxShadow: elevated ? DesignTokens.cardShadow(c.primary, elevated: true) : DesignTokens.cardShadow(c.primary),
      ),
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: content,
      ),
    );
  }
}

/// شارة سعر / تسمية صغيرة.
class RiyadaPill extends StatelessWidget {
  const RiyadaPill({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.filled = true,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = color ?? c.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? accent.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: filled ? null : Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: accent),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: accent, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
