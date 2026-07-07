import '../models/notification.dart';
import '../utils/paged_response.dart';
import 'api_client.dart';

class NotificationService {
  NotificationService(this._client);
  final ApiClient _client;

  Future<List<AppNotification>> getForUser(int userId, {int page = 1, int limit = 30}) async {
    final res = await _client.dio.get('/notifications/$userId', queryParameters: {'page': page, 'limit': limit});
    return unwrapPagedList(res.data, AppNotification.fromJson);
  }

  Future<void> markRead(int id) async {
    await _client.dio.post('/notifications/$id/read');
  }

  Future<void> markAllRead(int userId) async {
    await _client.dio.post('/notifications/user/$userId/read-all');
  }
}
