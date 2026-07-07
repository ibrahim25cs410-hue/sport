class BookingUpdatedEvent {
  const BookingUpdatedEvent({
    required this.bookingId,
    required this.status,
    required this.titleKey,
    required this.messageKey,
    required this.messageArgs,
  });

  factory BookingUpdatedEvent.fromJson(Map<String, dynamic> json) {
    final rawArgs = json['messageArgs'];
    final args = <String, String>{};
    if (rawArgs is Map) {
      rawArgs.forEach((k, v) => args['$k'] = '$v');
    }
    return BookingUpdatedEvent(
      bookingId: json['bookingId'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      titleKey: json['titleKey'] as String? ?? '',
      messageKey: json['messageKey'] as String? ?? '',
      messageArgs: args,
    );
  }

  final int bookingId;
  final String status;
  final String titleKey;
  final String messageKey;
  final Map<String, String> messageArgs;
}

enum SignalRConnectionStatus { disconnected, connecting, connected, reconnecting }
