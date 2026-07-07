import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/booking_actions_provider.dart';
import '../../../core/providers/owner_payment_provider.dart';
import '../../../core/providers/realtime_booking_sync.dart';
import '../../../core/utils/session_key_helper.dart';
import '../../../models/booking.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/signalr_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/design_tokens.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../utils/format.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/common.dart';
import '../../../widgets/connectivity_banner.dart';
import '../../../widgets/skeleton_loaders.dart';
import '../../../router/app_router.dart';
import '../../../widgets/stat_card.dart';
import 'widgets/owner_bookings_list.dart';

/// لوحة المالك — حجوزات pending/approved، صافي الأرباح، قبول/رفض مع حالة تحميل.
class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  String _filter = 'pending';
  int? _actionBookingId;
  ProviderSubscription<int>? _bookingEventsSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(connectOwnerSignalR(ref));
      _bookingEventsSub = ref.listenManual<int>(
        signalRProvider.select((s) => s.generation),
        (prev, next) {
          if (prev == null || next == prev || !mounted) return;
          final event = ref.read(signalRProvider).lastEvent;
          if (event == null) return;
          handleOwnerBookingRealtimeEvent(ref, context, event);
        },
      );
    });
  }

  @override
  void dispose() {
    _bookingEventsSub?.close();
    super.dispose();
  }

  List<OwnerBooking> _filtered(OwnerDashboard dash) => switch (_filter) {
        'pending' => dash.bookings.where((b) => b.status == 'pending').toList(),
        'approved' => dash.bookings.where((b) => b.status == 'approved').toList(),
        _ => dash.bookings.where((b) => b.status == 'pending' || b.status == 'approved').toList(),
      };

  Future<void> _onAction(int id, bool approve) async {
    if (!approve) {
      final l10n = context.l10n;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.rejectBooking),
          content: Text(l10n.rejectBookingConfirm),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: context.colors.error),
              child: Text(l10n.yesReject),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    final key = watchSessionKey(ref);
    if (key == null) return;

    setState(() => _actionBookingId = id);
    final l10n = context.l10n;
    try {
      final actions = ref.read(bookingActionsProvider(key));
      if (approve) {
        await actions.approveBooking(id);
      } else {
        await actions.rejectBooking(id);
      }
      if (!mounted) return;
      showAppSnackBar(context, approve ? l10n.bookingApprovedSnack : l10n.bookingRejectedSnack);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _actionBookingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final key = watchSessionKey(ref);
    if (key == null) return const SizedBox.shrink();

    final dashAsync = ref.watch(ownerDashboardProvider(key));
    final outstandingAmount = ref.watch(
      ownerPaymentAccountProvider(key).select((a) => a.valueOrNull?.outstandingAmount ?? 0),
    );
    final dash = dashAsync.valueOrNull;
    final loading = dashAsync.isLoading && dash == null;
    final filtered = dash == null ? <OwnerBooking>[] : _filtered(dash);

    return Scaffold(
      appBar: AppBar(
        title: Text(dash?.field.name ?? l10n.ownerDashboard),
        actions: [
          if (outstandingAmount > 0)
            IconButton(
              tooltip: l10n.payCommission,
              icon: Badge(
                label: Text('${outstandingAmount ~/ 1000}k'),
                child: const Icon(Icons.account_balance_wallet_outlined),
              ),
              onPressed: () => context.goOwnerCommissionCheckout(),
            ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () {
            ref.read(ownerDashboardProvider(key).notifier).refreshPreservingData();
            ref.invalidate(ownerPaymentAccountProvider(key));
          }),
        ],
      ),
      body: ConnectivityBanner(
        child: loading
            ? const OwnerDashboardSkeleton()
            : dash == null
                ? EmptyState(icon: Icons.error_outline_rounded, title: l10n.retry, subtitle: l10n.connectionLost)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RepaintBoundary(
                        child: FinanceSummaryCard(
                          totalRevenue: dash.totalRevenue,
                          commission: dash.appCommission,
                          netRevenue: dash.netRevenue,
                          pendingCount: dash.pendingCount,
                        ),
                      ),
                      if (outstandingAmount > 0)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: FilledButton.icon(
                            onPressed: () => context.goOwnerCommissionCheckout(),
                            icon: const Icon(Icons.payment_rounded),
                            label: Text(l10n.payCommissionAmount(formatMoney(outstandingAmount))),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                        child: Row(
                          children: [
                            StatCard(
                              expanded: true,
                              icon: Icons.payments_rounded,
                              label: l10n.netRevenue,
                              value: formatMoney(dash.netRevenue),
                              color: c.primary,
                            ),
                            const SizedBox(width: DesignTokens.spaceSm),
                            StatCard(
                              expanded: true,
                              icon: Icons.pending_actions_rounded,
                              label: l10n.pending,
                              value: '${dash.pendingCount}',
                              color: c.warning,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceMd),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _filterChip(l10n.pending, 'pending'),
                              _filterChip(l10n.approved, 'approved'),
                              _filterChip(l10n.all, 'all'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceSm),
                      Expanded(
                        child: OwnerBookingsList(
                          bookings: filtered,
                          actionBookingId: _actionBookingId,
                          onApprove: (id) => _onAction(id, true),
                          onReject: (id) => _onAction(id, false),
                          refreshColor: c.primary,
                          onRefresh: () async => ref.invalidate(ownerDashboardProvider(key)),
                          emptyWidget: EmptyState(
                            icon: Icons.inbox_rounded,
                            title: l10n.noOwnerBookings,
                            subtitle: l10n.noOwnerBookingsHint,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final c = context.colors;
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(left: DesignTokens.spaceSm),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: c.primary.withValues(alpha: 0.2),
        checkmarkColor: c.primary,
        labelStyle: TextStyle(
          color: selected ? c.onSurface : c.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
