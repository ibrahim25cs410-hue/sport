import 'package:dio/dio.dart';

import '../exceptions/booking_conflict_exception.dart';
import 'api_client.dart';

class SlotService {
  SlotService(this._client);
  final ApiClient _client;

  Future<DateTime> selectSlot({
    required int fieldId,
    required DateTime startTime,
    required int hours,
  }) async {
    try {
      final res = await _client.dio.post('/slots/select', data: {
        'fieldId': fieldId,
        'startTime': startTime.toIso8601String(),
        'hours': hours,
      });
      final data = res.data as Map<String, dynamic>;
      return DateTime.parse(data['expiresAt'] as String);
    } on DioException catch (e) {
      throw _asConflict(e);
    }
  }

  Future<void> releaseSlot({
    required int fieldId,
    required DateTime startTime,
    required int hours,
  }) async {
    await _client.dio.post('/slots/release', data: {
      'fieldId': fieldId,
      'startTime': startTime.toIso8601String(),
      'hours': hours,
    });
  }

  Exception _asConflict(DioException e) {
    if (e.response?.statusCode == 409) {
      final data = e.response?.data;
      if (data is Map && data['code'] == 'ConflictError') {
        return BookingConflictException(
          messageKey: data['messageKey'] as String? ?? 'slotJustBooked',
        );
      }
    }
    return e;
  }
}
