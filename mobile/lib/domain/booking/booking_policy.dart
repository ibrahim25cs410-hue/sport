import '../../core/constants/financial_constants.dart';
import '../../models/booking.dart';
import '../../models/schedule.dart';

/// قواعد الحجز والإلغاء — منطق نقي قابل للاختبار (مطابق لـ FinancialRules في الخادم).
abstract final class BookingPolicy {
  /// إلغاء مجاني إذا بقي يوم أو أكثر قبل الموعد.
  static const int freeCancellationHours = 24;

  /// غرامة إلغاء متأخر إذا بقي 12 ساعة أو أقل.
  static const int lateCancellationHours = 12;
  static const int lateCancellationPenaltyIqd = 5000;
  static const int lateCancellationOwnerShareIqd = 2500;
  static const int lateCancellationPlatformShareIqd = 2500;
  static const int minBookingHours = 1;
  static const int maxBookingHours = 2;
  /// ساعات العمل: 9:00 ص — 12:00 م (منتصف الليل).
  static const int openHour = 9;
  static const int closeHour = 24;

  /// نسبة عمولة المنصة (10%).
  static double get platformCommissionRate => FinancialConstants.platformCommissionRate;

  /// سعر افتراضي للملعب عند غياب السعر.
  static int get defaultPricePerHour => FinancialConstants.defaultFieldPricePerHourIqd;

  /// @deprecated استخدم [calculateTotalForField] مع سعر الملعب.
  static int get pricePerHour => defaultPricePerHour;

  /// Thu–Sat peak surcharge per hour (IQD) — matches server FinancialRules.
  static const int peakDaySurchargePerHourIqd = 3000;
  static const int loyaltyPointsForDiscount = 10;
  static const double loyaltyDiscountRate = 0.10;

  static bool isPeakPricingDay(DateTime date) {
    return date.weekday == DateTime.thursday ||
        date.weekday == DateTime.friday ||
        date.weekday == DateTime.saturday;
  }

  static int hourlyRate(int basePricePerHour, DateTime date) =>
      basePricePerHour + (isPeakPricingDay(date) ? peakDaySurchargePerHourIqd : 0);

  /// Full quote including optional 10% loyalty discount at 10 points.
  static ({int subtotal, int discount, int total, bool discountApplied}) quoteBookingPrice({
    required int basePricePerHour,
    required DateTime date,
    required int hours,
    int loyaltyPoints = 0,
  }) {
    final subtotal = hourlyRate(basePricePerHour, date) * hours;
    final applyDiscount = loyaltyPoints >= loyaltyPointsForDiscount;
    final discount = applyDiscount ? FinancialConstants.roundIqd(subtotal * loyaltyDiscountRate) : 0;
    return (
      subtotal: subtotal,
      discount: discount,
      total: subtotal - discount,
      discountApplied: applyDiscount,
    );
  }

  /// إجمالي الحجز = سعر الملعب × الساعات (legacy — prefer [quoteBookingPrice]).
  static int calculateTotalForField(int fieldPricePerHour, int hours) => fieldPricePerHour * hours;

  static int calculateTotal(int hours, {int? fieldPricePerHour}) =>
      calculateTotalForField(fieldPricePerHour ?? defaultPricePerHour, hours);

  /// عمولة المنصة = (سعر الساعة × عدد الساعات) × 10%.
  static int calculateCommission({required int pricePerHour, required int hours}) =>
      FinancialConstants.calculateCommission(pricePerHour: pricePerHour, hours: hours);

  /// عمولة المنصة من إجمالي الحجز.
  static int calculateCommissionFromTotal(int totalPrice) =>
      FinancialConstants.calculateCommissionFromTotal(totalPrice);

  /// صافي الأرباح = إجمالي الدخل − عمولة المنصة (10% من الإجمالي).
  static int netRevenueFromCompleted({required int grossRevenue}) =>
      FinancialConstants.netRevenue(
        grossRevenue: grossRevenue,
        commission: calculateCommissionFromTotal(grossRevenue),
      );

  static DateTime endTime(DateTime start, int hours) => start.add(Duration(hours: hours));

  /// تداخل فترتين [start, end) — نفس منطق الخادم.
  static bool intervalsOverlap(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) =>
      aStart.isBefore(bEnd) && aEnd.isAfter(bStart);

  /// هل يقع الحجز ضمن ساعات العمل (9 ص — 12 م)؟
  static bool isWithinOperatingHours(DateTime start, int hours) {
    if (start.hour < openHour) return false;
    if (start.hour >= closeHour) return false;
    final end = endTime(start, hours);
    final midnight = DateTime(start.year, start.month, start.day + 1);
    return !end.isAfter(midnight);
  }

  /// هل يتعارض الحجز الجديد مع فترات محجوزة/معلّمة في الجدول؟
  static bool conflictsWithBlockedSlots({
    required DateTime start,
    required int hours,
    required Iterable<TimeSlot> slots,
  }) {
    final end = endTime(start, hours);
    for (final slot in slots) {
      if (slot.isAvailable && !slot.isHeld) continue;
      if (intervalsOverlap(start, end, slot.startTime, slot.endTime)) return true;
    }
    return false;
  }

  static bool conflictsWithSchedule({
    required DateTime start,
    required int hours,
    required FieldSchedule schedule,
  }) {
    final all = schedule.schedule.expand((d) => d.slots);
    return conflictsWithBlockedSlots(start: start, hours: hours, slots: all);
  }

  /// هل يمكن إلغاء الحجز؟ (قبل موعد الحجز + حالة نشطة).
  static bool canCancel({
    required DateTime startTime,
    required String status,
    DateTime? now,
  }) {
    if (!_isActiveStatus(status)) return false;
    return hoursUntil(startTime, now: now) > 0;
  }

  /// إلغاء متأخر — غرامة 5,000 د.ع عند الإلغاء قبل 12 ساعة أو أقل من الموعد.
  static bool hasLateCancellationPenalty(DateTime startTime, {DateTime? now}) {
    final hours = hoursUntil(startTime, now: now);
    return hours > 0 && hours <= lateCancellationHours;
  }

  /// إلغاء مجاني — قبل الموعد بيوم أو أكثر (أو بين 12–24 ساعة).
  static bool isFreeCancellation(DateTime startTime, {DateTime? now}) {
    final hours = hoursUntil(startTime, now: now);
    return hours > lateCancellationHours;
  }

  static bool canCancelBooking(Booking booking, {DateTime? now}) =>
      canCancel(startTime: booking.startTime, status: booking.status, now: now);

  static double hoursUntil(DateTime startTime, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    return startTime.difference(clock).inMinutes / 60.0;
  }

  static bool isSlotBookable(TimeSlot slot, {DateTime? now, FieldSchedule? schedule}) {
    final clock = now ?? DateTime.now();
    if (slot.startTime.isBefore(clock)) return false;
    if (!slot.isAvailable) return false;
    if (slot.status == 'booked') return false;
    if (!isWithinOperatingHours(slot.startTime, slot.hours)) return false;
    if (schedule != null && conflictsWithSchedule(start: slot.startTime, hours: slot.hours, schedule: schedule)) {
      return false;
    }
    return true;
  }

  static bool isValidHours(int hours) => hours >= minBookingHours && hours <= maxBookingHours;

  static bool isFutureStart(DateTime startTime, {DateTime? now}) {
    return !startTime.isBefore(now ?? DateTime.now());
  }

  static bool _isActiveStatus(String status) => status == 'pending' || status == 'approved';
}
