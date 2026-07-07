/// نتيجة عملية حجز — بديل خفيف لـ Either دون إضافة حزم خارجية.
enum BookingFailureCode {
  slotUnavailable,
  invalidHours,
  pastTime,
  cancelWindowClosed,
  accountRestricted,
  conflict,
  unknown,
}

class BookingFailure {
  const BookingFailure({
    required this.code,
    this.messageKey,
    this.cause,
  });

  final BookingFailureCode code;
  final String? messageKey;
  final Object? cause;
}

sealed class BookingResult<T> {
  const BookingResult();

  bool get isOk => this is BookingOk<T>;
  bool get isErr => this is BookingErr<T>;

  T? get valueOrNull => switch (this) {
        BookingOk(:final value) => value,
        BookingErr() => null,
      };

  BookingFailure? get failureOrNull => switch (this) {
        BookingOk() => null,
        BookingErr(:final failure) => failure,
      };
}

final class BookingOk<T> extends BookingResult<T> {
  const BookingOk(this.value);
  final T value;
}

final class BookingErr<T> extends BookingResult<T> {
  const BookingErr(this.failure);
  final BookingFailure failure;
}
