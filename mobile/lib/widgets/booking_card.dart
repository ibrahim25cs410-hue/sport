import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/booking/booking_policy.dart';
import '../models/booking.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/format.dart';
import '../utils/l10n_extension.dart';
import 'common.dart';
import 'price_text.dart';
import 'status_badge.dart';

class UserBookingCard extends StatelessWidget {
  const UserBookingCard({
    super.key,
    required this.booking,
    required this.canCancel,
    this.onCancel,
    this.onPay,
  });

  final Booking booking;
  final bool canCancel;
  final VoidCallback? onCancel;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          side: BorderSide(color: c.outline.withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(booking.fieldName, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  StatusBadge(status: booking.status),
                ],
              ),
              if (booking.referenceCode != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.tag_rounded, size: 16, color: c.primaryLight),
                    const SizedBox(width: 6),
                    Text(
                      booking.referenceCode!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: c.primary,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: l10n.copyReference,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: booking.referenceCode!));
                        showAppSnackBar(context, l10n.referenceCopied);
                      },
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              InfoTile(icon: Icons.location_on_outlined, text: booking.fieldAddress),
              InfoTile(icon: Icons.phone_outlined, text: booking.fieldPhone),
              InfoTile(icon: Icons.schedule_rounded, text: formatDateTime(booking.startTime)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.hours(booking.hours), style: Theme.of(context).textTheme.bodyLarge),
                    PriceText(
                      formatMoney(booking.totalPrice),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              if (booking.status == 'approved') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 16, color: c.success),
                    const SizedBox(width: 6),
                    Text(
                      formatRemaining(booking.remainingHours),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: c.success,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
              if (booking.needsPayment) ...[
                const SizedBox(height: DesignTokens.spaceMd),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    border: Border.all(color: c.warning.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payment_rounded, size: 18, color: c.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.paymentPendingHint,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onPay,
                    icon: const Icon(Icons.payments_rounded, size: 18),
                    label: Text(l10n.payNow),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                    ),
                  ),
                ),
              ],
              if (canCancel && onCancel != null) ...[
                const SizedBox(height: DesignTokens.spaceMd),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(l10n.cancelBooking),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.error,
                      side: BorderSide(color: c.error),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                    ),
                  ),
                ),
              ] else if (_isActive(booking.status) && canCancel && BookingPolicy.hasLateCancellationPenalty(booking.startTime)) ...[
                const SizedBox(height: DesignTokens.spaceMd),
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: c.warning),
                    const SizedBox(width: DesignTokens.spaceXs),
                    Expanded(
                      child: Text(
                        l10n.cancelLatePenaltyHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.warning),
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

  static bool _isActive(String status) => status == 'pending' || status == 'approved';
}
