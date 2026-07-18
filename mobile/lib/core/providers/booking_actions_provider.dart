import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/booking/booking_result.dart';
import '../../core/paging/paged_list_state.dart';
import '../../domain/booking/booking_policy.dart';
import '../../models/cancel_booking_result.dart';
import '../../models/create_booking_result.dart';
import '../../models/booking.dart';
import '../../models/field.dart';
import '../../models/schedule.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/session_key.dart';
import '../providers/repository_providers.dart';
import '../repositories/booking_repository.dart';

/// قائمة الملاعب — عبر المستودع فقط.
final fieldsListProvider =
    AsyncNotifierProvider.family<FieldsListNotifier, List<Field>, UserSessionKey>(
  FieldsListNotifier.new,
);

class FieldsListNotifier extends FamilyAsyncNotifier<List<Field>, UserSessionKey> {
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;

  @override
  Future<List<Field>> build(UserSessionKey arg) async {
    _page = 1;
    _hasMore = true;
    final items = await ref.read(authRepositoryProvider).getFields(page: 1, limit: defaultPageSize);
    _hasMore = inferHasMore(items.length, defaultPageSize);
    return items;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;
    _loadingMore = true;
    final current = state.valueOrNull ?? [];
    try {
      final nextPage = _page + 1;
      final more = await ref.read(authRepositoryProvider).getFields(page: nextPage, limit: defaultPageSize);
      _page = nextPage;
      _hasMore = inferHasMore(more.length, defaultPageSize);
      state = AsyncData([...current, ...more]);
    } finally {
      _loadingMore = false;
    }
  }
}

/// جدول ملعب.
final fieldScheduleProvider =
    AsyncNotifierProvider.family<FieldScheduleNotifier, FieldSchedule, FieldScheduleKey>(
  FieldScheduleNotifier.new,
);

class FieldScheduleKey {
  const FieldScheduleKey({required this.session, required this.fieldId});
  final UserSessionKey session;
  final int fieldId;

  @override
  bool operator ==(Object other) =>
      other is FieldScheduleKey && other.session == session && other.fieldId == fieldId;

  @override
  int get hashCode => Object.hash(session, fieldId);
}

class FieldScheduleNotifier extends FamilyAsyncNotifier<FieldSchedule, FieldScheduleKey> {
  @override
  Future<FieldSchedule> build(FieldScheduleKey arg) async {
    return ref.read(bookingRepositoryProvider(arg.session.client)).getSchedule(arg.fieldId);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(arg));
  }
}

/// عمليات الحجز مع Optimistic UI ونتائج منظمة.
final bookingActionsProvider = Provider.family<BookingActions, UserSessionKey>(
  (ref, session) => BookingActions(ref, session),
);

class BookingActions {
  BookingActions(this._ref, this._session);

  final Ref _ref;
  final UserSessionKey _session;

  BookingRepository get _repo => _ref.read(bookingRepositoryProvider(_session.client));

  Future<BookingResult<CreateBookingResult>> createBooking({
    required int fieldId,
    required DateTime startTime,
    required int hours,
    required int fieldPricePerHour,
    required String fieldName,
    required String fieldAddress,
    required String fieldPhone,
    String paymentMethod = 'cash',
    TimeSlot? slot,
    FieldSchedule? schedule,
  }) async {
    final endTime = startTime.add(Duration(hours: hours));
    final loyalty = _ref.read(authProvider).user?.loyaltyPoints ?? 0;
    final quote = BookingPolicy.quoteBookingPrice(
      basePricePerHour: fieldPricePerHour,
      date: startTime,
      hours: hours,
      loyaltyPoints: loyalty,
    );
    final optimistic = Booking(
      id: -DateTime.now().millisecondsSinceEpoch,
      fieldName: fieldName,
      fieldAddress: fieldAddress,
      fieldPhone: fieldPhone,
      startTime: startTime,
      endTime: endTime,
      hours: hours,
      totalPrice: quote.total,
      status: 'pending',
      paymentStatus: paymentMethod == 'cash' ? 'pay_at_venue' : 'unpaid',
      paymentMethod: paymentMethod,
      remainingHours: hours.toDouble(),
      canCancel: BookingPolicy.canCancel(startTime: startTime, status: 'pending'),
    );

    _ref.read(userBookingsProvider(_session).notifier).optimisticPrepend(optimistic);

    final result = await _repo.createPendingBooking(
      fieldId: fieldId,
      startTime: startTime,
      hours: hours,
      paymentMethod: paymentMethod,
      slot: slot,
      schedule: schedule,
    );

    if (result.isOk) {
      final created = result.valueOrNull!;
      if (created.id <= 0) {
        _ref.invalidate(userBookingsProvider(_session));
        return const BookingErr(BookingFailure(code: BookingFailureCode.unknown));
      }
      final confirmed = Booking(
        id: created.id,
        referenceCode: created.referenceCode,
        fieldName: fieldName,
        fieldAddress: fieldAddress,
        fieldPhone: fieldPhone,
        startTime: startTime,
        endTime: endTime,
        hours: hours,
        totalPrice: created.totalPrice > 0 ? created.totalPrice : quote.total,
        status: 'pending',
        paymentStatus: created.paymentStatus,
        paymentMethod: created.paymentMethod,
        remainingHours: hours.toDouble(),
        canCancel: BookingPolicy.canCancel(startTime: startTime, status: 'pending'),
      );
      _ref.read(userBookingsProvider(_session).notifier).confirmCreated(confirmed);
      unawaited(_ref.read(userBookingsProvider(_session).notifier).refreshPreservingData());
      _ref.invalidate(userStatsProvider(_session));
    } else {
      // أزل الحجز المؤقت عند الفشل
      _ref.invalidate(userBookingsProvider(_session));
    }

    return result;
  }

  Future<BookingResult<CancelBookingResult>> cancelBooking(Booking booking) async {
    _ref.read(userBookingsProvider(_session).notifier).optimisticUpdateStatus(booking.id, 'cancelled');

    final result = await _repo.cancelIfAllowed(booking);

    if (result.isOk) {
      _ref.invalidate(userStatsProvider(_session));
    } else {
      _ref.invalidate(userBookingsProvider(_session));
    }

    return result;
  }

  Future<void> approveBooking(int bookingId, {String? referenceCode}) async {
    _ref.read(ownerDashboardProvider(_session).notifier).optimisticUpdateBookingStatus(bookingId, 'approved');
    try {
      await _repo.approveBooking(bookingId, referenceCode: referenceCode);
      _ref.invalidate(ownerDashboardProvider(_session));
    } catch (e) {
      _ref.invalidate(ownerDashboardProvider(_session));
      rethrow;
    }
  }

  Future<void> rejectBooking(int bookingId, {String? referenceCode}) async {
    _ref.read(ownerDashboardProvider(_session).notifier).optimisticUpdateBookingStatus(bookingId, 'rejected');
    try {
      await _repo.rejectBooking(bookingId, referenceCode: referenceCode);
      _ref.invalidate(ownerDashboardProvider(_session));
    } catch (e) {
      _ref.invalidate(ownerDashboardProvider(_session));
      rethrow;
    }
  }
}
