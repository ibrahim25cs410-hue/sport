import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/l10n_extension.dart';
import '../utils/relative_time.dart';
import 'common.dart';

class NotificationsList extends StatelessWidget {
  const NotificationsList({
    super.key,
    required this.notifications,
    required this.onTap,
    this.onMarkAllRead,
    this.showMarkAll = false,
    this.footer,
  });

  final List<AppNotification> notifications;
  final void Function(AppNotification n) onTap;
  final VoidCallback? onMarkAllRead;
  final bool showMarkAll;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;

    if (notifications.isEmpty) {
      return ListView(
        children: [EmptyState(icon: Icons.notifications_none_rounded, title: l10n.noNotifications)],
      );
    }

    final unread = notifications.where((n) => !n.isRead).length;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: notifications.length + (showMarkAll && unread > 0 ? 1 : 0) + (footer != null ? 1 : 0),
      itemBuilder: (_, i) {
        final markAllSlot = showMarkAll && unread > 0 ? 1 : 0;
        if (showMarkAll && unread > 0 && i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onMarkAllRead,
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: Text(l10n.markAllReadCount(unread)),
              ),
            ),
          );
        }
        if (footer != null && i == notifications.length + markAllSlot) {
          return footer!;
        }
        final idx = i - markAllSlot;
        final n = notifications[idx];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            color: n.isRead ? c.card : c.primary.withValues(alpha: 0.06),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: n.isRead ? c.surfaceVariant : c.primary.withValues(alpha: 0.15),
                child: Icon(
                  n.isRead ? Icons.notifications_outlined : Icons.notifications_active_rounded,
                  color: c.primary,
                  size: 20,
                ),
              ),
              title: Text(n.title, style: Theme.of(context).textTheme.titleMedium),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(n.message),
                  const SizedBox(height: 4),
                  Text(
                    formatRelativeTime(l10n, n.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.primaryLight),
                  ),
                ],
              ),
              onTap: () => onTap(n),
            ),
          ),
        );
      },
    );
  }
}
