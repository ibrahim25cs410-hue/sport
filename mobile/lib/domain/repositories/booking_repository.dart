import '../entities/booking_entity.dart';
import '../enums/booking_status.dart';
import '../enums/payment_method.dart';

abstract class BookingRepository {
  Stream<List<BookingEntity>> watchUserBookings(String userId);
  Future<BookingEntity> createBooking(BookingEntity draft);
  Future<void> cancelBooking(String bookingId);
  Future<void> updateStatus(String bookingId, BookingStatus status);
  Future<BookingEntity?> getBooking(String id);
}

abstract class PaymentRepository {
  Future<String> processPayment({
    required String bookingId,
    required int amount,
    required PaymentMethod method,
    String? couponCode,
  });
}
