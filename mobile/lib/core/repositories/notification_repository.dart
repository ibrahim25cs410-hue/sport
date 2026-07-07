import '../../models/notification.dart';
import '../../services/api_client.dart';
import '../../services/notification_service.dart';

/// مستودع الإشعارات.
class NotificationRepository {
  NotificationRepository(ApiClient client) : _remote = NotificationService(client);

  final NotificationService _remote;

  Future<List<AppNotification>> getForUser(int userId, {int page = 1, int limit = 30}) =>
      _remote.getForUser(userId, page: page, limit: limit);

  Future<void> markRead(int id) => _remote.markRead(id);

  Future<void> markAllRead(int userId) => _remote.markAllRead(userId);
}
