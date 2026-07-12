import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/riyada_motion.dart';
import '../../theme/design_tokens.dart';
import '../../theme/riyada_theme_extension.dart';
import 'riyada_nav_icon.dart';
import 'riyada_nav_icon_widget.dart';

/// شريط تنقل سفلي عائم — Glassmorphism مع أيقونات SVG.
class FloatingBottomNavigationBar extends StatelessWidget {
  const FloatingBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.labels,
    this.icons = RiyadaNavIcon.shellTabs,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<String> labels;
  final List<RiyadaNavIcon> icons;

  static const _radius = DesignTokens.navBarRadius;
  static const _animDuration = RiyadaMotion.medium;
  static const _itemHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    assert(labels.length == icons.length, 'labels and icons must match');
    final c = context.colors;
    final muted = context.inactiveColor;
    final active = context.accentColor;
    final isDark = context.isDarkMode;
    final useBlur = _preferBlur(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, 0, DesignTokens.spaceLg, DesignTokens.spaceLg),
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: useBlur
              ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: _barSurface(context, c, muted, active, isDark),
                )
              : _barSurface(context, c, muted, active, isDark),
        ),
      ),
    );
  }

  Widget _barSurface(BuildContext context, RiyadaColors c, Color muted, Color active, bool isDark) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.0),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: (isDark ? c.surfaceElevated : Colors.white).withValues(alpha: isDark ? 0.85 : 0.92),
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(
            color: isDark ? DesignTokens.glassBorder : c.outline.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 4),
          child: SizedBox(
            height: _itemHeight,
            child: Row(
              children: List.generate(icons.length, (i) {
                return Expanded(
                  child: _FloatingNavItem(
                    icon: icons[i],
                    label: labels[i],
                    selected: i == selectedIndex,
                    activeColor: active,
                    inactiveColor: muted,
                    onTap: () => onSelected(i),
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

class _FloatingNavItem extends StatelessWidget {
  const _FloatingNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final RiyadaNavIcon icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? activeColor : inactiveColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!selected) HapticFeedback.selectionClick();
          onTap();
        },
        splashColor: activeColor.withValues(alpha: 0.15),
        highlightColor: activeColor.withValues(alpha: 0.08),
        child: SizedBox(
          height: FloatingBottomNavigationBar._itemHeight,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: FloatingBottomNavigationBar._animDuration,
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.all(selected ? 8 : 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? activeColor.withValues(alpha: 0.18) : Colors.transparent,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.22),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: RiyadaNavIconWidget(
                      icon: icon,
                      color: color,
                      selected: selected,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: 64,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? color : inactiveColor.withValues(alpha: 0.75),
                            fontSize: 9,
                            height: 1.1,
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

typedef FloatingGlassNavBar = FloatingBottomNavigationBar;

bool _preferBlur(BuildContext context) {
  if (MediaQuery.disableAnimationsOf(context)) return false;
  if (kIsWeb) return false;
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (_) {
    return false;
  }
}
