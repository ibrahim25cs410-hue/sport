class CancelBookingResult {
  const CancelBookingResult({
    required this.message,
    required this.tier,
    required this.penaltyIqd,
    required this.ownerShareIqd,
    required this.platformShareIqd,
  });

  final String message;
  final String tier;
  final int penaltyIqd;
  final int ownerShareIqd;
  final int platformShareIqd;

  bool get hasPenalty => penaltyIqd > 0;

  factory CancelBookingResult.fromJson(Map<String, dynamic> json) => CancelBookingResult(
        message: json['message'] as String? ?? '',
        tier: json['tier'] as String? ?? 'free',
        penaltyIqd: json['penaltyIqd'] as int? ?? 0,
        ownerShareIqd: json['ownerShareIqd'] as int? ?? 0,
        platformShareIqd: json['platformShareIqd'] as int? ?? 0,
      );
}
