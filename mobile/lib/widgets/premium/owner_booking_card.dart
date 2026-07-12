import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';

import '../../models/booking.dart';
import '../../theme/riyada_theme_extension.dart';
import '../../theme/design_tokens.dart';
import '../../utils/format.dart';
import '../../utils/l10n_extension.dart';
import '../price_text.dart';
import '../status_badge.dart';

/// بطاقة حجز المالك — ألوان من الثيم لدعم الوضع الليلي/النهاري.
class OwnerBookingCard extends StatelessWidget {
  const OwnerBookingCard({
    super.key,
    required this.booking,
    required this.onApprove,
    required this.onReject,
    this.busy = false,
  });

  final OwnerBooking booking;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool busy;

  static const _radius = 16.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = context.colors;
    final l10n = context.l10n;
    final cardColor = theme.cardTheme.color ?? scheme.surface;
    final initial = booking.userName.isNotEmpty ? booking.userName[0] : '?';
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: context.isDarkMode ? 0.4 : 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: scheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      initial,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.userName,
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (booking.fieldName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            booking.fieldName,
                            style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(LineIcons.phone, size: 12, color: textTheme.bodySmall?.color),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                booking.userPhone,
                                style: textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: booking.status),
                ],
              ),
              if (booking.referenceCode != null) ...[
                const SizedBox(height: DesignTokens.spaceSm),
                Row(
                  children: [
                    Icon(LineIcons.hashtag, size: 12, color: textTheme.bodySmall?.color),
                    const SizedBox(width: 4),
                    Text(
                      booking.referenceCode!,
                      style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: DesignTokens.spaceMd),
              _InfoRow(icon: LineIcons.calendar, text: formatDateTime(booking.startTime)),
              const SizedBox(height: DesignTokens.spaceXs),
              _InfoRow(icon: LineIcons.clock, text: l10n.hours(booking.hours)),
              const SizedBox(height: DesignTokens.spaceMd),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: DesignTokens.spaceSm),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: PriceText(
                  formatMoney(booking.totalPrice),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              if (booking.status == 'pending') ...[
                const SizedBox(height: DesignTokens.spaceMd),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: busy ? null : onApprove,
                        icon: busy
                            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary))
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(l10n.approve),
                        style: FilledButton.styleFrom(
                          backgroundColor: c.success,
                          foregroundColor: scheme.onPrimary,
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spaceSm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : onReject,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: Text(l10n.reject),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.error,
                          side: BorderSide(color: c.error),
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: textTheme.bodySmall?.color),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: textTheme.bodySmall)),
      ],
    );
  }
}
