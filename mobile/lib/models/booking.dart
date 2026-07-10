import 'field.dart';
import '../utils/json_int.dart';

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
        id: asInt(json['id']) ?? 0,
        referenceCode: json['referenceCode'] as String?,
        fieldName: json['fieldName'] as String? ?? '',
        fieldPhone: json['fieldPhone'] as String? ?? '',
        fieldImage: json['fieldImage'] as String?,
        fieldAddress: json['fieldAddress'] as String? ?? '',
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        hours: asInt(json['hours']) ?? 1,
        totalPrice: asInt(json['totalPrice']) ?? 0,
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

  factory OwnerBooking.fromJson(Map<String, dynamic> json) {
    final rawStart = json['startTime'];
    DateTime start;
    if (rawStart is String && rawStart.isNotEmpty) {
      start = DateTime.tryParse(rawStart) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      start = DateTime.fromMillisecondsSinceEpoch(0);
    }
    return OwnerBooking(
      id: asInt(json['id']) ?? 0,
      referenceCode: json['referenceCode'] as String?,
      userName: json['userName'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      userEmail: json['userEmail'] as String? ?? '',
      startTime: start,
      hours: asInt(json['hours']) ?? 1,
      totalPrice: asInt(json['totalPrice']) ?? 0,
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class OwnerDashboard {
  final Field? field;
  final List<OwnerBooking> bookings;
  final int totalRevenue;
  final int appCommission;
  final int netRevenue;
  final int pendingCount;

  const OwnerDashboard({
    this.field,
    required this.bookings,
    required this.totalRevenue,
    required this.appCommission,
    required this.netRevenue,
    required this.pendingCount,
  });

  factory OwnerDashboard.fromJson(Map<String, dynamic> json) {
    final rawField = json['field'];
    Field? field;
    if (rawField is Map<String, dynamic>) {
      try {
        field = Field.fromJson(rawField);
      } catch (_) {
        field = null;
      }
    }
    final bookings = <OwnerBooking>[];
    for (final e in (json['bookings'] as List<dynamic>? ?? const [])) {
      if (e is! Map<String, dynamic>) continue;
      try {
        bookings.add(OwnerBooking.fromJson(e));
      } catch (_) {
        // تخطّي حجوزات تالفة بدل إسقاط اللوحة كاملة
      }
    }
    return OwnerDashboard(
      field: field,
      bookings: bookings,
      totalRevenue: asInt(json['totalRevenue']) ?? 0,
      appCommission: asInt(json['appCommission']) ?? 0,
      netRevenue: asInt(json['netRevenue']) ?? 0,
      pendingCount: asInt(json['pendingCount']) ?? 0,
    );
  }
}
