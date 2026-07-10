import '../utils/json_int.dart';

class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final String? status;
  final DateTime? heldUntil;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.status,
    this.heldUntil,
  });

  bool get isHeld => status == 'held';

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        isAvailable: json['isAvailable'] as bool? ?? false,
        status: json['status'] as String?,
        heldUntil: json['heldUntil'] != null ? DateTime.parse(json['heldUntil'] as String) : null,
      );

  int get hours => endTime.difference(startTime).inHours;
}

class DaySchedule {
  final DateTime date;
  final List<TimeSlot> slots;

  const DaySchedule({required this.date, required this.slots});

  factory DaySchedule.fromJson(Map<String, dynamic> json) => DaySchedule(
        date: DateTime.parse(json['date'] as String),
        slots: (json['slots'] as List<dynamic>? ?? const [])
            .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class FieldSchedule {
  final int id;
  final String name;
  final int pricePerHour;
  final List<DaySchedule> schedule;

  const FieldSchedule({
    required this.id,
    required this.name,
    required this.pricePerHour,
    required this.schedule,
  });

  factory FieldSchedule.fromJson(Map<String, dynamic> json) => FieldSchedule(
        id: asInt(json['id']) ?? 0,
        name: json['name'] as String? ?? '',
        pricePerHour: asInt(json['pricePerHour']) ?? 0,
        schedule: (json['schedule'] as List<dynamic>? ?? const [])
            .map((e) => DaySchedule.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
