import '../../core/booking/booking_result.dart';
import '../../domain/booking/booking_policy.dart';
import '../../exceptions/booking_conflict_exception.dart';
import '../../models/booking.dart';
import '../../models/cancel_booking_result.dart';
import '../../models/create_booking_result.dart';
import '../../models/schedule.dart';
import '../../models/user_stats.dart';
import '../../services/api_client.dart';
import '../../services/booking_service.dart';
import '../paging/paged_list_state.dart';

/// مستودع الحجوزات — تحقق من القواعد محلياً ثم استدعاء الـ API.
class BookingRepository {
  BookingRepository(ApiClient client) : _remote = BookingService(client);

  final BookingService _remote;

  Future<FieldSchedule> getSchedule(int fieldId) => _remote.getSchedule(fieldId);

  /// يتحقق من التوفر وينشئ حجزاً بحالة pending على الخادم.
  Future<BookingResult<CreateBookingResult>> createPendingBooking({
    required int fieldId,
    required DateTime startTime,
    required int hours,
    String paymentMethod = 'online',
    TimeSlot? slot,
    FieldSchedule? schedule,
    DateTime? now,
  }) async {
    if (!BookingPolicy.isValidHours(hours)) {
      return const BookingErr(BookingFailure(code: BookingFailureCode.invalidHours));
    }
    if (!BookingPolicy.isFutureStart(startTime, now: now)) {
      return const BookingErr(BookingFailure(code: BookingFailureCode.pastTime));
    }
    if (!BookingPolicy.isWithinOperatingHours(startTime, hours)) {
      return const BookingErr(BookingFailure(code: BookingFailureCode.invalidHours, messageKey: 'outsideHours'));
    }
    if (slot != null && !BookingPolicy.isSlotBookable(slot, now: now, schedule: schedule)) {
      return const BookingErr(
        BookingFailure(code: BookingFailureCode.slotUnavailable, messageKey: 'slotJustBooked'),
      );
    }
    if (schedule != null &&
        BookingPolicy.conflictsWithSchedule(start: startTime, hours: hours, schedule: schedule)) {
      return const BookingErr(
        BookingFailure(code: BookingFailureCode.slotUnavailable, messageKey: 'slotJustBooked'),
      );
    }

    try {
      final result = await _remote.createBookingWithRef(
        fieldId: fieldId,
        startTime: startTime,
        hours: hours,
        paymentMethod: paymentMethod,
      );
      return BookingOk(result);
    } on BookingConflictException catch (e) {
      return BookingErr(
        BookingFailure(code: BookingFailureCode.conflict, messageKey: e.messageKey, cause: e),
      );
    } catch (e) {
      return BookingErr(BookingFailure(code: BookingFailureCode.unknown, cause: e));
    }
  }

  Future<List<Booking>> getUserBookings(int userId, {int page = 1, int limit = defaultPageSize}) =>
      _remote.getUserBookings(userId, page: page, limit: limit);

  Future<List<Booking>> getBookingHistory(int userId, {int page = 1, int limit = defaultPageSize}) =>
      _remote.getBookingHistory(userId, page: page, limit: limit);

  /// إلغاء الحجز قبل موعده (مع غرامة متأخرة إن لزم).
  Future<BookingResult<CancelBookingResult>> cancelIfAllowed(Booking booking, {DateTime? now}) async {
    if (!BookingPolicy.canCancelBooking(booking, now: now)) {
      return const BookingErr(BookingFailure(code: BookingFailureCode.cancelWindowClosed));
    }

    try {
      final result = await _remote.cancelBooking(booking.id);
      return BookingOk(result);
    } catch (e) {
      if (_remote.isAccountRestricted(e)) {
        return BookingErr(BookingFailure(code: BookingFailureCode.accountRestricted, cause: e));
      }
      if (_remote.isCancelWindowViolation(e)) {
        return BookingErr(BookingFailure(code: BookingFailureCode.cancelWindowClosed, cause: e));
      }
      return BookingErr(BookingFailure(code: BookingFailureCode.unknown, cause: e));
    }
  }

  Future<OwnerDashboard> getOwnerDashboard(int ownerId) => _remote.getOwnerDashboard(ownerId);

  Future<void> approveBooking(int bookingId, {String? referenceCode}) =>
      _remote.approveBooking(bookingId, referenceCode: referenceCode);

  Future<void> rejectBooking(int bookingId, {String? referenceCode}) =>
      _remote.rejectBooking(bookingId, referenceCode: referenceCode);

  Future<UserStats> getUserStats(int userId) => _remote.getUserStats(userId);

  bool isConflict(Object error) => error is BookingConflictException;
}
