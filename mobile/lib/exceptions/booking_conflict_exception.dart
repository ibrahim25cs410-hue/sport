class BookingConflictException implements Exception {
  const BookingConflictException({this.messageKey = 'slotJustBooked'});
  final String messageKey;

  @override
  String toString() => 'BookingConflictException($messageKey)';
}
