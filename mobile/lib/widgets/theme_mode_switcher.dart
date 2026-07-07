import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/riyada_motion.dart';
import '../theme/design_tokens.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/l10n_extension.dart';

/// مبدّل وضع ليلي/نهاري بتصميم احترافي.
class ThemeModeSwitcher extends StatelessWidget {
  const ThemeModeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final isDark = context.watch<ThemeProvider>().isDark;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.0),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(color: c.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ThemeOption(
                selected: !isDark,
                icon: Icons.wb_sunny_rounded,
                label: l10n.lightMode,
                onTap: () => context.read<ThemeProvider>().setDarkMode(false),
              ),
            ),
            Expanded(
              child: _ThemeOption(
                selected: isDark,
                icon: Icons.nights_stay_rounded,
                label: l10n.darkMode,
                onTap: () => context.read<ThemeProvider>().setDarkMode(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return AnimatedContainer(
      duration: RiyadaMotion.medium,
      curve: RiyadaMotion.standardCurve,
      decoration: BoxDecoration(
        color: selected ? (context.isDarkMode ? c.surfaceElevated : Colors.white) : Colors.transparent,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        boxShadow: selected && !context.isDarkMode
            ? [BoxShadow(color: DesignTokens.primaryTeal.withValues(alpha: 0.14), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: selected ? context.accentColor : context.inactiveColor),
                const SizedBox(width: 6),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: RiyadaMotion.fast,
                    curve: RiyadaMotion.standardCurve,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? context.typographyColor : context.inactiveColor,
                      fontSize: 12,
                      height: 1.1,
                    ),
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
