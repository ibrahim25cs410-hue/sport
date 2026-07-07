class AdminStats {
  const AdminStats({
    required this.totalUsers,
    required this.totalOwners,
    required this.totalFields,
    required this.totalBookings,
    required this.paidBookings,
    required this.totalRevenueIqd,
    required this.platformCommissionIqd,
  });

  final int totalUsers;
  final int totalOwners;
  final int totalFields;
  final int totalBookings;
  final int paidBookings;
  final int totalRevenueIqd;
  final int platformCommissionIqd;

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalUsers: json['totalUsers'] as int? ?? 0,
        totalOwners: json['totalOwners'] as int? ?? 0,
        totalFields: json['totalFields'] as int? ?? 0,
        totalBookings: json['totalBookings'] as int? ?? 0,
        paidBookings: json['paidBookings'] as int? ?? 0,
        totalRevenueIqd: json['totalRevenueIqd'] as int? ?? 0,
        platformCommissionIqd: json['platformCommissionIqd'] as int? ?? 0,
      );
}
