import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/booking/booking_policy.dart';
import '../models/field.dart';
import '../theme/design_tokens.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/format.dart';
import '../utils/l10n_extension.dart';
import 'price_text.dart';

/// ورقة تأكيد قبل إرسال طلب الحجز — مع ملخص مالي واضح.
Future<bool?> showBookingConfirmSheet({
  required BuildContext context,
  required Field field,
  required DateTime startTime,
  required int hours,
}) {
  final subtotal = BookingPolicy.calculateTotalForField(field.pricePerHour, hours);
  final l10n = context.l10n;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
      builder: (ctx) {
        final c = ctx.colors;
        return Padding(
          padding: EdgeInsets.fromLTRB(DesignTokens.spaceXl, 0, DesignTokens.spaceXl, DesignTokens.spaceXl + MediaQuery.of(ctx).padding.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Text(l10n.confirmBooking, style: Theme.of(ctx).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: DesignTokens.spaceSm),
            Text(l10n.bookingSummary, style: Theme.of(ctx).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: DesignTokens.spaceXl),
            _SummaryCard(
              child: Column(
                children: [
                  _row(ctx, Icons.stadium_rounded, l10n.labelField, field.name),
                  _divider(c),
                  _row(ctx, Icons.schedule_rounded, l10n.labelDateTime, formatTimeRange12Ar(startTime, hours)),
                  _divider(c),
                  _row(ctx, Icons.timer_outlined, l10n.labelDuration, l10n.hours(hours)),
                  _divider(c),
                  _row(ctx, Icons.payments_outlined, l10n.pricePerHourLine, '${formatMoney(field.pricePerHour)}${l10n.perHour}', emphasized: true),
                  _divider(c),
                  _row(ctx, Icons.receipt_long_rounded, l10n.subtotal, formatMoney(subtotal), emphasized: true),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Container(
              padding: const EdgeInsets.all(DesignTokens.spaceMd),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                border: Border.all(color: c.accent.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: c.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.commissionNote,
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.appCommission, style: Theme.of(ctx).textTheme.bodySmall),
                      Text(
                        formatMoney(BookingPolicy.calculateCommission(
                          pricePerHour: field.pricePerHour,
                          hours: hours,
                        )),
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700, color: c.warning),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.payAtField, style: Theme.of(ctx).textTheme.bodySmall),
                      PriceText(
                        formatMoney(subtotal),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceXl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceMd),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(ctx, true),
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: Text(l10n.confirmAndSend),
                  ),
                ),
              ],
            ),
            ],
            ),
          ),
        );
      },
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      decoration: BoxDecoration(
        color: c.surfaceVariant.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: c.outlineVariant),
      ),
      child: child,
    );
  }
}

Widget _divider(RiyadaColors c) => Divider(color: c.outlineVariant.withValues(alpha: 0.7), height: 20);

Widget _row(BuildContext ctx, IconData icon, String label, String value, {bool emphasized = false}) {
  final c = ctx.colors;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: c.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: Theme.of(ctx).textTheme.bodyMedium)),
        const SizedBox(width: 8),
        Flexible(
          child: emphasized
              ? PriceText(
                  value,
                  textAlign: TextAlign.end,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                )
              : Text(
                  value,
                  style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.end,
                ),
        ),
      ],
    ),
  );
}
