import '../models/owner_payment_account.dart';
import 'api_client.dart';

class UserBookingPaymentApiService {
  UserBookingPaymentApiService(this._client);
  final ApiClient _client;

  Future<PaymentInitiation> initiate({required int bookingId, required String gateway}) async {
    final res = await _client.dio.post('/bookings/$bookingId/pay/initiate', data: {'gateway': gateway});
    return PaymentInitiation.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PaymentVerification> verify(String transactionToken) async {
    final res = await _client.dio.post('/bookings/pay/verify', data: {'transactionToken': transactionToken});
    return PaymentVerification.fromJson(res.data as Map<String, dynamic>);
  }
}
