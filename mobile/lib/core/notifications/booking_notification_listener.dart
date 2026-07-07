import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/booking_push_payload.dart';
import '../../providers/push_notification_provider.dart';
import '../../router/navigation_keys.dart';
import 'booking_notification_coordinator.dart';

/// Listens to [pushNotificationProvider] and surfaces booking status alerts in-app.
class BookingNotificationListener extends ConsumerWidget {
  const BookingNotificationListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(pushNotificationProvider.select((s) => s.generation), (prev, next) {
      if (prev == next) return;
      try {
        final message = ref.read(pushNotificationProvider).lastMessage;
        if (message == null) return;
        final payload = BookingPushPayload.fromMessage(message);
        if (!payload.isBookingStatusChange) return;

        final ctx = rootNavigatorKey.currentContext ?? context;
        if (!ctx.mounted) return;
        BookingNotificationCoordinator.handleForeground(ref, ctx, message);
      } catch (_) {
        // Never crash the widget tree on malformed push payloads.
      }
    });

    return child;
  }
}
