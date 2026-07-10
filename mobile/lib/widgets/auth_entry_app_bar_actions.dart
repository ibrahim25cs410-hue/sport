import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/l10n_extension.dart';
import 'language_switcher.dart';

/// أيقونات اللغة + الوضع الليلي/النهاري — لواجهات الدخول والتسجيل فقط.
class AuthEntryAppBarActions extends StatelessWidget {
  const AuthEntryAppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = context.watch<ThemeProvider>().isDark;
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.language,
          onPressed: () => showLanguagePickerSheet(context),
          icon: Icon(isArabic ? Icons.translate_rounded : Icons.language_rounded),
        ),
        IconButton(
          tooltip: l10n.darkMode,
          onPressed: () => context.read<ThemeProvider>().toggle(),
          icon: Icon(isDark ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded),
        ),
      ],
    );
  }
}
