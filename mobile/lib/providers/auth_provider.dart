import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../services/auth_interceptor.dart';
import '../core/providers/repository_providers.dart';
import '../core/repositories/auth_repository.dart';
import '../data/datasources/remote/fcm_service.dart';
import '../models/field.dart';
import '../models/user.dart';
import '../router/app_router.dart';
import '../router/navigation_keys.dart';
import '../services/api_service.dart';
import '../services/session_storage.dart';
import '../utils/api_logger.dart';
import '../utils/error_messages.dart';
import '../providers/socket_provider.dart';
import 'service_providers.dart';

export 'service_providers.dart' show
    apiServiceProvider,
    apiClientProvider,
    authServiceProvider,
    tokenStorageProvider,
    socketServiceProvider;

/// حالة الجلسة — مصدر واحد للمصادقة عبر Riverpod.
class AuthState {
  const AuthState({
    this.user,
    this.ownerField,
    this.loading = false,
    this.bootstrapping = false,
    this.hasStoredToken = false,
    this.error,
  });

  final User? user;
  final Field? ownerField;
  final bool loading;
  final bool bootstrapping;
  final bool hasStoredToken;
  final String? error;

  bool get isLoggedIn => user != null;

  /// Current role from session (`user`, `owner`, or `admin`).
  String? get role => user?.role;

  bool get isAdmin => user?.isAdmin ?? false;

  bool get isOwner => user?.isOwner ?? false;

  AuthState copyWith({
    User? user,
    Field? ownerField,
    bool? loading,
    bool? bootstrapping,
    bool? hasStoredToken,
    String? error,
    bool clearUser = false,
    bool clearField = false,
    bool clearError = false,
  }) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        ownerField: clearField ? null : (ownerField ?? this.ownerField),
        loading: loading ?? this.loading,
        bootstrapping: bootstrapping ?? this.bootstrapping,
        hasStoredToken: hasStoredToken ?? this.hasStoredToken,
        error: clearError ? null : (error ?? this.error),
      );
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Wires the Dio 401 handler to [AuthService.logout] and session cleanup.
final authInterceptorProvider = Provider<void>((ref) {
  ref.watch(apiServiceProvider).onUnauthorized = () async {
    await ref.read(authServiceProvider).logout();
    await ref.read(authProvider.notifier).clearSession();
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      GoRouter.of(ctx).go(AppRoutes.loginUser);
    }
  };
});

class AuthNotifier extends Notifier<AuthState> {
  ApiService get client => ref.read(apiServiceProvider);

  SocketNotifier get _socket => ref.read(socketProvider.notifier);

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() => const AuthState();

  /// Restores the session once at app launch. Token is only cleared on HTTP 401.
  Future<void> bootstrap() async {
    state = state.copyWith(bootstrapping: true, clearError: true);
    await ApiConfig.load();
    client.refreshBaseUrl();
    apiLog('Base URL', client.baseUrl);

    final authService = ref.read(authServiceProvider);
    final hasToken = await authService.hasToken();
    state = state.copyWith(hasStoredToken: hasToken);

    if (!hasToken) {
      state = state.copyWith(bootstrapping: false);
      return;
    }

    try {
      final session = await _repo.bootstrapFromToken();
      state = state.copyWith(user: session.user, ownerField: session.field);
      await SessionStorage.save(session.user, session.field);
      await FcmService.syncTokenWithServer(client);
    } on DioException catch (e) {
      if (AuthInterceptor.isStrictUnauthorized(e)) {
        await authService.logout();
        await SessionStorage.clear();
        state = state.copyWith(clearUser: true, clearField: true, hasStoredToken: false);
      } else {
        await _restoreCachedSession();
      }
    } catch (e, st) {
      apiLogError('bootstrap session restore failed — using cache', e, st);
      await _restoreCachedSession();
    }

    state = state.copyWith(bootstrapping: false);
    if (state.isLoggedIn) {
      await _socket.connect();
    }
  }

  Future<void> _restoreCachedSession() async {
    final cached = await SessionStorage.load();
    if (cached.user != null) {
      state = state.copyWith(user: cached.user, ownerField: cached.field);
      apiLog('Session restored from local cache (offline)');
    }
  }

  Future<void> setApiHost(String? host) async {
    await ApiConfig.setHost(host);
    client.refreshBaseUrl();
    state = state.copyWith();
  }

  Future<void> setApiBaseUrl(String? url) async {
    await ApiConfig.setBaseUrl(url);
    client.refreshBaseUrl();
    state = state.copyWith();
  }

  Future<bool> login(String email, String password, {String? expectedRole}) => _run(() async {
        final r = await _repo.login(email, password, expectedRole: expectedRole);
        final role = expectedRole?.trim().toLowerCase();
        if (role == 'owner' && !r.user.isOwner && !r.user.isAdmin) {
          await ref.read(authServiceProvider).logout();
          throw Exception('هذا حساب مستخدم — استخدم تسجيل دخول المستخدم');
        }
        if (role == 'user' && r.user.isOwner) {
          await ref.read(authServiceProvider).logout();
          throw Exception('هذا حساب صاحب ملعب — استخدم تسجيل دخول أصحاب الملاعب');
        }
        state = state.copyWith(user: r.user, ownerField: r.field, hasStoredToken: true);
        await SessionStorage.save(r.user, r.field);
        await FcmService.syncTokenWithServer(client);
        await _socket.connect();
      });

  Future<bool> registerUser(Map<String, dynamic> body) => _run(() async {
        final r = await _repo.registerUser(body);
        state = state.copyWith(user: r.user, clearField: true, hasStoredToken: true);
        await SessionStorage.save(r.user, null);
        await FcmService.syncTokenWithServer(client);
        await _socket.connect();
      });

  Future<bool> registerOwner(Map<String, dynamic> body) => _run(() async {
        final r = await _repo.registerOwner(body);
        state = state.copyWith(user: r.user, ownerField: r.field, hasStoredToken: true);
        await SessionStorage.save(r.user, r.field);
        await FcmService.syncTokenWithServer(client);
        await _socket.connect();
      });

  /// Clears in-memory session state without touching the stored JWT.
  Future<void> clearSession() async {
    await SessionStorage.clear();
    state = state.copyWith(clearUser: true, clearField: true, clearError: true, hasStoredToken: false);
  }

  Future<void> logout() async {
    await _socket.disconnect();
    await ref.read(authServiceProvider).logout();
    await clearSession();
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? image,
    String? password,
  }) =>
      _run(() async {
        final updated = await _repo.updateProfile(
          name: name,
          phone: phone,
          image: image,
          password: password,
        );
        state = state.copyWith(user: updated);
        await SessionStorage.save(updated, state.ownerField);
      });

  Future<bool> updateField({
    required String name,
    required String address,
    required String phone,
    required int pricePerHour,
    String? image,
  }) async {
    final field = state.ownerField;
    if (field == null) return false;
    return _run(() async {
      final updated = await _repo.updateField(
        fieldId: field.id,
        name: name,
        address: address,
        phone: phone,
        pricePerHour: pricePerHour,
        image: image,
      );
      state = state.copyWith(ownerField: updated);
      if (state.user != null) await SessionStorage.save(state.user!, updated);
    });
  }

  Future<bool> createField({
    required String name,
    required String address,
    required String phone,
    required int pricePerHour,
    String? image,
  }) =>
      _run(() async {
        final created = await _repo.createField(
          name: name,
          address: address,
          phone: phone,
          pricePerHour: pricePerHour,
          image: image,
        );
        state = state.copyWith(ownerField: created);
        if (state.user != null) await SessionStorage.save(state.user!, created);
      });

  Future<bool> _run(Future<void> Function() fn) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await fn();
      return true;
    } catch (e) {
      state = state.copyWith(error: friendlyErrorMessage(e));
      return false;
    } finally {
      state = state.copyWith(loading: false);
    }
  }
}
