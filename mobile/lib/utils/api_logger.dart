import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// طباعة تفصيلية في Console (Chrome DevTools / Debug Console).
void apiLog(String message, [Object? detail]) {
  if (!kDebugMode) return;
  debugPrint('[Riyada API] $message${detail != null ? ' → $detail' : ''}');
}

void apiLogError(String context, Object error, [StackTrace? stack]) {
  if (!kDebugMode) return;
  debugPrint('[Riyada API] ❌ $context');
  debugPrint('[Riyada API]   error: $error');
  if (error is DioException) {
    debugPrint('[Riyada API]   type: ${error.type}');
    debugPrint('[Riyada API]   url: ${error.requestOptions.uri}');
    debugPrint('[Riyada API]   method: ${error.requestOptions.method}');
    debugPrint('[Riyada API]   status: ${error.response?.statusCode}');
    debugPrint('[Riyada API]   response: ${error.response?.data}');
    debugPrint('[Riyada API]   message: ${error.message}');
  }
  if (stack != null) {
    debugPrint('[Riyada API]   stack: $stack');
  }
}
