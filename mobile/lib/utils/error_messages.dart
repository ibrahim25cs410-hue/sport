import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/api_config.dart';

/// يحوّل أخطاء Dio والشبكة إلى رسائل عربية واضحة للمستخدم.
String friendlyErrorMessage(Object? error) {
  if (error == null) return 'حدث خطأ غير متوقع، حاول مجدداً.';

  if (error is PlatformException) {
    return 'تعذّر حفظ بيانات الجلسة على الجهاز. أعد تشغيل التطبيق وحاول مجدداً.';
  }

  if (error is DioException) {
    final serverMsg = _apiMessage(error);
    if (serverMsg != null && !_isTechnical(serverMsg) && serverMsg.length < 160) {
      return serverMsg;
    }
    return _mapDioType(error);
  }

  final raw = error.toString()
      .replaceAll('Exception:', '')
      .replaceAll('DioException [', '')
      .trim();

  if (_isTechnical(raw)) return _genericConnection();
  if (raw.length > 160) return 'حدث خطأ، يرجى المحاولة لاحقاً.';
  return raw.isEmpty ? 'حدث خطأ غير متوقع.' : raw;
}

String? _apiMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map) {
    final code = data['code'];
    if (code == 'rate_limit_exceeded') {
      return 'طلبات كثيرة — انتظر قليلاً ثم حاول مجدداً.';
    }
    if (code == 'InsufficientFunds') {
      return 'رصيد المحفظة غير كافٍ لتغطية العمولة. يرجى شحن الرصيد.';
    }
    if (code == 'SERVICE_UNAVAILABLE') {
      return 'تعذّر الاتصال بالخادم. تحقق من الإنترنت وحاول مجدداً.';
    }
    final m = data['message'];
    if (m is String && m.trim().isNotEmpty) return m.trim();
  }
  final msg = e.message?.trim();
  if (msg != null && msg.isNotEmpty) return msg;
  return null;
}

bool _isTechnical(String s) {
  final lower = s.toLowerCase();
  return lower.contains('dioexception') ||
      lower.contains('xmlhttprequest') ||
      lower.contains('socketexception') ||
      lower.contains('connection errored') ||
      lower.contains('connection refused') ||
      lower.contains('failed host lookup') ||
      lower.contains('network layer') ||
      lower.contains('localhost:') ||
      lower.contains('err_connection') ||
      lower.contains('type ') && lower.contains('is not a subtype');
}

String _mapDioType(DioException e) {
  if (e.response == null &&
      (e.type == DioExceptionType.unknown ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout)) {
    return _genericConnection();
  }

  return switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      _genericConnection(),
    DioExceptionType.badResponse => _httpStatus(e.response?.statusCode, _apiMessage(e)),
    DioExceptionType.cancel => 'تم إلغاء الطلب.',
    DioExceptionType.unknown => e.response == null ? _genericConnection() : 'حدث خطأ، يرجى المحاولة لاحقاً.',
    _ => 'حدث خطأ، يرجى المحاولة لاحقاً.',
  };
}

String _genericConnection() {
  if (kReleaseMode) {
    return 'تعذّر الاتصال. تحقق من الإنترنت وحاول مجدداً.';
  }
  final url = ApiConfig.baseUrl;
  return 'عذراً، لم نتمكن من الاتصال بالخادم.\n'
      '• العنوان الحالي: $url\n'
      '• شغّل الخادم: .\\scripts\\run-api.ps1\n'
      '• على الهاتف: الإعدادات ← عنوان IP للكمبيوتر\n'
      '  (مثل 192.168.x.x:${ApiConfig.port})';
}

String _httpStatus(int? code, String? serverMsg) {
  if (serverMsg != null && !_isTechnical(serverMsg) && serverMsg.length < 160) {
    if (code == 400 || code == 402 || code == 409 || code == 429) return serverMsg;
  }
  return switch (code) {
    400 => serverMsg ?? 'البيانات المدخلة غير صحيحة.',
    401 => 'البريد أو كلمة المرور غير صحيحة.',
    403 => 'ليس لديك صلاحية لهذا الإجراء.',
    404 => 'تعذّر إتمام الطلب. حاول مرة أخرى لاحقاً.',
    402 => serverMsg ?? 'رصيد المحفظة غير كافٍ لتغطية العمولة. يرجى شحن الرصيد.',
    409 => serverMsg ?? 'هذا الإجراء غير متاح حالياً.',
    429 => 'طلبات كثيرة — انتظر قليلاً ثم حاول مجدداً.',
    500 || 502 || 503 || 504 => serverMsg ?? 'الخادم غير متاح حالياً. حاول لاحقاً.',
    _ => serverMsg ?? 'حدث خطأ، يرجى المحاولة لاحقاً.',
  };
}

/// يستخرج أرقام الهاتف العراقي فقط (07xxxxxxxxx).
String normalizeIraqiPhone(String input) =>
    input.replaceAll(RegExp(r'\D'), '');
