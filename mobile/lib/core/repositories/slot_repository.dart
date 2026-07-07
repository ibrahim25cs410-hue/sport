import '../../services/api_client.dart';
import '../../services/slot_service.dart';

/// مستودع قفل الأوقات التنافسي.
class SlotRepository {
  SlotRepository(ApiClient client) : _remote = SlotService(client);

  final SlotService _remote;

  Future<DateTime?> selectSlot({
    required int fieldId,
    required DateTime startTime,
    required int hours,
  }) =>
      _remote.selectSlot(fieldId: fieldId, startTime: startTime, hours: hours);

  Future<void> releaseSlot({
    required int fieldId,
    required DateTime startTime,
    required int hours,
  }) =>
      _remote.releaseSlot(fieldId: fieldId, startTime: startTime, hours: hours);
}
