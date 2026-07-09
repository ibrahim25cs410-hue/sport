import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import '../models/booking.dart';
import '../models/notification.dart';
import '../models/realtime_booking_event.dart';
import '../core/providers/booking_actions_provider.dart';
import '../core/providers/realtime_booking_sync.dart';
import '../core/providers/repository_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/session_key.dart';
import '../providers/socket_provider.dart';
import '../widgets/skeleton_loaders.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/l10n_extension.dart';
import '../../../widgets/premium/owner_booking_card.dart';
import '../widgets/common.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/notifications_list.dart';
import '../widgets/stat_card.dart';
import '../router/app_router.dart';

class OwnerHomeScreen extends ConsumerStatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  ConsumerState<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends ConsumerState<OwnerHomeScreen> with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 30);

  int _tab = 0;
  String _filter = 'all';
  Timer? _pollTimer;
  int? _actionBookingId;
  ConnectivityProvider? _connectivity;
  UserSessionKey? _sessionKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final client = ref.read(apiClientProvider);
    _connectivity = context.read<ConnectivityProvider>();
    _connectivity!.start(client);
    _sessionKey = UserSessionKey(client: client, userId: ref.read(authProvider).user!.id);
    setState(() {});

    try {
      await ref.read(socketProvider.notifier).ensureConnected();
      final fieldId = ref.read(authProvider).ownerField?.id;
      if (fieldId != null) {
        ref.read(socketProvider.notifier).joinField(fieldId);
      }
    } catch (_) {}

    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _connectivity?.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pollQuiet();
      _startPolling();
      unawaited(ref.read(socketProvider.notifier).ensureConnected());
    } else if (state == AppLifecycleState.paused) {
      _pollTimer?.cancel();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollQuiet());
  }

  Future<void> _refreshData() async {
    final key = _sessionKey;
    if (key == null) return;
    await Future.wait([
      ref.read(ownerDashboardProvider(key).notifier).refreshPreservingData(),
      ref.refresh(userNotificationsProvider(key).future),
    ]);
  }

  void _invalidateData() {
    final key = _sessionKey;
    if (key == null) return;
    ref.invalidate(ownerDashboardProvider(key));
    ref.invalidate(userNotificationsProvider(key));
  }

  Future<void> _pollQuiet() async {
    if (!mounted || _sessionKey == null) return;
    if (ref.read(socketProvider).status == RealtimeConnectionStatus.connected) return;
    _invalidateData();
  }

  Future<void> _action(int id, bool approve) async {
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

    setState(() => _actionBookingId = id);
    final l10n = context.l10n;
    final key = _sessionKey;
    if (key == null) return;
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
      if (!mounted) return;
      showAppError(context, e);
    } finally {
      if (mounted) setState(() => _actionBookingId = null);
    }
  }

  List<OwnerBooking> _filteredBookings(OwnerDashboard dash) => switch (_filter) {
        'pending' => dash.bookings.where((b) => b.status == 'pending').toList(),
        'approved' => dash.bookings.where((b) => b.status == 'approved').toList(),
        _ => dash.bookings,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final key = _sessionKey;

    ref.listen<int>(socketProvider.select((s) => s.generation), (prev, next) {
      if (prev == null || next == prev || key == null) return;
      final event = ref.read(socketProvider).lastEvent;
      if (event == null) return;
      handleOwnerBookingRealtimeEvent(ref, context, event);
    });

    final dashAsync = key == null ? null : ref.watch(ownerDashboardProvider(key));
    final notifsAsync = key == null ? null : ref.watch(userNotificationsProvider(key));
    final isReloading = dashAsync?.isLoading == true && dashAsync?.hasValue == true;
    final dash = isReloading && _actionBookingId != null ? null : dashAsync?.valueOrNull;
    final notifications = notifsAsync?.valueOrNull ?? <AppNotification>[];
    final unread = notifications.where((n) => !n.isRead).length;
    final loading = key == null || (dashAsync?.isLoading == true && dash == null);

    return RtlScaffold(
      appBar: AppBar(
        title: Text(dash?.field.name ?? l10n.ownerDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_rounded),
            onPressed: () => context.goProfile(),
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => unawaited(_refreshData())),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(socketProvider.notifier).disconnect();
              await ref.read(authServiceProvider).logout();
              await ref.read(authProvider.notifier).clearSession();
              if (!context.mounted) return;
              context.goLoginClearStack();
            },
          ),
        ],
      ),
      body: ConnectivityBanner(
        child: loading
            ? const OwnerDashboardSkeleton()
            : dash == null
                ? EmptyState(icon: Icons.error_outline_rounded, title: l10n.retry, subtitle: l10n.connectionLost)
                : IndexedStack(
                    index: _tab,
                    children: [
                      _bookingsTab(dash, isReloading: isReloading),
                      _notificationsTab(notifsAsync, notifications),
                    ],
                  ),
      ),
      bottomNavigationBar: RiyadaNavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: Badge(
              label: Text('${dash?.pendingCount ?? 0}'),
              isLabelVisible: (dash?.pendingCount ?? 0) > 0,
              child: const Icon(Icons.inbox_outlined),
            ),
            selectedIcon: const Icon(Icons.inbox_rounded),
            label: l10n.bookings,
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$unread'),
              isLabelVisible: unread > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: const Icon(Icons.notifications_rounded),
            label: l10n.notifications,
          ),
        ],
      ),
    );
  }

  Widget _bookingsTab(OwnerDashboard dash, {bool isReloading = false}) {
    final l10n = context.l10n;
    final c = context.colors;
    final filtered = _filteredBookings(dash);

    return RefreshIndicator(
      onRefresh: () async => _invalidateData(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FinanceSummaryCard(
              totalRevenue: dash.totalRevenue,
              commission: dash.appCommission,
              netRevenue: dash.netRevenue,
              pendingCount: dash.pendingCount,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  StatCard(
                    expanded: true,
                    icon: Icons.pending_actions_rounded,
                    label: l10n.pending,
                    value: '${dash.pendingCount}',
                    color: c.warning,
                  ),
                  const SizedBox(width: 10),
                  StatCard(
                    expanded: true,
                    icon: Icons.event_available_rounded,
                    label: l10n.totalBookings,
                    value: '${dash.bookings.length}',
                    color: c.primaryLight,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(l10n.all, 'all'),
                    _filterChip(l10n.pending, 'pending'),
                    _filterChip(l10n.approved, 'approved'),
                  ],
                ),
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: EmptyState(
                icon: Icons.inbox_rounded,
                title: l10n.noOwnerBookings,
                subtitle: l10n.noOwnerBookingsHint,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final b = filtered[i];
                  final busy = _actionBookingId == b.id || isReloading;
                  return OwnerBookingCard(
                    booking: b,
                    busy: busy,
                    onApprove: () => _action(b.id, true),
                    onReject: () => _action(b.id, false),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _notificationsTab(AsyncValue<List<AppNotification>>? async, List<AppNotification> notifications) {
    if (async?.isLoading == true && notifications.isEmpty) {
      return const NotificationsListSkeleton();
    }
    return RefreshIndicator(
      onRefresh: () async => _invalidateData(),
      child: NotificationsList(
        notifications: notifications,
        showMarkAll: true,
        onMarkAllRead: () async {
          final userId = ref.read(authProvider).user!.id;
          await ref.read(notificationRepositoryProvider(ref.read(apiClientProvider))).markAllRead(userId);
          unawaited(_refreshData());
        },
        onTap: (n) async {
          if (!n.isRead) {
            await ref.read(notificationRepositoryProvider(ref.read(apiClientProvider))).markRead(n.id);
            unawaited(_refreshData());
          }
        },
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
        labelStyle: TextStyle(
          color: selected ? c.onPrimary : c.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
