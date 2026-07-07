import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/utils/session_key_helper.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/notifications_list.dart';
import '../../../widgets/load_more_footer.dart';
import '../../../widgets/skeleton_loaders.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final key = watchSessionKey(ref);
    if (key == null) return const SizedBox.shrink();

    final async = ref.watch(userNotificationsProvider(key));
    final notifications = async.valueOrNull ?? [];
    final notifier = ref.read(userNotificationsProvider(key).notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifications)),
      body: async.isLoading && notifications.isEmpty
          ? const NotificationsListSkeleton()
          : NotificationsList(
              notifications: notifications,
              showMarkAll: true,
              footer: notifier.hasMore
                  ? LoadMoreScrollNotification(
                      hasMore: notifier.hasMore,
                      loading: notifier.loadingMore,
                      onLoadMore: () => notifier.loadMore(),
                    )
                  : null,
              onMarkAllRead: () async {
                await ref.read(notificationRepositoryProvider(ref.read(apiClientProvider))).markAllRead(key.userId);
                ref.invalidate(userNotificationsProvider(key));
              },
              onTap: (n) async {
                if (!n.isRead) {
                  await ref.read(notificationRepositoryProvider(ref.read(apiClientProvider))).markRead(n.id);
                  ref.invalidate(userNotificationsProvider(key));
                }
              },
            ),
    );
  }
}
