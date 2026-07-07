import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../core/network/dio_client_factory.dart';
import 'auth_interceptor.dart';
import 'token_storage.dart';

export 'auth_interceptor.dart' show UnauthorizedCallback;

/// HTTP client facade — presentation must depend on repositories, not Dio directly.
class ApiClient {
  ApiClient({TokenStorage? tokenStorage, List<Interceptor>? extraInterceptors})
      : _tokens = tokenStorage ?? TokenStorage() {
    _dio = DioClientFactory.create(extraInterceptors: extraInterceptors ?? const []);
    _authInterceptor = AuthInterceptor(tokenStorage: _tokens);
    _dio.interceptors.insert(0, _authInterceptor);
  }

  final TokenStorage _tokens;
  late final Dio _dio;
  late final AuthInterceptor _authInterceptor;

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
    final t = await _tokens.read();
    return t != null && t.isNotEmpty;
  }

  Future<String?> getToken() => _tokens.read();
}
