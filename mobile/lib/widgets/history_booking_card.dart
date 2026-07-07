import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../theme/design_tokens.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/format.dart';
import '../utils/l10n_extension.dart';
import 'common.dart';
import 'price_text.dart';
import 'status_badge.dart';

class HistoryBookingCard extends StatelessWidget {
  const HistoryBookingCard({super.key, required this.booking});

  final Booking booking;

  Color _accentColor(RiyadaColors c) => switch (booking.status) {
        'pending' => c.warning,
        'approved' when booking.remainingHours <= 0 => c.primary,
        'approved' => c.success,
        'cancelled' => c.onSurfaceVariant,
        'rejected' => c.error,
        _ => c.primary,
      };

  String _statusLabel(BuildContext context) {
    final l10n = context.l10n;
    if (booking.status == 'approved' && booking.remainingHours <= 0) {
      return l10n.statusCompleted;
    }
    return switch (booking.status) {
      'pending' => l10n.pending,
      'approved' => l10n.approved,
      'cancelled' => l10n.statusCancelled,
      'rejected' => l10n.statusRejected,
      _ => booking.status,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = _accentColor(c);
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: DesignTokens.spaceSm),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(booking.fieldName, style: Theme.of(context).textTheme.titleMedium),
                          ),
                          StatusBadge(status: booking.status, label: _statusLabel(context)),
                        ],
                      ),
                      if (booking.referenceCode != null) ...[
                        const SizedBox(height: DesignTokens.spaceSm),
                        Text(
                          booking.referenceCode!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: c.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                      const SizedBox(height: DesignTokens.spaceSm),
                      InfoTile(icon: Icons.schedule_rounded, text: formatDateTime(booking.startTime)),
                      const SizedBox(height: DesignTokens.spaceSm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.hours(booking.hours), style: Theme.of(context).textTheme.bodyLarge),
                          PriceText(
                            formatMoney(booking.totalPrice),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
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
    );
  }
}

class TotalHoursBanner extends StatelessWidget {
  const TotalHoursBanner({super.key, required this.totalHours});

  final int totalHours;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(DesignTokens.spaceMd, DesignTokens.spaceMd, DesignTokens.spaceMd, DesignTokens.spaceSm),
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        gradient: DesignTokens.brandGradient,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        boxShadow: DesignTokens.cardShadow(c.primary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.spaceSm),
            decoration: BoxDecoration(
              color: c.onInverse.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: Icon(Icons.emoji_events_rounded, color: c.onInverse, size: 28),
          ),
          const SizedBox(width: DesignTokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.totalHoursBooked,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.onInverseMuted),
                ),
                Text(
                  l10n.totalHoursValue(totalHours),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: c.onInverse,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
