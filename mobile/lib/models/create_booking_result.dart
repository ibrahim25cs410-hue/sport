import '../utils/json_int.dart';

class CreateBookingResult {
  const CreateBookingResult({
    required this.id,
    this.referenceCode,
    required this.paymentStatus,
    required this.totalPrice,
    this.discountAmount = 0,
    this.isDiscountApplied = false,
    this.hourlyRate,
    this.loyaltyPoints = 0,
  });

  final int id;
  final String? referenceCode;
  final String paymentStatus;
  final int totalPrice;
  final int discountAmount;
  final bool isDiscountApplied;
  final int? hourlyRate;
  final int loyaltyPoints;

  bool get needsPayment => paymentStatus != 'paid';

  factory CreateBookingResult.fromJson(Map<String, dynamic> json) => CreateBookingResult(
        id: asInt(json['id']) ?? 0,
        referenceCode: json['referenceCode'] as String?,
        paymentStatus: json['paymentStatus'] as String? ?? 'unpaid',
        totalPrice: asInt(json['totalPrice']) ?? 0,
        discountAmount: asInt(json['discountAmount']) ?? 0,
        isDiscountApplied: json['isDiscountApplied'] as bool? ?? false,
        hourlyRate: asInt(json['hourlyRate']),
        loyaltyPoints: asInt(json['loyaltyPoints']) ?? 0,
      );
}
