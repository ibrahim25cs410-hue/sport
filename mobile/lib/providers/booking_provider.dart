import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../models/notification.dart';
import '../models/user_stats.dart';
import '../core/paging/paged_list_state.dart';
import '../core/providers/repository_providers.dart';
import 'session_key.dart';

/// Active user bookings — invalidated when a bookingUpdated socket event arrives.
final userBookingsProvider =
    AsyncNotifierProvider.family<UserBookingsNotifier, List<Booking>, UserSessionKey>(
  UserBookingsNotifier.new,
);

class UserBookingsNotifier extends FamilyAsyncNotifier<List<Booking>, UserSessionKey> {
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  /// حجوزات أُنشئت محلياً ولم ترجع بعد من الـ API — يمنع سباق build() من مسحها.
  final List<Booking> _confirmedLocal = [];

  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;

  List<Booking> _mergeWithLocal(List<Booking> remote) {
    final ids = {for (final b in remote) b.id};
    _confirmedLocal.removeWhere((b) => b.id > 0 && ids.contains(b.id));
    final extras = _confirmedLocal.where((b) => b.id > 0 && !ids.contains(b.id)).toList();
    if (extras.isEmpty) return remote;
    return [...extras, ...remote];
  }

  @override
  Future<List<Booking>> build(UserSessionKey arg) async {
    _page = 1;
    _hasMore = true;
    final items = await ref
        .read(bookingRepositoryProvider(arg.client))
        .getUserBookings(arg.userId, page: 1, limit: defaultPageSize);
    _hasMore = inferHasMore(items.length, defaultPageSize);
    return _mergeWithLocal(items);
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;
    _loadingMore = true;
    final current = state.valueOrNull ?? [];
    try {
      final nextPage = _page + 1;
      final more = await ref
          .read(bookingRepositoryProvider(arg.client))
          .getUserBookings(arg.userId, page: nextPage, limit: defaultPageSize);
      _page = nextPage;
      _hasMore = inferHasMore(more.length, defaultPageSize);
      state = AsyncData([...current, ...more]);
    } finally {
      _loadingMore = false;
    }
  }

  void optimisticPrepend(Booking booking) {
    final current = state.valueOrNull;
    if (current == null) {
      state = AsyncData([booking]);
      return;
    }
    state = AsyncData([booking, ...current]);
  }

  /// بعد نجاح الإنشاء: استبدال الحجوزات المؤقتة بالحجز الحقيقي دون مسح القائمة.
  void confirmCreated(Booking booking) {
    if (booking.id > 0) {
      _confirmedLocal.removeWhere((b) => b.id == booking.id || b.id < 0);
      _confirmedLocal.insert(0, booking);
    }
    final current = state.valueOrNull ?? <Booking>[];
    final cleaned = current.where((b) => b.id > 0 && b.id != booking.id).toList();
    state = AsyncData([booking, ...cleaned]);
  }

  void optimisticUpdateStatus(int bookingId, String status) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.map((b) => b.id == bookingId ? _copyStatus(b, status) : b).toList(),
    );
  }

  /// إعادة جلب من الخادم دون مسح القائمة المعروضة (تجنّب الشاشة السوداء).
  Future<void> refreshPreservingData() async {
    final previous = state.valueOrNull;
    try {
      _page = 1;
      final data = await ref
          .read(bookingRepositoryProvider(arg.client))
          .getUserBookings(arg.userId, page: 1, limit: defaultPageSize);
      _hasMore = inferHasMore(data.length, defaultPageSize);
      final merged = _mergeWithLocal(data);
      // إن رجع الخادم فارغاً وما زال عندنا حجوزات مؤكدة محلياً — لا تمسحها
      if (merged.isEmpty && previous != null && previous.any((b) => b.id > 0)) {
        state = AsyncData(previous.where((b) => b.id > 0).toList());
      } else {
        state = AsyncData(merged);
      }
    } catch (e, st) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  Booking _copyStatus(Booking b, String status) => Booking(
        id: b.id,
        referenceCode: b.referenceCode,
        fieldName: b.fieldName,
        fieldPhone: b.fieldPhone,
        fieldImage: b.fieldImage,
        fieldAddress: b.fieldAddress,
        startTime: b.startTime,
        endTime: b.endTime,
        hours: b.hours,
        totalPrice: b.totalPrice,
        status: status,
        paymentStatus: b.paymentStatus,
        paymentMethod: b.paymentMethod,
        remainingHours: b.remainingHours,
        canCancel: status == 'pending' || status == 'approved' ? b.canCancel : false,
      );
}

/// سجل الحجوزات الكامل (حالي + سابق).
final bookingHistoryProvider =
    AsyncNotifierProvider.family<BookingHistoryNotifier, List<Booking>, UserSessionKey>(
  BookingHistoryNotifier.new,
);

class BookingHistoryNotifier extends FamilyAsyncNotifier<List<Booking>, UserSessionKey> {
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;

  @override
  Future<List<Booking>> build(UserSessionKey arg) async {
    _page = 1;
    _hasMore = true;
    final items = await ref
        .read(bookingRepositoryProvider(arg.client))
        .getBookingHistory(arg.userId, page: 1, limit: defaultPageSize);
    _hasMore = inferHasMore(items.length, defaultPageSize);
    return items;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;
    _loadingMore = true;
    final current = state.valueOrNull ?? [];
    try {
      final nextPage = _page + 1;
      final more = await ref
          .read(bookingRepositoryProvider(arg.client))
          .getBookingHistory(arg.userId, page: nextPage, limit: defaultPageSize);
      _page = nextPage;
      _hasMore = inferHasMore(more.length, defaultPageSize);
      state = AsyncData([...current, ...more]);
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refreshPreservingData() async {
    final previous = state.valueOrNull;
    try {
      _page = 1;
      final data = await ref
          .read(bookingRepositoryProvider(arg.client))
          .getBookingHistory(arg.userId, page: 1, limit: defaultPageSize);
      _hasMore = inferHasMore(data.length, defaultPageSize);
      state = AsyncData(data);
    } catch (e, st) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(e, st);
      }
    }
  }
}

final userStatsProvider =
    AsyncNotifierProvider.family<UserStatsNotifier, UserStats, UserSessionKey>(
  UserStatsNotifier.new,
);

class UserStatsNotifier extends FamilyAsyncNotifier<UserStats, UserSessionKey> {
  @override
  Future<UserStats> build(UserSessionKey arg) async {
    return ref.read(bookingRepositoryProvider(arg.client)).getUserStats(arg.userId);
  }
}

final userNotificationsProvider =
    AsyncNotifierProvider.family<UserNotificationsNotifier, List<AppNotification>, UserSessionKey>(
  UserNotificationsNotifier.new,
);

class UserNotificationsNotifier extends FamilyAsyncNotifier<List<AppNotification>, UserSessionKey> {
  static const _pageSize = 30;
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;

  @override
  Future<List<AppNotification>> build(UserSessionKey arg) async {
    _page = 1;
    _hasMore = true;
    final items = await ref
        .read(notificationRepositoryProvider(arg.client))
        .getForUser(arg.userId, page: 1, limit: _pageSize);
    _hasMore = inferHasMore(items.length, _pageSize);
    return items;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore) return;
    _loadingMore = true;
    final current = state.valueOrNull ?? [];
    try {
      final nextPage = _page + 1;
      final more = await ref
          .read(notificationRepositoryProvider(arg.client))
          .getForUser(arg.userId, page: nextPage, limit: _pageSize);
      _page = nextPage;
      _hasMore = inferHasMore(more.length, _pageSize);
      state = AsyncData([...current, ...more]);
    } finally {
      _loadingMore = false;
    }
  }
}

/// لوحة تحكم المالك.
final ownerDashboardProvider =
    AsyncNotifierProvider.family<OwnerDashboardNotifier, OwnerDashboard, UserSessionKey>(
  OwnerDashboardNotifier.new,
);

class OwnerDashboardNotifier extends FamilyAsyncNotifier<OwnerDashboard, UserSessionKey> {
  @override
  Future<OwnerDashboard> build(UserSessionKey arg) async {
    return ref.read(bookingRepositoryProvider(arg.client)).getOwnerDashboard(arg.userId);
  }

  void optimisticUpdateBookingStatus(int bookingId, String status) {
    final current = state.valueOrNull;
    if (current == null) return;
    final bookings = current.bookings
        .map((b) => b.id == bookingId ? _copyOwnerStatus(b, status) : b)
        .toList();
    final pendingDelta = status == 'approved' || status == 'rejected' ? -1 : 0;
    state = AsyncData(
      OwnerDashboard(
        field: current.field,
        bookings: bookings,
        totalRevenue: current.totalRevenue,
        appCommission: current.appCommission,
        netRevenue: current.netRevenue,
        pendingCount: (current.pendingCount + pendingDelta).clamp(0, 9999),
      ),
    );
  }

  Future<void> refreshPreservingData() async {
    final previous = state.valueOrNull;
    try {
      final data = await ref.read(bookingRepositoryProvider(arg.client)).getOwnerDashboard(arg.userId);
      state = AsyncData(data);
    } catch (e, st) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  OwnerBooking _copyOwnerStatus(OwnerBooking b, String status) => OwnerBooking(
        id: b.id,
        referenceCode: b.referenceCode,
        userName: b.userName,
        userPhone: b.userPhone,
        userEmail: b.userEmail,
        startTime: b.startTime,
        hours: b.hours,
        totalPrice: b.totalPrice,
        status: status,
      );
}
