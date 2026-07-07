import '../enums/owner_payment_gateway.dart';

/// جلسة دفع خارجية — يُمرَّر رمز المعاملة فقط، بدون بيانات حساسة.
class GatewayCheckoutSession {
  const GatewayCheckoutSession({
    required this.transactionToken,
    required this.amount,
    this.checkoutUrl,
  });

  final String transactionToken;
  final int amount;
  final String? checkoutUrl;
}

/// نتيجة إطلاق بوابة الدفع الخارجية.
class GatewayLaunchResult {
  const GatewayLaunchResult({required this.launched, this.message});

  final bool launched;
  final String? message;
}

/// استراتيجية بوابة دفع — Strategy Pattern.
abstract interface class PaymentGatewayStrategy {
  OwnerPaymentGateway get gateway;

  /// يفتح صفحة الدفع الخارجية (زين كاش أو hosted checkout للبطاقة).
  /// لا يُدخل المستخدم بيانات البطاقة داخل التطبيق.
  Future<GatewayLaunchResult> launchCheckout(GatewayCheckoutSession session);
}
