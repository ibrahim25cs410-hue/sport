import 'package:dio/dio.dart';

import '../utils/api_logger.dart';
import 'token_storage.dart';

typedef UnauthorizedCallback = Future<void> Function();

/// Attaches Bearer tokens and handles session revocation on strict HTTP 401 only.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    this.onUnauthorized,
  }) : _tokens = tokenStorage;

  final TokenStorage _tokens;
  UnauthorizedCallback? onUnauthorized;
  bool _handlingUnauthorized = false;

  static bool isPublicAuthPath(String path) {
    return path == '/login' ||
        path == '/register-user' ||
        path == '/register-owner';
  }

  /// True only when the server returned HTTP 401 — never for timeouts or transport errors.
  static bool isStrictUnauthorized(DioException error) {
    return error.response?.statusCode == 401;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    apiLog('→ ${options.method} ${options.uri}');
    final token = await _tokens.read();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    apiLog('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  /// HTTP 403 — permission denied; session stays active (handled per-service, e.g. [AdminService]).
  static bool isForbidden(DioException error) => error.response?.statusCode == 403;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      if (isStrictUnauthorized(err) &&
          !_handlingUnauthorized &&
          !isPublicAuthPath(err.requestOptions.path)) {
        final token = await _tokens.read();
        if (token != null && token.isNotEmpty) {
          _handlingUnauthorized = true;
          try {
            await onUnauthorized?.call();
          } catch (e, st) {
            apiLogError('onUnauthorized handler failed', e, st);
          } finally {
            _handlingUnauthorized = false;
          }
        }
      }
    } catch (e, st) {
      apiLogError('AuthInterceptor.onError failed', e, st);
    } finally {
      handler.next(err);
    }
  }
}
