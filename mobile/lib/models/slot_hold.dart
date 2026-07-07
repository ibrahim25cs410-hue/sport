class SlotSelectionEvent {
  const SlotSelectionEvent({
    required this.fieldId,
    required this.startTime,
    required this.hours,
    required this.userId,
    required this.expiresAt,
  });

  factory SlotSelectionEvent.fromJson(Map<String, dynamic> json) => SlotSelectionEvent(
        fieldId: json['fieldId'] as int? ?? 0,
        startTime: DateTime.parse(json['startTime'] as String),
        hours: json['hours'] as int? ?? 1,
        userId: json['userId'] as int? ?? 0,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );

  final int fieldId;
  final DateTime startTime;
  final int hours;
  final int userId;
  final DateTime expiresAt;
}

class SlotReleaseEvent {
  const SlotReleaseEvent({
    required this.fieldId,
    required this.startTime,
    required this.hours,
  });

  factory SlotReleaseEvent.fromJson(Map<String, dynamic> json) => SlotReleaseEvent(
        fieldId: json['fieldId'] as int? ?? 0,
        startTime: DateTime.parse(json['startTime'] as String),
        hours: json['hours'] as int? ?? 1,
      );

  final int fieldId;
  final DateTime startTime;
  final int hours;
}

String slotKey(DateTime start, int hours) => '${start.toIso8601String()}_$hours';
