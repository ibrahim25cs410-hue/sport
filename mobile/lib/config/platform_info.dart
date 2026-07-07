import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'api_config.dart';

/// معلومات المنصة — المضيف الافتراضي حسب الجهاز (محاكي أندرويد، سطح مكتب، إلخ).
abstract final class PlatformInfo {
  static String defaultApiHost() {
    if (kIsWeb) return 'localhost';
    if (!kIsWeb && Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  /// يُستدعى من ApiClient عند تغيير الإعدادات أو بعد bootstrap.
  static String resolveBaseUrl() => ApiConfig.baseUrl;
}
