/// بيانات شاشة دفع الحجز.
class BookingCheckoutArgs {
  const BookingCheckoutArgs({
    required this.bookingId,
    required this.totalPrice,
    required this.fieldName,
    this.referenceCode,
  });

  final int bookingId;
  final int totalPrice;
  final String fieldName;
  final String? referenceCode;
}
