import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/session_key.dart';
import '../theme/design_tokens.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/l10n_extension.dart';
import '../utils/error_messages.dart';
import '../widgets/common.dart';
import '../widgets/history_booking_card.dart';
import '../widgets/load_more_footer.dart';
import '../widgets/skeleton_loaders.dart';

enum _HistoryFilter { all, pending, approved, completed, cancelled }

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  List<Booking> _filtered(List<Booking> bookings) {
    final now = DateTime.now();
    return switch (_filter) {
      _HistoryFilter.pending => bookings.where((b) => b.status == 'pending').toList(),
      _HistoryFilter.approved => bookings.where((b) => b.status == 'approved' && b.endTime.isAfter(now)).toList(),
      _HistoryFilter.completed => bookings.where((b) => b.status == 'approved' && !b.endTime.isAfter(now)).toList(),
      _HistoryFilter.cancelled => bookings.where((b) => b.status == 'cancelled' || b.status == 'rejected').toList(),
      _HistoryFilter.all => bookings,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final client = ref.watch(apiClientProvider);
    final userId = ref.watch(authProvider).user!.id;
    final key = UserSessionKey(client: client, userId: userId);
    final historyAsync = ref.watch(bookingHistoryProvider(key));
    final statsAsync = ref.watch(userStatsProvider(key));
    final historyNotifier = ref.read(bookingHistoryProvider(key).notifier);
    final bookings = historyAsync.valueOrNull ?? [];
    final filtered = _filtered(bookings);
    final totalHours = statsAsync.valueOrNull?.totalHoursBooked ?? 0;
    final loading = historyAsync.isLoading && bookings.isEmpty;
    final hasError = historyAsync.hasError && bookings.isEmpty;

    return RtlScaffold(
      appBar: AppBar(title: Text(l10n.bookingHistory)),
      body: loading
          ? const BookingsListSkeleton()
          : hasError
              ? RefreshableEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: l10n.retry,
                  subtitle: friendlyErrorMessage(historyAsync.error),
                  onRefresh: () {
                    ref.invalidate(bookingHistoryProvider(key));
                    ref.invalidate(userStatsProvider(key));
                  },
                )
              : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(bookingHistoryProvider(key));
                ref.invalidate(userStatsProvider(key));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: TotalHoursBanner(totalHours: totalHours)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceMd, DesignTokens.spaceSm, DesignTokens.spaceMd, DesignTokens.spaceSm),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _chip(l10n.all, _HistoryFilter.all),
                            _chip(l10n.statusPendingApproval, _HistoryFilter.pending),
                            _chip(l10n.approved, _HistoryFilter.approved),
                            _chip(l10n.statusCompleted, _HistoryFilter.completed),
                            _chip(l10n.statusCancelled, _HistoryFilter.cancelled),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.history_rounded,
                        title: l10n.noBookings,
                        subtitle: l10n.noBookingsHint,
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          if (i == filtered.length) {
                            return LoadMoreScrollNotification(
                              hasMore: historyNotifier.hasMore,
                              loading: historyNotifier.loadingMore,
                              onLoadMore: () => historyNotifier.loadMore(),
                            );
                          }
                          return HistoryBookingCard(booking: filtered[i]);
                        },
                        childCount: filtered.length + (historyNotifier.hasMore ? 1 : 0),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.spaceLg)),
                ],
              ),
            ),
    );
  }

  Widget _chip(String label, _HistoryFilter value) {
    final c = context.colors;
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: DesignTokens.spaceSm),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        labelStyle: TextStyle(
          color: selected ? c.onPrimary : c.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
