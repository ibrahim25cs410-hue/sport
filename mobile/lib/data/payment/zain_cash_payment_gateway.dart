import 'package:url_launcher/url_launcher.dart';

import '../../domain/enums/owner_payment_gateway.dart';
import '../../domain/payment/payment_gateway.dart';

/// دفع زين كاش — إعادة توجيه لبوابة خارجية برمز معاملة فقط.
class ZainCashPaymentGateway implements PaymentGatewayStrategy {
  @override
  OwnerPaymentGateway get gateway => OwnerPaymentGateway.zainCash;

  @override
  Future<GatewayLaunchResult> launchCheckout(GatewayCheckoutSession session) async {
    final url = session.checkoutUrl;
    if (url == null || url.isEmpty) {
      return const GatewayLaunchResult(launched: false, message: 'missing_checkout_url');
    }
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    return GatewayLaunchResult(launched: launched);
  }
}
