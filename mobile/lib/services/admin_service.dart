import 'package:dio/dio.dart';

import '../models/admin_field_item.dart';
import '../models/admin_financial_stats.dart';
import '../models/admin_owner.dart';
import '../models/admin_pending_booking.dart';
import '../models/admin_stats.dart';
import '../models/wallet.dart';
import 'api_client.dart';
import 'wallet_service.dart';

/// Raised when the API returns 403 — caller should show a message, not crash.
class AdminForbiddenException implements Exception {
  AdminForbiddenException([this.message = 'غير مصرح لك بالوصول']);

  final String message;

  @override
  String toString() => message;
}

/// Admin-only API — Bearer token is attached by [AuthInterceptor].
class AdminService {
  AdminService(this._client) : _wallet = WalletService(_client);

  final ApiClient _client;
  final WalletService _wallet;

  Future<T> _guard<T>(Future<Response<dynamic>> Function() request, T Function(dynamic data) parse) async {
    try {
      final res = await request();
      return parse(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final data = e.response?.data;
        final msg = data is Map ? data['message'] as String? : null;
        throw AdminForbiddenException(msg ?? 'غير مصرح لك بالوصول');
      }
      rethrow;
    }
  }

  Future<AdminStats> getStats() => _guard(
        () => _client.dio.get('/admin/stats'),
        (data) => AdminStats.fromJson(data as Map<String, dynamic>),
      );

  Future<AdminFinancialStats> getFinancialStats() => _guard(
        () => _client.dio.get('/admin/financials'),
        (data) => AdminFinancialStats.fromJson(data as Map<String, dynamic>),
      );

  Future<List<AdminOwner>> getOwnersList() => _guard(
        () => _client.dio.get('/admin/owners'),
        (data) => (data as List).map((e) => AdminOwner.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Future<List<AdminPendingBooking>> getPendingBookings() => _guard(
        () => _client.dio.get('/admin/bookings/pending'),
        (data) => (data as List).map((e) => AdminPendingBooking.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Future<List<AdminFieldItem>> getAdminFields() => _guard(
        () => _client.dio.get('/admin/fields'),
        (data) => (data as List).map((e) => AdminFieldItem.fromJson(e as Map<String, dynamic>)).toList(),
      );

  Future<WalletDetail> adminTopUpOwner({
    required int ownerId,
    required int amountIqd,
    String? note,
  }) =>
      _wallet.adminTopUpOwner(ownerId: ownerId, amountIqd: amountIqd, note: note);

  Future<bool> toggleFieldStatus(int id) => _guard(
        () => _client.dio.patch('/admin/fields/$id/toggle'),
        (data) => (data as Map<String, dynamic>)['isActive'] as bool? ?? false,
      );
}
