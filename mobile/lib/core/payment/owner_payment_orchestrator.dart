import '../../data/payment/card_payment_gateway.dart';
import '../../data/payment/zain_cash_payment_gateway.dart';
import '../../config/payment_policy.dart';
import '../../domain/enums/owner_payment_gateway.dart';
import '../../domain/payment/payment_gateway.dart';
import '../../models/owner_payment_account.dart';
import '../repositories/owner_payment_repository.dart';
class OwnerPaymentVerifiedEvent {
  const OwnerPaymentVerifiedEvent({
    required this.invoiceId,
    required this.outstandingAmount,
    required this.message,
  });

  final int? invoiceId;
  final int outstandingAmount;
  final String message;
}

/// واجهة خدمة الدفع — تسمح بتبديل بوابة الدفع (Strategy Pattern).
abstract interface class PaymentService {
  Future<OwnerPaymentAccount> loadAccount(int ownerId);
  Future<({PaymentInitiation initiation, GatewayLaunchResult launch})> startExternalPayment({
    required int invoiceId,
    required OwnerPaymentGateway gateway,
  });
  Future<OwnerPaymentVerifiedEvent?> verifyPayment(String transactionToken);
}

/// منسّق الدفع — يجمع بين الـ API وبوابات الدفع دون تخزين بيانات حساسة.
class OwnerPaymentOrchestrator implements PaymentService {
  OwnerPaymentOrchestrator({
    required OwnerPaymentRepository repository,
    Map<OwnerPaymentGateway, PaymentGatewayStrategy>? gateways,
  })  : _repository = repository,
        _gateways = gateways ??
            {
              OwnerPaymentGateway.zainCash: ZainCashPaymentGateway(),
              OwnerPaymentGateway.card: CardPaymentGateway(),
            };

  final OwnerPaymentRepository _repository;
  final Map<OwnerPaymentGateway, PaymentGatewayStrategy> _gateways;

  @override
  Future<OwnerPaymentAccount> loadAccount(int ownerId) => _repository.getAccount(ownerId);

  PaymentGatewayStrategy gatewayFor(OwnerPaymentGateway gateway) {
    PaymentPolicy.requireElectronicPayments();
    return _gateways[gateway]!;
  }

  /// يبدأ الدفع عبر البوابة المختارة ويفتح صفحة الدفع الخارجية.
  @override
  Future<({PaymentInitiation initiation, GatewayLaunchResult launch})> startExternalPayment({
    required int invoiceId,
    required OwnerPaymentGateway gateway,
  }) async {
    PaymentPolicy.requireElectronicPayments();
    final initiation = await _repository.initiatePayment(invoiceId: invoiceId, gateway: gateway);
    final strategy = _gateways[gateway]!;
    final launch = await strategy.launchCheckout(GatewayCheckoutSession(
      transactionToken: initiation.transactionToken,
      amount: initiation.amount,
      checkoutUrl: initiation.checkoutUrl,
    ));
    return (initiation: initiation, launch: launch);
  }

  /// يتحقق من السيرفر أن العملية نجحت قبل تحديث حالة الحساب.
  @override
  Future<OwnerPaymentVerifiedEvent?> verifyPayment(String transactionToken) async {
    PaymentPolicy.requireElectronicPayments();
    final result = await _repository.verifyPayment(transactionToken);
    if (!result.success) return null;
    return OwnerPaymentVerifiedEvent(
      invoiceId: result.invoiceId,
      outstandingAmount: result.outstandingAmount,
      message: result.message,
    );
  }
}
