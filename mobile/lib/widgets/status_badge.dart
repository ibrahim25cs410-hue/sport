import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/l10n_extension.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.label});
  final String status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final (color, labelFromStatus, icon) = switch (status) {
      'pending' => (c.warning, l10n.statusPendingApproval, Icons.hourglass_top_rounded),
      'approved' => (c.success, l10n.approved, Icons.check_circle_rounded),
      'rejected' => (c.error, l10n.statusRejected, Icons.cancel_rounded),
      'cancelled' => (c.neutral, l10n.statusCancelled, Icons.block_rounded),
      _ => (c.info, status, Icons.info_outline_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label ?? labelFromStatus, style: GoogleFonts.cairo(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}
