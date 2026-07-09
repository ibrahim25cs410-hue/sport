import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../core/network/dio_client_factory.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';

export 'auth_interceptor.dart' show UnauthorizedCallback;

/// HTTP API facade with JWT injection and global 401 handling.
///
/// Prefer depending on repositories in UI code; use this in service classes.
class ApiService {
  ApiService({
    TokenStorage? tokenStorage,
    List<Interceptor>? extraInterceptors,
    Dio? dio,
  }) : _tokens = tokenStorage ?? TokenStorage() {
    _dio = dio ?? DioClientFactory.create(extraInterceptors: extraInterceptors ?? const []);
    _authInterceptor = AuthInterceptor(tokenStorage: _tokens);
    _dio.interceptors.insert(0, _authInterceptor);
  }

  final TokenStorage _tokens;
  late final Dio _dio;
  late final AuthInterceptor _authInterceptor;

  /// Called when the server returns HTTP 401 — wire to navigate to login.
  UnauthorizedCallback? get onUnauthorized => _authInterceptor.onUnauthorized;
  set onUnauthorized(UnauthorizedCallback? callback) {
    _authInterceptor.onUnauthorized = callback;
  }

  Dio get dio => _dio;
  String get baseUrl => _dio.options.baseUrl;

  void refreshBaseUrl() {
    _dio.options.baseUrl = ApiConfig.baseUrl;
  }

  Future<void> saveToken(String token) => _tokens.write(token);

  Future<void> clearToken() => _tokens.delete();

  Future<bool> hasToken() async {
    final token = await _tokens.read();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() => _tokens.read();
}

/// Backward-compatible alias used across the existing codebase.
typedef ApiClient = ApiService;
