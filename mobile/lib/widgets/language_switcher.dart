import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../utils/l10n_extension.dart';

/// مبدّل اللغة — أزرار واضحة بعرض كامل (بدون ListTile.trailing).
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key, this.compact = false});

  final bool compact;

  Future<void> _setLocale(BuildContext context, bool arabic) async {
    final provider = context.read<LocaleProvider>();
    final target = Locale(arabic ? 'ar' : 'en');
    if (provider.locale == target) return;
    await provider.setLocale(target);
    if (!context.mounted) return;
    final l10n = context.l10n;
    final name = arabic ? l10n.languageAr : l10n.languageEn;
    showAppSnackBar(context, l10n.languageSwitched(name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isArabic = context.watch<LocaleProvider>().isArabic;

    if (compact) {
      return SegmentedButton<bool>(
        segments: [
          ButtonSegment(value: true, label: Text(l10n.languageAr, style: const TextStyle(fontSize: 12))),
          ButtonSegment(value: false, label: Text(l10n.languageEn, style: const TextStyle(fontSize: 12))),
        ],
        selected: {isArabic},
        onSelectionChanged: (s) => _setLocale(context, s.first),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(l10n.languageAr)),
            ButtonSegment(value: false, label: Text(l10n.languageEn)),
          ],
          selected: {isArabic},
          onSelectionChanged: (s) => _setLocale(context, s.first),
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        OutlinedButton.icon(
          onPressed: () => _setLocale(context, !isArabic),
          icon: const Icon(Icons.swap_horiz_rounded, size: 20),
          label: Text(l10n.toggleLanguage),
        ),
      ],
    );
  }
}

/// ورقة سفلية لاختيار اللغة دون فتح شاشة الإعدادات كاملة.
Future<void> showLanguagePickerSheet(BuildContext context) {
  final l10n = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          DesignTokens.spaceLg,
          DesignTokens.spaceSm,
          DesignTokens.spaceLg,
          DesignTokens.spaceLg + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.language, style: Theme.of(ctx).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: DesignTokens.spaceMd),
            const LanguageSwitcher(),
          ],
        ),
      );
    },
  );
}
