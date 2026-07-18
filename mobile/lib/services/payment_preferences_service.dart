import 'package:shared_preferences/shared_preferences.dart';

import '../config/payment_policy.dart';
import '../domain/enums/owner_payment_gateway.dart';

/// تفضيل بوابة الدفع الافتراضية للمستخدم.
abstract final class PaymentPreferencesService {
  static const _gatewayKey = 'riyada_preferred_payment_gateway';

  static Future<OwnerPaymentGateway> loadGateway() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_gatewayKey);
    if (raw == null || raw.isEmpty) return OwnerPaymentGateway.zainCash;
    return OwnerPaymentGateway.fromApiValue(raw);
  }

  static Future<void> saveGateway(OwnerPaymentGateway gateway) async {
    PaymentPolicy.requireElectronicPayments();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gatewayKey, gateway.apiValue);
  }
}
