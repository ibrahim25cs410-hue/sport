import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../loading/global_loading_provider.dart';
import '../network/interceptors/global_loading_interceptor.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/token_storage.dart';

/// Shared secure token storage — single instance for [AuthService] and [ApiClient].
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// API client with Dio auth + global loading interceptors.
final apiClientProvider = Provider<ApiClient>((ref) {
  final loading = ref.read(globalLoadingProvider.notifier);
  return ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    extraInterceptors: [
      GlobalLoadingInterceptor(
        onShow: loading.show,
        onHide: loading.hide,
      ),
    ],
  );
});

/// Authentication service — token persistence and auth API calls.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});
