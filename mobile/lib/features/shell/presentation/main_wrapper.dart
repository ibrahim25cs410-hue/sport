import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;

import '../../../core/providers/realtime_booking_sync.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/connectivity_provider.dart';
import '../../../providers/signalr_provider.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/brand/floating_bottom_navigation_bar.dart';
import '../../../widgets/brand/riyada_nav_icon.dart';
import '../../admin/presentation/admin_dashboard_tab.dart';
import '../../admin/presentation/admin_financials_tab.dart';
import '../../admin/presentation/admin_requests_tab.dart';
import '../../admin/presentation/admin_settings_tab.dart';
import '../../bookings/presentation/bookings_tab.dart';
import '../../home/presentation/home_tab.dart';
import '../../owner/presentation/owner_accounts_tab.dart';
import '../../owner/presentation/owner_home_tab.dart';
import '../../owner/presentation/owner_requests_tab.dart';
import '../../owner/presentation/owner_wallet_tab.dart';
import '../../profile/presentation/profile_tab.dart';
import '../../../widgets/connectivity_banner.dart';
import '../lazy_shell_tab.dart';
import '../shell_state.dart';

/// Role-aware shell — renders the correct bottom navigation for user, owner, or admin.
class MainWrapper extends ConsumerStatefulWidget {
  const MainWrapper({super.key, this.initialIndex = 0, this.shellRouteChild});

  final int initialIndex;
  final Widget? shellRouteChild;

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

enum _ShellRole { user, owner, admin }

class _MainWrapperState extends ConsumerState<MainWrapper> {
  ProviderSubscription<int>? _bookingEventsSub;
  ProviderSubscription<String?>? _roleSub;
  final _realtimeCoalescer = RealtimeEventCoalescer();

  static const _userTabChildren = [
    HomeTab(),
    BookingsTab(),
    ProfileTab(),
  ];

  static const _ownerTabChildren = [
    OwnerHomeTab(),
    OwnerRequestsTab(),
    OwnerWalletTab(),
    OwnerAccountsTab(),
    ProfileTab(),
  ];

  static const _adminTabChildren = [
    AdminDashboardTab(),
    AdminRequestsTab(),
    AdminFinancialsTab(),
    AdminSettingsTab(),
  ];

  _ShellRole _roleFor(String? role) => switch (role) {
        'admin' => _ShellRole.admin,
        'owner' => _ShellRole.owner,
        _ => _ShellRole.user,
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onReady());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _roleSub ??= ref.listenManual<String?>(
      authProvider.select((a) => a.role),
      (prev, next) {
        if (prev == next) return;
        ref.read(shellTabProvider.notifier).select(0);
      },
    );
  }

  Future<void> _onReady() async {
    if (!mounted) return;
    final role = _roleFor(ref.read(authProvider).role);
    if (role == _ShellRole.owner) {
      unawaited(connectOwnerSignalR(ref));
    } else if (role == _ShellRole.user) {
      unawaited(connectUserSignalR(ref));
    }
    if (role != _ShellRole.admin) {
      _bookingEventsSub = ref.listenManual<int>(
        signalRProvider.select((s) => s.generation),
        (prev, next) {
          if (prev == null || next == prev || !mounted) return;
          final event = ref.read(signalRProvider).lastEvent;
          if (event == null) return;
          _realtimeCoalescer.schedule(event, (latest) {
            if (!mounted) return;
            final owner = ref.read(authProvider).user?.isOwner ?? false;
            if (owner) {
              handleOwnerBookingRealtimeEvent(ref, context, latest);
            } else {
              handleUserBookingRealtimeEvent(ref, context, latest);
            }
          });
        },
      );
    }
    ref.read(shellTabProvider.notifier).select(widget.initialIndex);
    if (mounted) {
      legacy.Provider.of<ConnectivityProvider>(context, listen: false).start(ref.read(apiClientProvider));
    }
  }

  @override
  void dispose() {
    _bookingEventsSub?.close();
    _roleSub?.close();
    _realtimeCoalescer.dispose();
    try {
      legacy.Provider.of<ConnectivityProvider>(context, listen: false).stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(authProvider);
    final role = _roleFor(auth.role);

    if (auth.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tab = ref.watch(shellTabProvider);

    final labels = switch (role) {
      _ShellRole.admin => [
          l10n.adminDashboard,
          l10n.ownerRequestsTab,
          l10n.financialSummary,
          l10n.settings,
        ],
      _ShellRole.owner => [
          l10n.homeTab,
          l10n.ownerRequestsTab,
          l10n.walletTab,
          l10n.accountsTab,
          l10n.profileTab,
        ],
      _ShellRole.user => [
          l10n.homeTab,
          l10n.myBookings,
          l10n.profileTab,
        ],
    };

    final icons = switch (role) {
      _ShellRole.admin => const [
          RiyadaNavIcon.home,
          RiyadaNavIcon.bookings,
          RiyadaNavIcon.accounts,
          RiyadaNavIcon.profile,
        ],
      _ShellRole.owner => const [
          RiyadaNavIcon.home,
          RiyadaNavIcon.bookings,
          RiyadaNavIcon.accounts,
          RiyadaNavIcon.explore,
          RiyadaNavIcon.profile,
        ],
      _ShellRole.user => const [
          RiyadaNavIcon.home,
          RiyadaNavIcon.bookings,
          RiyadaNavIcon.profile,
        ],
    };

    final children = switch (role) {
      _ShellRole.admin => _adminTabChildren,
      _ShellRole.owner => _ownerTabChildren,
      _ShellRole.user => _userTabChildren,
    };

    final tabs = List.generate(children.length, (i) {
      return LazyShellTab(
        key: ValueKey('${role.name}-tab-$i'),
        index: i,
        activeIndex: tab.clamp(0, children.length - 1),
        child: children[i],
      );
    });

    final activeTab = tab.clamp(0, children.length - 1);

    return ConnectivityBanner(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Scaffold(
            extendBody: true,
            body: IndexedStack(index: activeTab, children: tabs),
            bottomNavigationBar: FloatingBottomNavigationBar(
              selectedIndex: activeTab,
              onSelected: (i) {
                if (i == activeTab) return;
                ref.read(shellTabProvider.notifier).select(i);
              },
              labels: labels,
              icons: icons,
            ),
          ),
          if (widget.shellRouteChild != null)
            Positioned(
              left: 0,
              top: 0,
              width: 1,
              height: 1,
              child: IgnorePointer(child: widget.shellRouteChild!),
            ),
        ],
      ),
    );
  }
}
