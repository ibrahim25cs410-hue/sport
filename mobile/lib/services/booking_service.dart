import 'package:dio/dio.dart';
import '../models/cancel_booking_result.dart';
import '../models/create_booking_result.dart';
import '../models/booking.dart';
import '../models/schedule.dart';
import '../models/user_stats.dart';
import '../exceptions/booking_cancellation_exception.dart';
import '../exceptions/booking_conflict_exception.dart';
import '../utils/paged_response.dart';
import '../core/paging/paged_list_state.dart';
import 'api_client.dart';

class BookingService {
  BookingService(this._client);
  final ApiClient _client;

  Future<FieldSchedule> getSchedule(int fieldId) async {
    final res = await _client.dio.get('/fields/$fieldId/schedule');
    return FieldSchedule.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> createBooking({required int fieldId, required DateTime startTime, required int hours}) async {
    await _client.dio.post('/bookings', data: {
      'fieldId': fieldId,
      'startTime': startTime.toIso8601String(),
      'hours': hours,
    });
  }

  Future<CreateBookingResult> createBookingWithRef({
    required int fieldId,
    required DateTime startTime,
    required int hours,
    String paymentMethod = 'online',
  }) async {
    try {
      final res = await _client.dio.post('/bookings', data: {
        'fieldId': fieldId,
        'startTime': startTime.toIso8601String(),
        'hours': hours,
        'paymentMethod': paymentMethod,
      });
      return CreateBookingResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _asConflict(e);
    }
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

  Future<List<Booking>> getUserBookings(int userId, {int page = 1, int limit = defaultPageSize}) async {
    final res = await _client.dio.get('/bookings/user/$userId', queryParameters: {'page': page, 'limit': limit});
    return unwrapPagedList(res.data, Booking.fromJson);
  }

  Future<List<Booking>> getBookingHistory(int userId, {int page = 1, int limit = defaultPageSize}) async {
    final res = await _client.dio.get('/bookings/user/$userId/history', queryParameters: {'page': page, 'limit': limit});
    return unwrapPagedList(res.data, Booking.fromJson);
  }

  Future<CancelBookingResult> cancelBooking(int bookingId) async {
    try {
      final res = await _client.dio.post('/bookings/cancel', data: {'bookingId': bookingId});
      return CancelBookingResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapCancelError(e);
    }
  }

  bool isCancelWindowViolation(Object error) {
    if (error is! DioException) return false;
    return _isCancelWindowResponse(error);
  }

  Exception _mapCancelError(DioException e) {
    if (_isAccountRestrictedResponse(e)) {
      return BookingCancellationException(
        message: _responseMessage(e) ?? 'Account restricted due to excessive cancellations.',
        code: 'account_restricted',
      );
    }
    if (_isCancelWindowResponse(e)) {
      return BookingCancellationException();
    }
    return e;
  }

  bool isAccountRestricted(Object error) {
    if (error is BookingCancellationException && error.code == 'account_restricted') return true;
    if (error is! DioException) return false;
    return _isAccountRestrictedResponse(error);
  }

  bool _isAccountRestrictedResponse(DioException e) {
    if (e.response?.statusCode != 400) return false;
    final data = e.response?.data;
    if (data is Map && data['code'] == 'account_restricted') return true;
    final msg = _responseMessage(e) ?? '';
    return msg.contains('Account restricted due to excessive cancellations');
  }

  String? _responseMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) return data['message'] as String?;
    return null;
  }

  bool _isCancelWindowResponse(DioException e) {
    if (e.response?.statusCode != 400) return false;
    final data = e.response?.data;
    if (data is Map) {
      final msg = (data['message'] as String?) ?? '';
      return msg.contains('لا يمكن الإلغاء');
    }
    return false;
  }

  Future<OwnerDashboard> getOwnerDashboard(int ownerId) async {
    final res = await _client.dio.get('/bookings/owner/$ownerId');
    return OwnerDashboard.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> approveBooking(int bookingId) async {
    await _client.dio.post('/bookings/approve', data: {'bookingId': bookingId});
  }

  Future<void> rejectBooking(int bookingId) async {
    await _client.dio.post('/bookings/reject', data: {'bookingId': bookingId});
  }

  Future<UserStats> getUserStats(int userId) async {
    final res = await _client.dio.get('/stats/user/$userId');
    return UserStats.fromJson(res.data as Map<String, dynamic>);
  }
}
