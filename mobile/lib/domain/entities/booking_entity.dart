import '../enums/booking_status.dart';
import '../enums/payment_method.dart';

class BookingEntity {
  const BookingEntity({
    required this.id,
    required this.fieldId,
    required this.userId,
    required this.fieldName,
    required this.fieldAddress,
    required this.startTime,
    required this.endTime,
    required this.hours,
    required this.totalPrice,
    this.status = BookingStatus.pending,
    this.referenceCode,
    this.fieldImage,
    this.paymentMethod,
    this.qrCode,
    this.couponCode,
  });

  final String id;
  final String fieldId;
  final String userId;
  final String fieldName;
  final String fieldAddress;
  final DateTime startTime;
  final DateTime endTime;
  final int hours;
  final int totalPrice;
  final BookingStatus status;
  final String? referenceCode;
  final String? fieldImage;
  final PaymentMethod? paymentMethod;
  final String? qrCode;
  final String? couponCode;

  bool get canCancel => status == BookingStatus.pending || status == BookingStatus.approved;
}
