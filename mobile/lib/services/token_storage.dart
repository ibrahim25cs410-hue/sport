import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../utils/api_logger.dart';

/// JWT storage backed only by OS-protected secure storage.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? secure, SecureTokenStore? store})
    : _secure =
          store ??
          FlutterSecureTokenStore(
            secure ??
                const FlutterSecureStorage(
                  aOptions: AndroidOptions(encryptedSharedPreferences: true),
                  wOptions: WindowsOptions(useBackwardCompatibility: false),
                ),
          );

  final SecureTokenStore _secure;
  static const _fallbackKey = 'riyada_jwt_fallback';
  Future<void> _operation = Future<void>.value();
  String? _cachedToken;
  bool _cacheLoaded = false;
  bool _legacyCleanupDone = false;

  Future<void> write(String token) => _synchronized(() async {
    if (!isUsableJwt(token)) {
      throw const FormatException(
        'Refusing to store an invalid or expired JWT',
      );
    }
    await _secure.write(key: ApiConfig.tokenKey, value: token);
    _cachedToken = token;
    _cacheLoaded = true;
    await _deleteLegacyFallback();
  });

  Future<String?> read() => _synchronized(() async {
    if (_cacheLoaded) {
      if (_cachedToken == null || isUsableJwt(_cachedToken!)) {
        return _cachedToken;
      }
      await _deleteStoredToken();
      return null;
    }

    String? secure;
    try {
      secure = await _secure.read(key: ApiConfig.tokenKey);
    } catch (_) {
      await _deleteLegacyFallback();
      rethrow;
    }
    if (secure != null && secure.isNotEmpty) {
      if (isUsableJwt(secure)) {
        _cachedToken = secure;
        _cacheLoaded = true;
        await _deleteLegacyFallback();
        return secure;
      }
      await _deleteStoredToken();
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_fallbackKey);
    if (legacy == null) {
      _cachedToken = null;
      _cacheLoaded = true;
      return null;
    }
    try {
      if (!isUsableJwt(legacy)) return null;
      await _secure.write(key: ApiConfig.tokenKey, value: legacy);
      _cachedToken = legacy;
      _cacheLoaded = true;
      return legacy;
    } catch (e, st) {
      apiLogError('Legacy token migration failed; session discarded', e, st);
      return null;
    } finally {
      await prefs.remove(_fallbackKey);
      _legacyCleanupDone = true;
    }
  });

  Future<void> delete() => _synchronized(_deleteStoredToken);

  Future<void> _deleteStoredToken() async {
    try {
      await _secure.delete(key: ApiConfig.tokenKey);
    } catch (_) {}
    _cachedToken = null;
    _cacheLoaded = true;
    await _deleteLegacyFallback();
  }

  Future<void> _deleteLegacyFallback() async {
    if (_legacyCleanupDone) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fallbackKey);
    _legacyCleanupDone = true;
  }

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final result = _operation.then((_) => action());
    _operation = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  static bool isUsableJwt(String token, {DateTime? now}) {
    final parts = token.split('.');
    if (parts.length != 3) return false;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) return false;
      final exp = payload['exp'];
      if (exp is! num) return false;
      final instant = now ?? DateTime.now();
      return exp.toInt() > instant.toUtc().millisecondsSinceEpoch ~/ 1000 + 30;
    } catch (_) {
      return false;
    }
  }
}

abstract interface class SecureTokenStore {
  Future<void> write({required String key, required String? value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

final class FlutterSecureTokenStore implements SecureTokenStore {
  const FlutterSecureTokenStore(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<void> write({required String key, required String? value}) =>
      _storage.write(key: key, value: value);
  @override
  Future<String?> read({required String key}) => _storage.read(key: key);
  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}
