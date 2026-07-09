import 'stadium.dart';

class StadiumBooking {
  final int id;
  final int userId;
  final int stadiumId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final Stadium? stadium;
  final StadiumBookingUser? user;

  const StadiumBooking({
    required this.id,
    required this.userId,
    required this.stadiumId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.stadium,
    this.user,
  });

  factory StadiumBooking.fromJson(Map<String, dynamic> json) => StadiumBooking(
        id: json['id'] as int,
        userId: json['userId'] as int,
        stadiumId: json['stadiumId'] as int,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        status: json['status'] as String? ?? 'pending',
        stadium: json['stadium'] is Map<String, dynamic>
            ? Stadium.fromJson(json['stadium'] as Map<String, dynamic>)
            : null,
        user: json['user'] is Map<String, dynamic>
            ? StadiumBookingUser.fromJson(json['user'] as Map<String, dynamic>)
            : null,
      );
}

class StadiumBookingUser {
  final int id;
  final String name;
  final String email;

  const StadiumBookingUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory StadiumBookingUser.fromJson(Map<String, dynamic> json) => StadiumBookingUser(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
      );
}

class OwnerStadiumBookingsPage {
  final List<StadiumBooking> items;
  final int pendingCount;

  const OwnerStadiumBookingsPage({
    required this.items,
    required this.pendingCount,
  });

  factory OwnerStadiumBookingsPage.fromJson(Map<String, dynamic> json) =>
      OwnerStadiumBookingsPage(
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => StadiumBooking.fromJson(e as Map<String, dynamic>))
            .toList(),
        pendingCount: json['pendingCount'] as int? ?? 0,
      );
}
