import 'package:dio/dio.dart';

import '../models/wallet.dart';
import 'api_client.dart';

class WalletService {
  WalletService(this._client);
  final ApiClient _client;

  Future<WalletStatus> getStatus() async {
    final res = await _client.dio.get('/owner/wallet/status');
    return WalletStatus.fromJson(res.data as Map<String, dynamic>);
  }

  Future<WalletDetail> getWallet() async {
    final res = await _client.dio.get('/owner/wallet');
    return WalletDetail.fromJson(res.data as Map<String, dynamic>);
  }

  /// Admin-only — credits an owner wallet after in-person payment.
  Future<WalletDetail> adminTopUpOwner({
    required int ownerId,
    required int amountIqd,
    String? note,
  }) async {
    try {
      final res = await _client.dio.post('/admin/wallets/top-up', data: {
        'ownerId': ownerId,
        'amount': amountIqd,
        if (note != null && note.isNotEmpty) 'note': note,
      });
      return WalletDetail.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('غير مصرح لك بتنفيذ هذه العملية');
      }
      rethrow;
    }
  }
}
