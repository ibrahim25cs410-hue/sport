import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/admin_field_item.dart';
import '../../models/admin_financial_stats.dart';
import '../../models/admin_owner.dart';
import '../../models/admin_pending_booking.dart';
import '../../models/admin_stats.dart';
import '../../providers/service_providers.dart';
import '../../providers/session_key.dart';
import '../../services/admin_service.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(ref.watch(apiClientProvider));
});

final adminStatsProvider = FutureProvider.family<AdminStats, UserSessionKey>((ref, key) async {
  return ref.watch(adminServiceProvider).getStats();
});

final adminFinancialStatsProvider =
    FutureProvider.family<AdminFinancialStats, UserSessionKey>((ref, key) async {
  return ref.watch(adminServiceProvider).getFinancialStats();
});

final adminOwnersProvider = FutureProvider.family<List<AdminOwner>, UserSessionKey>((ref, key) async {
  return ref.watch(adminServiceProvider).getOwnersList();
});

final adminFieldsProvider = FutureProvider.family<List<AdminFieldItem>, UserSessionKey>((ref, key) async {
  return ref.watch(adminServiceProvider).getAdminFields();
});

final adminPendingBookingsProvider =
    FutureProvider.family<List<AdminPendingBooking>, UserSessionKey>((ref, key) async {
  return ref.watch(adminServiceProvider).getPendingBookings();
});
