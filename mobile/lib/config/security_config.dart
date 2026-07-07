import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

/// إعدادات أمنية — تُقرأ من --dart-define أو --dart-define-from-file.
abstract final class SecurityConfig {
  /// تفعيل SSL Pinning في الإنتاج: --dart-define=SSL_PINNING_ENABLED=true
  static const bool sslPinningEnabled = bool.fromEnvironment(
    'SSL_PINNING_ENABLED',
    defaultValue: false,
  );

  /// بصمة SHA-256 لشهادة السيرفر (hex بدون فواصل):
  /// openssl s_client -connect api.riyada.iq:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
  /// أو fingerprint الشهادة مباشرة حسب المنصة.
  /// --dart-define=SSL_PIN_SHA256=ABCD1234...
  static const String sslPinSha256 = String.fromEnvironment('SSL_PIN_SHA256');

  /// يُفعَّل التثبيت فقط في release على المنصات الأصلية (ليس web/debug).
  static bool get shouldPinCertificates =>
      !kIsWeb && kReleaseMode && sslPinningEnabled && sslPinSha256.isNotEmpty;
}
