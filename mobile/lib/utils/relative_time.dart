import '../l10n/app_localizations.dart';

/// وقت نسبي مترجم: «منذ 5 دقائق»، «أمس»، إلخ.
String formatRelativeTime(AppLocalizations l10n, DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  if (diff.isNegative || diff.inSeconds < 60) return l10n.relativeNow;
  if (diff.inMinutes < 60) return l10n.relativeMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l10n.relativeHours(diff.inHours);
  if (diff.inDays == 1) return l10n.relativeYesterday;
  if (diff.inDays < 7) return l10n.relativeDays(diff.inDays);
  if (diff.inDays < 30) return l10n.relativeWeeks((diff.inDays / 7).floor());
  if (diff.inDays < 365) return l10n.relativeMonths((diff.inDays / 30).floor());
  return l10n.relativeYears((diff.inDays / 365).floor());
}
