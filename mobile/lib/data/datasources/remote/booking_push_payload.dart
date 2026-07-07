import 'package:firebase_messaging/firebase_messaging.dart';

/// Parsed FCM data payload from the Riyada API.
class BookingPushPayload {
  const BookingPushPayload({
    required this.type,
    required this.title,
    required this.body,
    this.bookingId,
  });

  final String type;
  final String title;
  final String body;
  final int? bookingId;

  static const bookingApproved = 'booking_approved';
  static const bookingRejected = 'booking_rejected';
  static const bookingPending = 'booking_pending';
  static const bookingCancelled = 'booking_cancelled';

  factory BookingPushPayload.fromMessage(RemoteMessage message) {
    final data = message.data;
    final bookingRaw = data['bookingId'] ?? data['booking_id'];
  final bookingId = bookingRaw is int
        ? bookingRaw
        : int.tryParse(bookingRaw?.toString() ?? '');

    return BookingPushPayload(
      type: data['type'] ?? data['eventType'] ?? 'general',
      title: message.notification?.title ?? data['title'] ?? 'Riyada',
      body: message.notification?.body ?? data['body'] ?? '',
      bookingId: bookingId,
    );
  }

  bool get isBookingStatusChange =>
      type == bookingApproved ||
      type == bookingRejected ||
      type == bookingPending ||
      type == bookingCancelled;

  String? get bookingStatus => switch (type) {
        bookingApproved => 'approved',
        bookingRejected => 'rejected',
        bookingPending => 'pending',
        bookingCancelled => 'cancelled',
        _ => null,
      };
}
