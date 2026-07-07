import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/utils/session_key_helper.dart';
import '../../../services/admin_service.dart';
import '../../../theme/design_tokens.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../utils/format.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/common.dart';
import '../../../widgets/price_text.dart';
import '../../../widgets/premium/glass_surface.dart';
import '../../shell/shell_layout.dart';

class AdminRequestsTab extends ConsumerWidget {
  const AdminRequestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final key = watchSessionKey(ref);
    if (key == null) return const SizedBox.shrink();

    final pendingAsync = ref.watch(adminPendingBookingsProvider(key));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(l10n.ownerRequestsTab)),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          if (e is AdminForbiddenException) {
            return EmptyState(
              icon: Icons.lock_outline_rounded,
              title: l10n.retry,
              subtitle: e.message,
            );
          }
          return EmptyState(
            icon: Icons.error_outline_rounded,
            title: l10n.retry,
            subtitle: e.toString(),
          );
        },
        data: (bookings) {
          if (bookings.isEmpty) {
            return EmptyState(
              icon: Icons.inbox_rounded,
              title: l10n.noOwnerBookingsHint,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminPendingBookingsProvider(key)),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.spaceLg,
                DesignTokens.spaceLg,
                DesignTokens.spaceLg,
                ShellLayout.bottomInset(context),
              ),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final b = bookings[i];
                return GlassSurface(
                  borderRadius: DesignTokens.radiusLg,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: context.colors.primary.withValues(alpha: 0.15),
                      child: Icon(Icons.pending_actions_rounded, color: context.colors.primary),
                    ),
                    title: Text(b.fieldName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${b.userName} · ${DateFormat.yMMMd().add_jm().format(b.startTime.toLocal())} · ${b.hours}h',
                    ),
                    trailing: PriceText(
                      formatMoney(b.totalPrice),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
