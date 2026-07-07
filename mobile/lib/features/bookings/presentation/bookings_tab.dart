import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/booking/booking_result.dart';
import '../../../core/providers/booking_actions_provider.dart';
import '../../../core/utils/session_key_helper.dart';
import '../../../domain/booking/booking_policy.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/session_key.dart';
import '../../../router/app_router.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/design_tokens.dart';
import '../../../utils/booking_messages.dart';
import '../../../utils/l10n_extension.dart';
import '../../../models/booking.dart';
import '../../../models/booking_checkout_args.dart';
import '../../../widgets/booking_card.dart';
import '../../../widgets/common.dart';
import '../../../widgets/load_more_footer.dart';
import '../../shell/shell_layout.dart';
import '../../../widgets/skeleton_loaders.dart';

class BookingsTab extends ConsumerStatefulWidget {
  const BookingsTab({super.key});

  @override
  ConsumerState<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends ConsumerState<BookingsTab> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<Booking> _byStatus(List<Booking> all, String status) {
    return switch (status) {
      'upcoming' => all.where((b) => b.status == 'pending' || b.status == 'approved').toList(),
      'completed' => all.where((b) => b.status == 'completed').toList(),
      _ => all.where((b) => b.status == 'cancelled' || b.status == 'rejected').toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final key = watchSessionKey(ref);
    if (key == null) return const SizedBox.shrink();

    final async = ref.watch(userBookingsProvider(key));
    final bookings = async.valueOrNull ?? <Booking>[];
    final notifier = ref.read(userBookingsProvider(key).notifier);
    final showInitialSkeleton = async.isLoading && bookings.isEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(l10n.myBookings),
        actions: [
          IconButton(icon: const Icon(Icons.history_rounded), onPressed: () => context.goBookingHistory()),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: context.accentColor,
          labelColor: context.accentColor,
          unselectedLabelColor: context.inactiveColor,
          tabs: [
            Tab(text: l10n.bookingsUpcoming),
            Tab(text: l10n.bookingsCompleted),
            Tab(text: l10n.bookingsCancelled),
          ],
        ),
      ),
      body: showInitialSkeleton
          ? const BookingsListSkeleton()
          : async.hasError && bookings.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: ShellLayout.listPadding(context),
                  children: [
                    EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: l10n.retry,
                      subtitle: l10n.connectionLost,
                      actionLabel: l10n.retry,
                      onAction: () => ref.read(userBookingsProvider(key).notifier).refreshPreservingData(),
                    ),
                  ],
                )
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _BookingListKeepAlive(child: _list(_byStatus(bookings, 'upcoming'), key, l10n, notifier)),
                    _BookingListKeepAlive(child: _list(_byStatus(bookings, 'completed'), key, l10n, notifier)),
                    _BookingListKeepAlive(child: _list(_byStatus(bookings, 'cancelled'), key, l10n, notifier)),
                  ],
                ),
    );
  }

  Widget _list(List<Booking> bookings, UserSessionKey key, AppLocalizations l10n, UserBookingsNotifier notifier) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(userBookingsProvider(key).notifier).refreshPreservingData(),
        color: DesignTokens.primaryTeal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: ShellLayout.listPadding(context),
          children: [
            RefreshableEmptyState(
              icon: Icons.event_busy_rounded,
              title: l10n.noBookings,
              subtitle: l10n.noBookingsHint,
              onRefresh: () => ref.read(userBookingsProvider(key).notifier).refreshPreservingData(),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(userBookingsProvider(key).notifier).refreshPreservingData(),
      color: DesignTokens.primaryTeal,
      child: ListView.builder(
        padding: ShellLayout.listPadding(context).copyWith(top: DesignTokens.spaceSm),
        itemCount: bookings.length + (notifier.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == bookings.length) {
            return LoadMoreScrollNotification(
              hasMore: notifier.hasMore,
              loading: notifier.loadingMore,
              onLoadMore: () => notifier.loadMore(),
            );
          }
          final booking = bookings[i];
          final canCancel = booking.canCancel && BookingPolicy.canCancelBooking(booking);
          return UserBookingCard(
            booking: booking,
            canCancel: canCancel,
            onCancel: canCancel ? () => _cancel(booking, key) : null,
            onPay: booking.needsPayment ? () => _pay(booking) : null,
          );
        },
      ),
    );
  }

  Future<void> _pay(Booking booking) async {
    final paid = await context.goBookingCheckout(BookingCheckoutArgs(
      bookingId: booking.id,
      totalPrice: booking.totalPrice,
      fieldName: booking.fieldName,
      referenceCode: booking.referenceCode,
    ));
    if (paid == true && mounted) {
      final key = watchSessionKey(ref);
      if (key != null) {
        await ref.read(userBookingsProvider(key).notifier).refreshPreservingData();
      }
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

class _BookingListKeepAlive extends StatefulWidget {
  const _BookingListKeepAlive({required this.child});

  final Widget child;

  @override
  State<_BookingListKeepAlive> createState() => _BookingListKeepAliveState();
}

class _BookingListKeepAliveState extends State<_BookingListKeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
