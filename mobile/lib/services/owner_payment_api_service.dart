import '../models/owner_payment_account.dart';
import 'api_client.dart';

class OwnerPaymentApiService {
  OwnerPaymentApiService(this._client);
  final ApiClient _client;

  Future<OwnerPaymentAccount> getAccount(int ownerId) async {
    final res = await _client.dio.get('/payments/owner/me/account');
    return OwnerPaymentAccount.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PaymentInitiation> initiate({required int invoiceId, required String gateway}) async {
    final res = await _client.dio.post('/payments/initiate', data: {
      'invoiceId': invoiceId,
      'gateway': gateway,
    });
    return PaymentInitiation.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PaymentVerification> verify(String transactionToken) async {
    final res = await _client.dio.post('/payments/verify', data: {
      'transactionToken': transactionToken,
    });
    return PaymentVerification.fromJson(res.data as Map<String, dynamic>);
  }
}
