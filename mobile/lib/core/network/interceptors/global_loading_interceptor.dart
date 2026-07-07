import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show VoidCallback;

const _loadingTrackedKey = '_riyadaGlobalLoadingTracked';

/// Shows the global overlay for API calls unless [RequestOptions.extra] sets
/// `skipGlobalLoading: true` (e.g. health checks, background polling).
///
/// Tracks each request once so Dio retries do not inflate the overlay counter.
class GlobalLoadingInterceptor extends Interceptor {
  GlobalLoadingInterceptor({required this.onShow, required this.onHide});

  final VoidCallback onShow;
  final VoidCallback onHide;

  static const _mutatingMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final force = options.extra['requireGlobalLoading'] == true;
    final skip = options.extra['skipGlobalLoading'] == true;
    final isMutation = _mutatingMethods.contains(options.method.toUpperCase());
    final shouldTrack = !skip && (force || isMutation);

    if (shouldTrack && options.extra[_loadingTrackedKey] != true) {
      options.extra[_loadingTrackedKey] = true;
      onShow();
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _release(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _release(err.requestOptions);
    handler.next(err);
  }

  void _release(RequestOptions options) {
    if (options.extra['skipGlobalLoading'] == true) return;
    if (options.extra[_loadingTrackedKey] == true) {
      options.extra[_loadingTrackedKey] = false;
      onHide();
    }
  }
}
