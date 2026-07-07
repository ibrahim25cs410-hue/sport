import '../../domain/enums/owner_payment_gateway.dart';
import '../../models/owner_payment_account.dart';
import '../../services/api_client.dart';
import '../../services/user_booking_payment_api_service.dart';

class UserBookingPaymentRepository {
  UserBookingPaymentRepository(ApiClient client) : _remote = UserBookingPaymentApiService(client);
  final UserBookingPaymentApiService _remote;

  Future<PaymentInitiation> initiatePayment({
    required int bookingId,
    required OwnerPaymentGateway gateway,
  }) =>
      _remote.initiate(bookingId: bookingId, gateway: gateway.apiValue);

  Future<PaymentVerification> verifyPayment(String transactionToken) => _remote.verify(transactionToken);
}
