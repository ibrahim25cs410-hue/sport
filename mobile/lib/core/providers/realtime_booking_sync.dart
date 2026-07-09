import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/realtime_booking_event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/session_key.dart';
import '../../providers/socket_provider.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/realtime_l10n.dart';
import '../../theme/riyada_theme_extension.dart';
import '../../widgets/premium/realtime_toast.dart';

/// Socket.io connection for regular users.
Future<void> connectUserRealtime(WidgetRef ref) async {
  final user = ref.read(authProvider).user;
  if (user == null || user.role != 'user') return;
  try {
    await ref.read(socketProvider.notifier).ensureConnected();
  } catch (_) {}
}

/// Socket.io connection for owners — joins their primary field room when available.
Future<void> connectOwnerRealtime(WidgetRef ref) async {
  final user = ref.read(authProvider).user;
  final fieldId = ref.read(authProvider).ownerField?.id;
  if (user == null) return;

  try {
    await ref.read(socketProvider.notifier).ensureConnected();
    if (fieldId != null) {
      ref.read(socketProvider.notifier).joinField(fieldId);
    }
  } catch (_) {}
}

void handleUserBookingRealtimeEvent(WidgetRef ref, BuildContext context, BookingUpdatedEvent event) {
  if (!context.mounted) return;

  final user = ref.read(authProvider).user;
  if (user == null || user.role != 'user') return;

  final session = UserSessionKey(client: ref.read(apiServiceProvider), userId: user.id);
  final bookings = ref.read(userBookingsProvider(session));

  if (bookings.hasValue && event.bookingId > 0) {
    ref.read(userBookingsProvider(session).notifier).optimisticUpdateStatus(event.bookingId, event.status);
  } else {
    unawaited(ref.read(userBookingsProvider(session).notifier).refreshPreservingData());
  }

  final l10n = context.l10n;
  if (event.titleKey == 'rtTitleBookingApproved' ||
      event.status == 'approved' ||
      event.status == 'confirmed') {
    showRealtimeToast(
      context,
      title: localizeRealtimeTitle(l10n, event.titleKey),
      message: localizeRealtimeMessage(l10n, event),
      icon: Icons.verified_rounded,
    );
  } else if (event.titleKey == 'rtTitleBookingRejected' || event.status == 'rejected') {
    showRealtimeToast(
      context,
      title: localizeRealtimeTitle(l10n, event.titleKey),
      message: localizeRealtimeMessage(l10n, event),
      icon: Icons.info_outline_rounded,
      accent: context.colors.warningSurface,
    );
  }
}

void handleOwnerBookingRealtimeEvent(WidgetRef ref, BuildContext context, BookingUpdatedEvent event) {
  if (!context.mounted) return;

  final user = ref.read(authProvider).user;
  if (user == null || user.role != 'owner') return;

  final session = UserSessionKey(client: ref.read(apiServiceProvider), userId: user.id);
  final dash = ref.read(ownerDashboardProvider(session));

  if (dash.hasValue && event.bookingId > 0) {
    ref.read(ownerDashboardProvider(session).notifier).optimisticUpdateBookingStatus(event.bookingId, event.status);
  } else {
    unawaited(ref.read(ownerDashboardProvider(session).notifier).refreshPreservingData());
  }

  final l10n = context.l10n;
  if (event.titleKey == 'rtTitleNewBooking' || event.status == 'pending') {
    showRealtimeToast(
      context,
      title: localizeRealtimeTitle(l10n, event.titleKey),
      message: localizeRealtimeMessage(l10n, event),
      icon: Icons.notifications_active_rounded,
    );
  }
}

/// Coalesces rapid booking events into a single UI update.
class RealtimeEventCoalescer {
  RealtimeEventCoalescer({this.delay = const Duration(milliseconds: 450)});

  final Duration delay;
  Timer? _timer;
  BookingUpdatedEvent? _latest;

  void schedule(BookingUpdatedEvent event, void Function(BookingUpdatedEvent event) onFire) {
    _latest = event;
    _timer?.cancel();
    _timer = Timer(delay, () {
      final latest = _latest;
      _latest = null;
      if (latest != null) onFire(latest);
    });
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _latest = null;
  }
}
