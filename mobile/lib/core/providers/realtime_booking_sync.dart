import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/signalr_config.dart';
import '../../models/realtime_booking_event.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/session_key.dart';
import '../../providers/signalr_provider.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/realtime_l10n.dart';
import '../../theme/riyada_theme_extension.dart';
import '../../widgets/premium/realtime_toast.dart';

/// اتصال SignalR للمستخدم — يُستدعى مرة واحدة من initState.
Future<void> connectUserSignalR(WidgetRef ref) async {
  final user = ref.read(authProvider).user;
  if (user == null || user.role != 'user') return;

  final client = ref.read(apiClientProvider);
  try {
    await ref.read(signalRProvider.notifier).ensureConnected(
          hubUrl: SignalRConfig.hubUrlFromApiBase(client.baseUrl),
          getToken: client.getToken,
        );
  } catch (_) {}
}

/// معالجة حدث حجز لحظي — تحديث تدريجي بدون طلبات متكررة.
void handleUserBookingRealtimeEvent(WidgetRef ref, BuildContext context, BookingUpdatedEvent event) {
  if (!context.mounted) return;

  final user = ref.read(authProvider).user;
  if (user == null || user.role != 'user') return;

  final session = UserSessionKey(client: ref.read(apiClientProvider), userId: user.id);
  final bookings = ref.read(userBookingsProvider(session));

  if (bookings.hasValue && event.bookingId > 0) {
    ref.read(userBookingsProvider(session).notifier).optimisticUpdateStatus(event.bookingId, event.status);
  } else {
    unawaited(ref.read(userBookingsProvider(session).notifier).refreshPreservingData());
  }

  final l10n = context.l10n;
  if (event.titleKey == 'rtTitleBookingApproved' || event.status == 'approved') {
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

/// معالجة حدث حجز لحظي للمالك — تحديث اللوحة فوراً.
void handleOwnerBookingRealtimeEvent(WidgetRef ref, BuildContext context, BookingUpdatedEvent event) {
  if (!context.mounted) return;

  final user = ref.read(authProvider).user;
  if (user == null || user.role != 'owner') return;

  final session = UserSessionKey(client: ref.read(apiClientProvider), userId: user.id);
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

/// للمالك — انضمام لمجموعة الملعب وتحديث اللوحة.
Future<void> connectOwnerSignalR(WidgetRef ref) async {
  final user = ref.read(authProvider).user;
  final fieldId = ref.read(authProvider).ownerField?.id;
  if (user == null || fieldId == null) return;

  final client = ref.read(apiClientProvider);
  try {
    await ref.read(signalRProvider.notifier).ensureConnected(
          hubUrl: SignalRConfig.hubUrlFromApiBase(client.baseUrl),
          getToken: client.getToken,
        );
    await ref.read(signalRProvider.notifier).joinField(fieldId);
  } catch (_) {}
}

/// يدمج أحداث SignalR المتتالية في معالجة واحدة.
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
