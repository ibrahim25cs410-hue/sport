import '../../domain/enums/owner_payment_gateway.dart';
import '../../models/owner_payment_account.dart';
import '../../services/api_client.dart';
import '../../services/owner_payment_api_service.dart';

class OwnerPaymentRepository {
  OwnerPaymentRepository(ApiClient client) : _remote = OwnerPaymentApiService(client);
  final OwnerPaymentApiService _remote;

  Future<OwnerPaymentAccount> getAccount(int ownerId) => _remote.getAccount(ownerId);

  Future<PaymentInitiation> initiatePayment({
    required int invoiceId,
    required OwnerPaymentGateway gateway,
  }) =>
      _remote.initiate(invoiceId: invoiceId, gateway: gateway.apiValue);

  Future<PaymentVerification> verifyPayment(String transactionToken) =>
      _remote.verify(transactionToken);
}
