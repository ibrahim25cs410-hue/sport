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
        id: json['id'] as int,
        referenceCode: json['referenceCode'] as String?,
        paymentStatus: json['paymentStatus'] as String? ?? 'unpaid',
        totalPrice: json['totalPrice'] as int? ?? 0,
        discountAmount: json['discountAmount'] as int? ?? 0,
        isDiscountApplied: json['isDiscountApplied'] as bool? ?? false,
        hourlyRate: json['hourlyRate'] as int?,
        loyaltyPoints: json['loyaltyPoints'] as int? ?? 0,
      );
}
