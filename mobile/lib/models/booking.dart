import 'field.dart';

class Booking {
  final int id;
  final String? referenceCode;
  final String fieldName;
  final String fieldPhone;
  final String? fieldImage;
  final String fieldAddress;
  final DateTime startTime;
  final DateTime endTime;
  final int hours;
  final int totalPrice;
  final String status;
  final String paymentStatus;
  final double remainingHours;
  final bool canCancel;

  const Booking({
    required this.id,
    this.referenceCode,
    required this.fieldName,
    required this.fieldPhone,
    this.fieldImage,
    required this.fieldAddress,
    required this.startTime,
    required this.endTime,
    required this.hours,
    required this.totalPrice,
    required this.status,
    this.paymentStatus = 'paid',
    required this.remainingHours,
    required this.canCancel,
  });

  bool get needsPayment => paymentStatus != 'paid' && status != 'cancelled' && status != 'rejected';

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as int,
        referenceCode: json['referenceCode'] as String?,
        fieldName: json['fieldName'] as String? ?? '',
        fieldPhone: json['fieldPhone'] as String? ?? '',
        fieldImage: json['fieldImage'] as String?,
        fieldAddress: json['fieldAddress'] as String? ?? '',
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        hours: json['hours'] as int? ?? 1,
        totalPrice: json['totalPrice'] as int? ?? 0,
        status: json['status'] as String? ?? 'pending',
        paymentStatus: json['paymentStatus'] as String? ?? 'paid',
        remainingHours: (json['remainingHours'] as num?)?.toDouble() ?? 0,
        canCancel: json['canCancel'] as bool? ?? false,
      );
}

class OwnerBooking {
  final int id;
  final String? referenceCode;
  final String userName;
  final String userPhone;
  final String userEmail;
  final DateTime startTime;
  final int hours;
  final int totalPrice;
  final String status;

  const OwnerBooking({
    required this.id,
    this.referenceCode,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    required this.startTime,
    required this.hours,
    required this.totalPrice,
    required this.status,
  });

  factory OwnerBooking.fromJson(Map<String, dynamic> json) => OwnerBooking(
        id: json['id'] as int,
        referenceCode: json['referenceCode'] as String?,
        userName: json['userName'] as String? ?? '',
        userPhone: json['userPhone'] as String? ?? '',
        userEmail: json['userEmail'] as String? ?? '',
        startTime: DateTime.parse(json['startTime'] as String),
        hours: json['hours'] as int? ?? 1,
        totalPrice: json['totalPrice'] as int? ?? 0,
        status: json['status'] as String? ?? 'pending',
      );
}

class OwnerDashboard {
  final Field field;
  final List<OwnerBooking> bookings;
  final int totalRevenue;
  final int appCommission;
  final int netRevenue;
  final int pendingCount;

  const OwnerDashboard({
    required this.field,
    required this.bookings,
    required this.totalRevenue,
    required this.appCommission,
    required this.netRevenue,
    required this.pendingCount,
  });

  factory OwnerDashboard.fromJson(Map<String, dynamic> json) => OwnerDashboard(
        field: Field.fromJson(json['field'] as Map<String, dynamic>),
        bookings: (json['bookings'] as List<dynamic>)
            .map((e) => OwnerBooking.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalRevenue: json['totalRevenue'] as int? ?? 0,
        appCommission: json['appCommission'] as int? ?? 0,
        netRevenue: json['netRevenue'] as int? ?? 0,
        pendingCount: json['pendingCount'] as int? ?? 0,
      );
}
