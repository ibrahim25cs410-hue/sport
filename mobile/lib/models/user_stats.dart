class UserStats {
  final int upcomingBookings;
  final int pendingBookings;
  final int unreadNotifications;
  final int totalHoursBooked;

  const UserStats({
    required this.upcomingBookings,
    required this.pendingBookings,
    required this.unreadNotifications,
    this.totalHoursBooked = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        upcomingBookings: json['upcomingBookings'] as int? ?? 0,
        pendingBookings: json['pendingBookings'] as int? ?? 0,
        unreadNotifications: json['unreadNotifications'] as int? ?? 0,
        totalHoursBooked: json['totalHoursBooked'] as int? ?? 0,
      );
}
