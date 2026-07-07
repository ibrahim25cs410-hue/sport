enum BookingStatus {
  pending('pending'),
  approved('approved'),
  completed('completed'),
  cancelled('cancelled'),
  rejected('rejected');

  const BookingStatus(this.value);
  final String value;

  static BookingStatus fromString(String? raw) => BookingStatus.values.firstWhere(
        (s) => s.value == raw,
        orElse: () => BookingStatus.pending,
      );

  bool get isUpcoming => this == pending || this == approved;
}
