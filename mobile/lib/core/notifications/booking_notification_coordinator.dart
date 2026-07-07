import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/session_key.dart';
import '../../router/app_router.dart';
import '../../router/navigation_keys.dart';
import '../../theme/riyada_theme_extension.dart';
import '../../utils/l10n_extension.dart';
import '../../widgets/premium/realtime_toast.dart';
import '../../data/datasources/remote/booking_push_payload.dart';

/// Reacts to FCM booking pushes — refreshes lists, shows in-app toast, navigates on tap.
abstract final class BookingNotificationCoordinator {
  static void handleForeground(WidgetRef ref, BuildContext context, RemoteMessage message) {
    final payload = BookingPushPayload.fromMessage(message);
    if (!payload.isBookingStatusChange) return;

    _syncBookingData(payload, read: ref.read, invalidate: ref.invalidate);
    if (!context.mounted) return;
    _showInAppAlert(context, payload);
  }

  static void handleOpened(ProviderContainer container, RemoteMessage message) {
    final payload = BookingPushPayload.fromMessage(message);
    _syncBookingData(payload, read: container.read, invalidate: container.invalidate);

    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    if (payload.isBookingStatusChange) {
      GoRouter.of(ctx).go(AppRoutes.userHome);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final next = rootNavigatorKey.currentContext;
        if (next != null && next.mounted) {
          next.goNotifications();
        }
      });
    } else {
      ctx.goNotifications();
    }
  }

  static void _syncBookingData(
    BookingPushPayload payload, {
    required T Function<T>(ProviderListenable<T> provider) read,
    required void Function(ProviderBase<Object?> provider) invalidate,
  }) {
    final user = read(authProvider).user;
    if (user == null) return;

    final session = UserSessionKey(client: read(apiClientProvider), userId: user.id);
    invalidate(userNotificationsProvider(session));

    if (!payload.isBookingStatusChange) return;

    final bookings = read(userBookingsProvider(session));
    if (payload.bookingId != null &&
        payload.bookingStatus != null &&
        bookings.hasValue) {
      read(userBookingsProvider(session).notifier)
          .optimisticUpdateStatus(payload.bookingId!, payload.bookingStatus!);
    } else {
      invalidate(userBookingsProvider(session));
    }

    if (user.isOwner) {
      invalidate(ownerDashboardProvider(session));
    }
  }

  static void _showInAppAlert(BuildContext context, BookingPushPayload payload) {
    final l10n = context.l10n;
    final (icon, accent) = switch (payload.type) {
      BookingPushPayload.bookingApproved => (Icons.verified_rounded, null),
      BookingPushPayload.bookingRejected => (Icons.info_outline_rounded, context.colors.warningSurface),
      BookingPushPayload.bookingPending => (Icons.notifications_active_rounded, null),
      BookingPushPayload.bookingCancelled => (Icons.event_busy_rounded, null),
      _ => (Icons.notifications_rounded, null),
    };

    showRealtimeToast(
      context,
      title: payload.title,
      message: payload.body.isNotEmpty ? payload.body : l10n.notifications,
      icon: icon,
      accent: accent,
    );
  }
}

/// Encodes [BookingPushPayload] for local notification tap routing.
String encodeNotificationPayload(BookingPushPayload payload) => jsonEncode({
      'type': payload.type,
      if (payload.bookingId != null) 'bookingId': payload.bookingId,
    });

BookingPushPayload? decodeNotificationPayload(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return BookingPushPayload(
      type: map['type'] as String? ?? 'general',
      title: 'Riyada',
      body: '',
      bookingId: map['bookingId'] is int
          ? map['bookingId'] as int
          : int.tryParse(map['bookingId']?.toString() ?? ''),
    );
  } catch (_) {
    return null;
  }
}
