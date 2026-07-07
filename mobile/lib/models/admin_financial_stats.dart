class AdminFinancialStats {
  const AdminFinancialStats({
    required this.paidBookings,
    required this.totalRevenueIqd,
    required this.platformCommissionIqd,
  });

  final int paidBookings;
  final int totalRevenueIqd;
  final int platformCommissionIqd;

  factory AdminFinancialStats.fromJson(Map<String, dynamic> json) => AdminFinancialStats(
        paidBookings: json['paidBookings'] as int? ?? 0,
        totalRevenueIqd: json['totalRevenueIqd'] as int? ?? 0,
        platformCommissionIqd: json['platformCommissionIqd'] as int? ?? 0,
      );
}
