import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/booking_actions_provider.dart';
import '../../../core/utils/session_key_helper.dart';
import '../../../providers/booking_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/common.dart';
import '../../shell/shell_layout.dart';
import 'widgets/owner_bookings_list.dart';

/// طلبات الحجز الجديدة — للمالك (تبويب حجز جديد).
class OwnerRequestsTab extends ConsumerStatefulWidget {
  const OwnerRequestsTab({super.key});

  @override
  ConsumerState<OwnerRequestsTab> createState() => _OwnerRequestsTabState();
}

class _OwnerRequestsTabState extends ConsumerState<OwnerRequestsTab> with AutomaticKeepAliveClientMixin {
  int? _busyId;

  @override
  bool get wantKeepAlive => true;

  Future<void> _action(int id, bool approve) async {
    final key = watchSessionKey(ref);
    if (key == null) return;
    setState(() => _busyId = id);
    final l10n = context.l10n;
    try {
      final actions = ref.read(bookingActionsProvider(key));
      if (approve) {
        await actions.approveBooking(id);
      } else {
        await actions.rejectBooking(id);
      }
      if (mounted) showAppSnackBar(context, approve ? l10n.bookingApprovedSnack : l10n.bookingRejectedSnack);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final c = context.colors;
    final key = watchSessionKey(ref);
    if (key == null) return const SizedBox.shrink();

    final dashAsync = ref.watch(ownerDashboardProvider(key));
    final dash = dashAsync.valueOrNull;
    final pending = dash?.bookings.where((b) => b.status == 'pending').toList() ?? [];
    final loading = dashAsync.isLoading && dash == null;

    Future<void> refresh() => ref.read(ownerDashboardProvider(key).notifier).refreshPreservingData();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newBookingTab)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : dashAsync.hasError && dash == null
              ? RefreshableEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: l10n.connectionLost,
                  subtitle: l10n.retry,
                  onRefresh: refresh,
                )
              : OwnerBookingsList(
              bookings: pending,
              actionBookingId: _busyId,
              onApprove: (id) => _action(id, true),
              onReject: (id) => _action(id, false),
              refreshColor: c.primary,
              onRefresh: refresh,
              emptyWidget: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: ShellLayout.listPadding(context),
                children: [
                  EmptyState(icon: Icons.inbox_rounded, title: l10n.noOwnerBookings, subtitle: l10n.noOwnerBookingsHint),
                ],
              ),
            ),
    );
  }
}
