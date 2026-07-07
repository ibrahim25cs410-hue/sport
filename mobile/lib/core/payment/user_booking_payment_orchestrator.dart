import '../../data/payment/card_payment_gateway.dart';
import '../../data/payment/zain_cash_payment_gateway.dart';
import '../../domain/enums/owner_payment_gateway.dart';
import '../../domain/payment/payment_gateway.dart';
import '../../models/owner_payment_account.dart';
import '../repositories/user_booking_payment_repository.dart';

class UserBookingPaymentOrchestrator {
  UserBookingPaymentOrchestrator({
    required UserBookingPaymentRepository repository,
    Map<OwnerPaymentGateway, PaymentGatewayStrategy>? gateways,
  })  : _repository = repository,
        _gateways = gateways ??
            {
              OwnerPaymentGateway.zainCash: ZainCashPaymentGateway(),
              OwnerPaymentGateway.card: CardPaymentGateway(),
            };

  final UserBookingPaymentRepository _repository;
  final Map<OwnerPaymentGateway, PaymentGatewayStrategy> _gateways;

  Future<({PaymentInitiation initiation, GatewayLaunchResult launch})> startExternalPayment({
    required int bookingId,
    required OwnerPaymentGateway gateway,
  }) async {
    final initiation = await _repository.initiatePayment(bookingId: bookingId, gateway: gateway);
    final strategy = _gateways[gateway]!;
    final launch = await strategy.launchCheckout(GatewayCheckoutSession(
      transactionToken: initiation.transactionToken,
      amount: initiation.amount,
      checkoutUrl: initiation.checkoutUrl,
    ));
    return (initiation: initiation, launch: launch);
  }

  Future<PaymentVerification> verifyPayment(String transactionToken) =>
      _repository.verifyPayment(transactionToken);
}
