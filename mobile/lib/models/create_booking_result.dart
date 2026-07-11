import '../utils/json_int.dart';

class CreateBookingResult {
  const CreateBookingResult({
    required this.id,
    this.referenceCode,
    required this.paymentStatus,
    this.paymentMethod = 'online',
    required this.totalPrice,
    this.discountAmount = 0,
    this.isDiscountApplied = false,
    this.hourlyRate,
    this.loyaltyPoints = 0,
  });

  final int id;
  final String? referenceCode;
  final String paymentStatus;
  final String paymentMethod;
  final int totalPrice;
  final int discountAmount;
  final bool isDiscountApplied;
  final int? hourlyRate;
  final int loyaltyPoints;

  /// Online unpaid only — cash waits for owner approval and is paid at the venue.
  bool get needsPayment =>
      paymentStatus != 'paid' &&
      paymentStatus != 'pay_at_venue' &&
      paymentMethod.toLowerCase() != 'cash';

  factory CreateBookingResult.fromJson(Map<String, dynamic> json) => CreateBookingResult(
        id: asInt(json['id']) ?? 0,
        referenceCode: json['referenceCode'] as String?,
        paymentStatus: json['paymentStatus'] as String? ?? 'unpaid',
        paymentMethod: json['paymentMethod'] as String? ?? 'online',
        totalPrice: asInt(json['totalPrice']) ?? 0,
        discountAmount: asInt(json['discountAmount']) ?? 0,
        isDiscountApplied: json['isDiscountApplied'] as bool? ?? false,
        hourlyRate: asInt(json['hourlyRate']),
        loyaltyPoints: asInt(json['loyaltyPoints']) ?? 0,
      );
}
