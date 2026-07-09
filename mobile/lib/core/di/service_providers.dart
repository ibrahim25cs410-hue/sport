import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../loading/global_loading_provider.dart';
import '../network/interceptors/global_loading_interceptor.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/socket_service.dart';
import '../../services/stadium_service.dart';
import '../../services/token_storage.dart';

export '../../services/api_service.dart' show ApiService, UnauthorizedCallback;

/// Shared secure token storage — single instance for auth and API layers.
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Primary HTTP client with JWT interceptor and global loading.
final apiServiceProvider = Provider<ApiService>((ref) {
  final loading = ref.read(globalLoadingProvider.notifier);
  return ApiService(
    tokenStorage: ref.watch(tokenStorageProvider),
    extraInterceptors: [
      GlobalLoadingInterceptor(
        onShow: loading.show,
        onHide: loading.hide,
      ),
    ],
  );
});

/// Backward-compatible alias.
final apiClientProvider = apiServiceProvider;

/// Authentication service — token persistence and auth API calls.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(apiServiceProvider),
    ref.watch(tokenStorageProvider),
  );
});

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(ref.watch(apiServiceProvider));
});

final stadiumServiceProvider = Provider<StadiumService>((ref) {
  return StadiumService(ref.watch(apiServiceProvider));
});

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService(tokenStorage: ref.watch(tokenStorageProvider));
  ref.onDispose(service.dispose);
  return service;
});
