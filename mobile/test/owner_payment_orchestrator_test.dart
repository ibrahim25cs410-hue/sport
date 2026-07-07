import 'package:flutter_test/flutter_test.dart';
import 'package:riyada/core/payment/owner_payment_orchestrator.dart';
import 'package:riyada/core/repositories/owner_payment_repository.dart';
import 'package:riyada/domain/enums/owner_payment_gateway.dart';
import 'package:riyada/domain/payment/payment_gateway.dart';
import 'package:riyada/models/owner_payment_account.dart';
import 'package:riyada/services/api_client.dart';

class _FakePaymentRepository extends OwnerPaymentRepository {
  _FakePaymentRepository() : super(ApiClient());

  PaymentVerification? nextVerify;
  PaymentInitiation? lastInitiation;

  @override
  Future<PaymentInitiation> initiatePayment({
    required int invoiceId,
    required OwnerPaymentGateway gateway,
  }) async {
    lastInitiation = PaymentInitiation(
      transactionToken: 'TXN-test',
      gateway: gateway.apiValue,
      amount: 2400,
      checkoutUrl: 'https://checkout.test/pay',
    );
    return lastInitiation!;
  }

  @override
  Future<PaymentVerification> verifyPayment(String transactionToken) async {
    return nextVerify ??
        PaymentVerification(
          success: true,
          status: 'paid',
          invoiceId: 1,
          outstandingAmount: 0,
          message: 'ok',
        );
  }
}

class _FakeGateway implements PaymentGatewayStrategy {
  _FakeGateway(this._gateway);
  final OwnerPaymentGateway _gateway;

  @override
  OwnerPaymentGateway get gateway => _gateway;

  @override
  Future<GatewayLaunchResult> launchCheckout(GatewayCheckoutSession session) async =>
      const GatewayLaunchResult(launched: true);
}

void main() {
  test('verifyPayment returns event only after server confirms success', () async {
    final repo = _FakePaymentRepository();
    repo.nextVerify = const PaymentVerification(
      success: true,
      status: 'paid',
      invoiceId: 7,
      outstandingAmount: 0,
      message: 'تم الدفع',
    );

    final orchestrator = OwnerPaymentOrchestrator(
      repository: repo,
      gateways: {OwnerPaymentGateway.zainCash: _FakeGateway(OwnerPaymentGateway.zainCash)},
    );

    final event = await orchestrator.verifyPayment('TXN-test');
    expect(event, isNotNull);
    expect(event!.invoiceId, 7);
    expect(event.outstandingAmount, 0);
  });

  test('startExternalPayment uses gateway strategy without card data', () async {
    final repo = _FakePaymentRepository();
    final orchestrator = OwnerPaymentOrchestrator(
      repository: repo,
      gateways: {OwnerPaymentGateway.card: _FakeGateway(OwnerPaymentGateway.card)},
    );

    final result = await orchestrator.startExternalPayment(
      invoiceId: 1,
      gateway: OwnerPaymentGateway.card,
    );

    expect(result.launch.launched, isTrue);
    expect(result.initiation.transactionToken, 'TXN-test');
    expect(repo.lastInitiation?.checkoutUrl, isNotNull);
  });
}
