import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../utils/api_logger.dart';
import '../utils/error_messages.dart';

/// Retries transient network failures and normalizes connection errors for the UI.
class NetworkResilienceInterceptor extends Interceptor {
  NetworkResilienceInterceptor(this._dio);

  final Dio _dio;
  static const int maxRetries = 2;

  static bool isTransient(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }
    if (error.error is SocketException || error.error is TimeoutException) {
      return true;
    }
    final status = error.response?.statusCode;
    return status == 502 || status == 503 || status == 504;
  }

  static bool isRetryableRequest(RequestOptions options) {
    final method = options.method.toUpperCase();
    if (method == 'GET' || method == 'HEAD') return true;
    return options.extra['retryOnFailure'] == true;
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = (err.requestOptions.extra['retryCount'] as int?) ?? 0;

    if (isTransient(err) && isRetryableRequest(err.requestOptions) && retryCount < maxRetries) {
      final delayMs = 400 * (retryCount + 1);
      apiLog('Retry ${retryCount + 1}/$maxRetries', '${err.requestOptions.method} ${err.requestOptions.uri} in ${delayMs}ms');
      await Future<void>.delayed(Duration(milliseconds: delayMs));

      final options = err.requestOptions;
      options.extra['retryCount'] = retryCount + 1;

      try {
        final response = await _dio.fetch<dynamic>(options);
        handler.resolve(response);
        return;
      } catch (e) {
        if (e is DioException) {
          err = e;
        } else {
          handler.next(_normalize(err));
          return;
        }
      }
    }

    handler.next(_normalize(err));
  }

  DioException _normalize(DioException error) {
    if (!isTransient(error)) return error;

    final message = friendlyErrorMessage(error);
    return DioException(
      requestOptions: error.requestOptions,
      response: error.response,
      type: error.type,
      error: error.error,
      message: message,
    );
  }
}
