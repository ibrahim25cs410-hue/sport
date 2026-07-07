import 'package:flutter_test/flutter_test.dart';
import 'package:riyada/domain/booking/booking_policy.dart';
import 'package:riyada/models/booking.dart';
import 'package:riyada/models/schedule.dart';
import 'package:riyada/utils/format.dart';

void main() {
  final now = DateTime(2026, 6, 22, 10);

  group('BookingPolicy pricing', () {
    test('field price per hour', () {
      expect(BookingPolicy.calculateTotalForField(15000, 1), 15000);
      expect(BookingPolicy.calculateTotalForField(12000, 2), 24000);
    });

    test('default fallback field price 2000 per hour', () {
      expect(BookingPolicy.defaultPricePerHour, 2000);
      expect(BookingPolicy.calculateTotal(1), 2000);
      expect(BookingPolicy.calculateTotal(2), 4000);
    });
  });

  group('BookingPolicy commission', () {
    test('commission rate is 10%', () {
      expect(BookingPolicy.platformCommissionRate, 0.10);
    });

    test('commission = 10% of price per hour × hours', () {
      expect(
        BookingPolicy.calculateCommission(pricePerHour: 12000, hours: 2),
        2400,
      );
      expect(
        BookingPolicy.calculateCommission(pricePerHour: 15000, hours: 1),
        1500,
      );
    });

    test('commission from total booking price', () {
      expect(BookingPolicy.calculateCommissionFromTotal(24000), 2400);
    });

    test('rounds commission away from zero', () {
      expect(
        BookingPolicy.calculateCommission(pricePerHour: 10001, hours: 1),
        1000,
      );
    });
  });

  group('BookingPolicy operating hours', () {
    test('allows 9am start for one hour', () {
      final start = DateTime(2026, 6, 23, 9);
      expect(BookingPolicy.isWithinOperatingHours(start, 1), isTrue);
    });

    test('allows 11pm start for one hour ending at midnight', () {
      final start = DateTime(2026, 6, 23, 23);
      expect(BookingPolicy.isWithinOperatingHours(start, 1), isTrue);
    });

    test('rejects 11pm start for two hours past midnight', () {
      final start = DateTime(2026, 6, 23, 23);
      expect(BookingPolicy.isWithinOperatingHours(start, 2), isFalse);
    });

    test('rejects start before 9am', () {
      final start = DateTime(2026, 6, 23, 8);
      expect(BookingPolicy.isWithinOperatingHours(start, 1), isFalse);
    });
  });

  group('BookingPolicy overlap', () {
    test('detects overlap when 2h booking blocks second hour start', () {
      final blocked = TimeSlot(
        startTime: DateTime(2026, 6, 23, 16),
        endTime: DateTime(2026, 6, 23, 18),
        isAvailable: false,
        status: 'booked',
      );
      final tryStart = DateTime(2026, 6, 23, 17);
      expect(
        BookingPolicy.conflictsWithBlockedSlots(start: tryStart, hours: 1, slots: [blocked]),
        isTrue,
      );
    });

    test('no overlap for non-overlapping slots', () {
      final blocked = TimeSlot(
        startTime: DateTime(2026, 6, 23, 16),
        endTime: DateTime(2026, 6, 23, 17),
        isAvailable: false,
        status: 'booked',
      );
      final tryStart = DateTime(2026, 6, 23, 18);
      expect(
        BookingPolicy.conflictsWithBlockedSlots(start: tryStart, hours: 1, slots: [blocked]),
        isFalse,
      );
    });
  });

  group('formatTime12Ar', () {
    test('formats afternoon with م', () {
      expect(formatTime12Ar(DateTime(2026, 6, 23, 16)), '4:00 م');
    });

    test('formats morning with ص', () {
      expect(formatTime12Ar(DateTime(2026, 6, 23, 9)), '9:00 ص');
    });

    test('formats noon as 12 م', () {
      expect(formatTime12Ar(DateTime(2026, 6, 23, 12)), '12:00 م');
    });
  });

  group('BookingPolicy.canCancel', () {
    test('allows cancel when more than 24 hours remain (free)', () {
      final start = now.add(const Duration(hours: 30));
      expect(
        BookingPolicy.canCancel(startTime: start, status: 'pending', now: now),
        isTrue,
      );
      expect(BookingPolicy.hasLateCancellationPenalty(start, now: now), isFalse);
    });

    test('allows cancel within 12 hours with late penalty', () {
      final start = now.add(const Duration(hours: 12));
      expect(
        BookingPolicy.canCancel(startTime: start, status: 'approved', now: now),
        isTrue,
      );
      expect(BookingPolicy.hasLateCancellationPenalty(start, now: now), isTrue);
    });

    test('allows cancel between 12 and 24 hours without penalty', () {
      final start = now.add(const Duration(hours: 18));
      expect(
        BookingPolicy.canCancel(startTime: start, status: 'pending', now: now),
        isTrue,
      );
      expect(BookingPolicy.hasLateCancellationPenalty(start, now: now), isFalse);
    });

    test('blocks cancel after start time', () {
      final start = now.subtract(const Duration(hours: 1));
      expect(
        BookingPolicy.canCancel(startTime: start, status: 'approved', now: now),
        isFalse,
      );
    });

    test('blocks cancel for completed bookings', () {
      final start = now.add(const Duration(days: 3));
      expect(
        BookingPolicy.canCancel(startTime: start, status: 'completed', now: now),
        isFalse,
      );
    });
  });

  group('BookingPolicy slot validation', () {
    test('rejects booked slot', () {
      final slot = TimeSlot(
        startTime: now.add(const Duration(days: 1)),
        endTime: now.add(const Duration(days: 1, hours: 1)),
        isAvailable: false,
        status: 'booked',
      );
      expect(BookingPolicy.isSlotBookable(slot, now: now), isFalse);
    });

    test('accepts available future slot', () {
      final slot = TimeSlot(
        startTime: now.add(const Duration(days: 1, hours: 5)),
        endTime: now.add(const Duration(days: 1, hours: 6)),
        isAvailable: true,
        status: 'available',
      );
      expect(BookingPolicy.isSlotBookable(slot, now: now), isTrue);
    });
  });

  test('canCancelBooking mirrors policy on model', () {
    final booking = Booking(
      id: 1,
      fieldName: 'Test',
      fieldPhone: '07',
      fieldAddress: 'Addr',
      startTime: now.add(const Duration(hours: 48)),
      endTime: now.add(const Duration(hours: 49)),
      hours: 1,
      totalPrice: 2000,
      status: 'pending',
      remainingHours: 1,
      canCancel: true,
    );
    expect(BookingPolicy.canCancelBooking(booking, now: now), isTrue);
  });

  test('net revenue subtracts 10% platform commission from gross', () {
    expect(
      BookingPolicy.netRevenueFromCompleted(grossRevenue: 100000),
      90000,
    );
  });
}
