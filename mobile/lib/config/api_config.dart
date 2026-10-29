import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:shared_preferences/shared_preferences.dart';

/// إعدادات الربط بالـ API — مصدر واحد لـ baseUrl (بيئة + تفضيلات المستخدم).
abstract final class ApiConfig {
  /// منفذ الخادم: --dart-define=API_PORT=61082
  static const String port = String.fromEnvironment('API_PORT', defaultValue: '61082');

  /// مضيف كامل أو جزئي: --dart-define=API_HOST=192.168.1.10
  static const String hostOverride = String.fromEnvironment('API_HOST');

  /// رابط كامل: --dart-define=API_BASE_URL=http://192.168.1.10:61082/api
  static const String baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  /// http أو https
  static const String scheme = String.fromEnvironment('API_SCHEME', defaultValue: 'http');

  static const String _hostKey = 'api_host_override';
  static const String _baseUrlKey = 'api_base_url_override';

  static String? _runtimeHost;
  static String? _runtimeBaseUrl;

  /// يُحمَّل من SharedPreferences عند بدء التطبيق (تطوير فقط).
  static Future<void> load() async {
    // A build-time endpoint is authoritative, even in debug APKs distributed
    // for testing. Never let an old localhost preference override it.
    if (kReleaseMode || baseUrlOverride.isNotEmpty || hostOverride.isNotEmpty) {
      _runtimeHost = null;
      _runtimeBaseUrl = null;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _runtimeHost = prefs.getString(_hostKey);
    _runtimeBaseUrl = prefs.getString(_baseUrlKey);
  }

  static Future<void> setHost(String? host) async {
    _runtimeHost = host?.trim().isEmpty == true ? null : host?.trim();
    _runtimeBaseUrl = null;
    final prefs = await SharedPreferences.getInstance();
    if (_runtimeHost == null) {
      await prefs.remove(_hostKey);
    } else {
      await prefs.setString(_hostKey, _runtimeHost!);
    }
    await prefs.remove(_baseUrlKey);
  }

  static Future<void> setBaseUrl(String? url) async {
    final normalized = url == null || url.trim().isEmpty ? null : normalizeBaseUrl(url.trim());
    _runtimeBaseUrl = normalized;
    _runtimeHost = null;
    final prefs = await SharedPreferences.getInstance();
    if (normalized == null) {
      await prefs.remove(_baseUrlKey);
      await prefs.remove(_hostKey);
    } else {
      await prefs.setString(_baseUrlKey, normalized);
      await prefs.remove(_hostKey);
    }
  }

  static String? get savedHost => _runtimeHost;
  static String? get savedBaseUrl => _runtimeBaseUrl;

  /// هل تم ضبط عنوان API عبر dart-define أو تفضيلات المستخدم؟
  static bool get isExplicitlyConfigured =>
      baseUrlOverride.isNotEmpty ||
      hostOverride.isNotEmpty ||
      (_runtimeBaseUrl?.isNotEmpty == true) ||
      (_runtimeHost?.isNotEmpty == true);

  /// الرابط الفعّال — dart-define أولاً، ثم تفضيلات التطوير فقط عند غيابه.
  static String get baseUrl {
    if (baseUrlOverride.isNotEmpty) {
      return normalizeBaseUrl(baseUrlOverride);
    }
    if (hostOverride.isNotEmpty) {
      return normalizeBaseUrl('$scheme://$hostOverride:$port/api');
    }
    if (!kReleaseMode) {
      if (_runtimeBaseUrl?.isNotEmpty == true) {
        return normalizeBaseUrl(_runtimeBaseUrl!);
      }
      final host = _runtimeHost?.isNotEmpty == true ? _runtimeHost : null;
      if (host != null) {
        return '$scheme://$host:$port/api';
      }
    }
    if (kReleaseMode) {
      return normalizeBaseUrl('https://sports-x7v7.onrender.com/api');
    }
    return '$scheme://${_defaultHost()}:$port/api';
  }

  static String _defaultHost() {
    if (kIsWeb) return 'localhost';
    if (!kIsWeb && Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }

  /// يضمن انتهاء الرابط بـ /api
  static String normalizeBaseUrl(String raw) {
    var url = raw.trim();
    if (!url.contains('://')) {
      url = '$scheme://$url';
    }
    url = url.replaceAll(RegExp(r'/+$'), '');
    if (!url.endsWith('/api')) {
      url = '$url/api';
    }
    return url;
  }

  /// Socket.io server origin (without `/api` suffix).
  static String get socketBaseUrl => baseUrl.replaceAll(RegExp(r'/api/?$'), '');

  static const String tokenKey = 'riyada_jwt';
}
