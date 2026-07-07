/// رفض إلغاء الحجز (نافذة الإلغاء أو حظر الحساب).
class BookingCancellationException implements Exception {
  const BookingCancellationException({this.message, this.code});

  final String? message;
  final String? code;

  @override
  String toString() => message ?? 'BookingCancellationException';
}
