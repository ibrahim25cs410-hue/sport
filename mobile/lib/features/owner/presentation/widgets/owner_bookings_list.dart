import 'package:flutter/material.dart';

import '../../../../models/booking.dart';
import '../../../../widgets/premium/owner_booking_card.dart';
import '../../../shell/shell_layout.dart';
import '../../../../theme/design_tokens.dart';

/// قائمة حجوزات المالك — معزولة لتقليل إعادة البناء عند تحديث الملخص المالي.
class OwnerBookingsList extends StatelessWidget {
  const OwnerBookingsList({
    super.key,
    required this.bookings,
    required this.actionBookingId,
    required this.onApprove,
    required this.onReject,
    required this.refreshColor,
    required this.onRefresh,
    required this.emptyWidget,
  });

  final List<OwnerBooking> bookings;
  final int? actionBookingId;
  final void Function(int id) onApprove;
  final void Function(int id) onReject;
  final Color refreshColor;
  final Future<void> Function() onRefresh;
  final Widget emptyWidget;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) return emptyWidget;
    return RefreshIndicator(
      color: refreshColor,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: ShellLayout.listPadding(context).copyWith(top: DesignTokens.spaceSm),
        itemCount: bookings.length,
        itemBuilder: (_, i) {
          final b = bookings[i];
          final busy = actionBookingId == b.id;
          return RepaintBoundary(
            child: OwnerBookingCard(
              booking: b,
              busy: busy,
              onApprove: () => onApprove(b.id),
              onReject: () => onReject(b.id),
            ),
          );
        },
      ),
    );
  }
}
