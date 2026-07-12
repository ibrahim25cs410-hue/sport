import 'package:flutter/material.dart';

import '../../../../models/booking.dart';
import '../../../../widgets/premium/owner_booking_card.dart';
import '../../../shell/shell_layout.dart';
import '../../../../theme/design_tokens.dart';

/// قائمة حجوزات المالك — مجمّعة حسب الملعب (لا تُدمج ملاعب مختلفة معاً).
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
  final void Function(OwnerBooking booking) onApprove;
  final void Function(OwnerBooking booking) onReject;
  final Color refreshColor;
  final Future<void> Function() onRefresh;
  final Widget emptyWidget;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) return emptyWidget;

    final grouped = <int, List<OwnerBooking>>{};
    final names = <int, String>{};
    for (final b in bookings) {
      final key = b.fieldId != 0 ? b.fieldId : (b.fieldName.hashCode);
      grouped.putIfAbsent(key, () => []).add(b);
      if (b.fieldName.isNotEmpty) names[key] = b.fieldName;
    }
    final keys = grouped.keys.toList();
    final showHeaders = keys.length > 1 ||
        (keys.length == 1 && (names[keys.first]?.isNotEmpty ?? false));

    final children = <Widget>[];
    for (final key in keys) {
      final list = grouped[key]!;
      final name = names[key] ?? '';
      if (showHeaders && name.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spaceLg,
              DesignTokens.spaceMd,
              DesignTokens.spaceLg,
              DesignTokens.spaceXs,
            ),
            child: Text(
              name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        );
      }
      for (final b in list) {
        final busy = actionBookingId == b.id;
        children.add(
          RepaintBoundary(
            child: OwnerBookingCard(
              booking: b,
              busy: busy,
              onApprove: () => onApprove(b),
              onReject: () => onReject(b),
            ),
          ),
        );
      }
    }

    return RefreshIndicator(
      color: refreshColor,
      onRefresh: onRefresh,
      child: ListView(
        padding: ShellLayout.listPadding(context).copyWith(top: DesignTokens.spaceSm),
        children: children,
      ),
    );
  }
}
