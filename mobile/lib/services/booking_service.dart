import 'package:dio/dio.dart';
import '../models/cancel_booking_result.dart';
import '../models/create_booking_result.dart';
import '../models/booking.dart';
import '../models/schedule.dart';
import '../models/stadium_booking.dart';
import '../models/user_stats.dart';
import '../exceptions/booking_cancellation_exception.dart';
import '../exceptions/booking_conflict_exception.dart';
import '../utils/paged_response.dart';
import '../core/paging/paged_list_state.dart';
import 'api_service.dart';

class BookingService {
  BookingService(this._api);
  final ApiService _api;

  Future<FieldSchedule> getSchedule(int fieldId) async {
    final res = await _api.dio.get('/fields/$fieldId/schedule');
    return FieldSchedule.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> createBooking({required int fieldId, required DateTime startTime, required int hours}) async {
    await _api.dio.post('/bookings', data: {
      'fieldId': fieldId,
      'startTime': startTime.toIso8601String(),
      'hours': hours,
      'paymentMethod': 'cash',
    });
  }

  Future<CreateBookingResult> createBookingWithRef({
    required int fieldId,
    required DateTime startTime,
    required int hours,
    String paymentMethod = 'cash',
  }) async {
    try {
      final res = await _api.dio.post('/bookings', data: {
        'fieldId': fieldId,
        'startTime': startTime.toUtc().toIso8601String(),
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
    final res = await _api.dio.get('/bookings/user/me', queryParameters: {'page': page, 'limit': limit});
    return unwrapPagedList(res.data, Booking.fromJson);
  }

  Future<List<Booking>> getBookingHistory(int userId, {int page = 1, int limit = defaultPageSize}) async {
    final res = await _api.dio.get('/bookings/user/me/history', queryParameters: {'page': page, 'limit': limit});
    return unwrapPagedList(res.data, Booking.fromJson);
  }

  Future<CancelBookingResult> cancelBooking(int bookingId) async {
    try {
      final res = await _api.dio.post('/bookings/cancel', data: {'bookingId': bookingId});
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
    final res = await _api.dio.get('/bookings/owner/me');
    return OwnerDashboard.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> approveBooking(int bookingId, {String? referenceCode}) async {
    await _api.dio.post('/bookings/approve', data: {
      'bookingId': bookingId,
      if (referenceCode != null && referenceCode.isNotEmpty) 'referenceCode': referenceCode,
    });
  }

  Future<void> rejectBooking(int bookingId, {String? referenceCode}) async {
    await _api.dio.post('/bookings/reject', data: {
      'bookingId': bookingId,
      if (referenceCode != null && referenceCode.isNotEmpty) 'referenceCode': referenceCode,
    });
  }

  Future<UserStats> getUserStats(int userId) async {
    final res = await _api.dio.get('/stats/user/$userId');
    return UserStats.fromJson(res.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------------------
  // Task 3 — stadium bookings
  // ---------------------------------------------------------------------------

  Future<StadiumBooking> createStadiumBooking({
    required int stadiumId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final res = await _api.dio.post('/bookings', data: {
      'stadiumId': stadiumId,
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
    });
    return StadiumBooking.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<StadiumBooking>> getMyStadiumBookings({
    int page = 1,
    int limit = defaultPageSize,
  }) async {
    final res = await _api.dio.get(
      '/bookings/user/me',
      queryParameters: {'page': page, 'limit': limit},
    );
    return unwrapPagedList(res.data, StadiumBooking.fromJson);
  }

  Future<OwnerStadiumBookingsPage> getOwnerStadiumBookings({
    int page = 1,
    int limit = defaultPageSize,
  }) async {
    final res = await _api.dio.get(
      '/bookings/owner/me',
      queryParameters: {'page': page, 'limit': limit},
    );
    return OwnerStadiumBookingsPage.fromJson(res.data as Map<String, dynamic>);
  }

  Future<StadiumBooking> updateBookingStatus({
    required int bookingId,
    required String status,
  }) async {
    final res = await _api.dio.patch(
      '/bookings/$bookingId/status',
      data: {'status': status},
    );
    return StadiumBooking.fromJson(res.data as Map<String, dynamic>);
  }
}
