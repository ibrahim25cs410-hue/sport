import 'package:dio/dio.dart';

import '../../../config/api_config.dart';
import '../../../core/security/ssl_pinning.dart';
import '../../../utils/api_logger.dart';
import '../../../utils/error_messages.dart';
import '../../../services/network_resilience_interceptor.dart';

/// Central Dio configuration — keeps transport concerns out of [ApiClient].
abstract final class DioClientFactory {
  static Dio create({List<Interceptor> extraInterceptors = const []}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 12),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    configureSslPinning(dio);

    for (final interceptor in extraInterceptors) {
      dio.interceptors.add(interceptor);
    }

    dio.interceptors.add(NetworkResilienceInterceptor(dio));
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          apiLogError('Network/Server error', error);
          final data = error.response?.data;
          if (data is Map && data['message'] != null) {
            handler.next(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: error.type,
                message: data['message'] as String,
              ),
            );
            return;
          }
          if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            handler.next(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: error.type,
                message: friendlyErrorMessage(error),
              ),
            );
            return;
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}
