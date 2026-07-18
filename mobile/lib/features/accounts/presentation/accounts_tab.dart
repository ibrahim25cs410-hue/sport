import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/booking/booking_result.dart';
import '../../../config/payment_policy.dart';
import '../../../core/providers/booking_actions_provider.dart';
import '../../../core/utils/session_key_helper.dart';
import '../../../domain/booking/booking_policy.dart';
import '../../../models/booking.dart';
import '../../../models/booking_checkout_args.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/session_key.dart';
import '../../../router/app_router.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/design_tokens.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../utils/booking_messages.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/booking_card.dart';
import '../../../widgets/common.dart';
import '../../../widgets/fintech/fintech_card.dart';
import '../../../widgets/skeleton_loaders.dart';
import '../../shell/shell_state.dart';

/// الحسابات — حجوزاتي وملخص الحساب.
class AccountsTab extends ConsumerStatefulWidget {
  const AccountsTab({super.key});

  @override
  ConsumerState<AccountsTab> createState() => _AccountsTabState();
}

class _AccountsTabState extends ConsumerState<AccountsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final c = context.colors;
    final key = watchSessionKey(ref);
    if (key == null) return const SizedBox.shrink();

    final async = ref.watch(userBookingsProvider(key));
    final bookings = async.valueOrNull ?? <Booking>[];
    final upcoming = bookings.where((b) => b.status == 'pending' || b.status == 'approved').toList();
    final loading = async.isLoading && bookings.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountsTab),
        actions: [
          IconButton(icon: const Icon(Icons.history_rounded), onPressed: () => context.goBookingHistory()),
        ],
      ),
      body: loading
          ? const BookingsListSkeleton()
          : RefreshIndicator(
              onRefresh: () => ref.read(userBookingsProvider(key).notifier).refreshPreservingData(),
              color: c.primary,
              child: upcoming.isEmpty
                  ? ListView(
                      children: [
                        FintechCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.accountsSummary, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text(l10n.noBookingsHint, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        EmptyState(
                          icon: Icons.event_busy_rounded,
                          title: l10n.noBookings,
                          actionLabel: l10n.exploreTab,
                          onAction: () => ref.read(shellTabProvider.notifier).select(1),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
                      itemCount: upcoming.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return FintechCard(
                            child: Row(
                              children: [
                                Icon(Icons.receipt_long_rounded, color: c.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.activeBookingsCount(upcoming.length),
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final booking = upcoming[i - 1];
                        final canCancel = booking.canCancel && BookingPolicy.canCancelBooking(booking);
                        return RepaintBoundary(
                          child: UserBookingCard(
                            booking: booking,
                            canCancel: canCancel,
                            onCancel: canCancel ? () => _cancel(booking, key) : null,
                            onPay: PaymentPolicy.electronicPaymentsEnabled && booking.needsPayment
                                ? () => _pay(booking, key)
                                : null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Future<void> _pay(Booking booking, UserSessionKey key) async {
    final paid = await context.goBookingCheckout(BookingCheckoutArgs(
      bookingId: booking.id,
      totalPrice: booking.totalPrice,
      fieldName: booking.fieldName,
      referenceCode: booking.referenceCode,
    ));
    if (paid == true && mounted) {
      await ref.read(userBookingsProvider(key).notifier).refreshPreservingData();
    }
  }

  Future<void> _cancel(Booking booking, UserSessionKey key) async {
    final l10n = context.l10n;
    final latePenalty = BookingPolicy.hasLateCancellationPenalty(booking.startTime);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelBooking),
        content: Text(latePenalty ? l10n.cancelLatePenaltyConfirm : l10n.cancelBookingConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.no)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.yesCancel)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final result = await ref.read(bookingActionsProvider(key)).cancelBooking(booking);
    if (!mounted) return;
    switch (result) {
      case BookingOk(:final value):
        showAppSnackBar(
          context,
          value.hasPenalty ? l10n.cancelSuccessWithPenalty : l10n.rtTitleBookingCancelled,
        );
      case BookingErr(:final failure):
        showAppWarningSnackBar(context, bookingFailureMessage(l10n, failure));
    }
  }
}
