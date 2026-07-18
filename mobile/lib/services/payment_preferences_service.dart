import 'package:shared_preferences/shared_preferences.dart';

import '../domain/enums/owner_payment_gateway.dart';

/// تفضيل بوابة الدفع الافتراضية للمستخدم.
abstract final class PaymentPreferencesService {
  static const _gatewayKey = 'riyada_preferred_payment_gateway';

  /// Temporary launch mode: bookings are cash-at-venue only.
  /// Re-enable later with --dart-define=ELECTRONIC_PAYMENTS_ENABLED=true.
  static const electronicPaymentsEnabled = bool.fromEnvironment(
    'ELECTRONIC_PAYMENTS_ENABLED',
    defaultValue: false,
  );

  static Future<OwnerPaymentGateway> loadGateway() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_gatewayKey);
    if (raw == null || raw.isEmpty) return OwnerPaymentGateway.zainCash;
    return OwnerPaymentGateway.fromApiValue(raw);
  }

  static Future<void> saveGateway(OwnerPaymentGateway gateway) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gatewayKey, gateway.apiValue);
  }
}
