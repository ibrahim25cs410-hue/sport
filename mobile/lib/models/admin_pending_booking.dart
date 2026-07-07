class AdminPendingBooking {
  const AdminPendingBooking({
    required this.id,
    required this.fieldName,
    required this.userName,
    required this.startTime,
    required this.hours,
    required this.totalPrice,
    required this.status,
  });

  final int id;
  final String fieldName;
  final String userName;
  final DateTime startTime;
  final int hours;
  final int totalPrice;
  final String status;

  factory AdminPendingBooking.fromJson(Map<String, dynamic> json) => AdminPendingBooking(
        id: json['id'] as int,
        fieldName: json['fieldName'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
        startTime: DateTime.parse(json['startTime'] as String),
        hours: json['hours'] as int? ?? 0,
        totalPrice: json['totalPrice'] as int? ?? 0,
        status: json['status'] as String? ?? 'pending',
      );
}
