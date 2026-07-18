import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../utils/api_logger.dart';

/// JWT storage backed only by OS-protected secure storage.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? secure, SecureTokenStore? store})
      : _secure = store ??
            FlutterSecureTokenStore(
              secure ??
                  const FlutterSecureStorage(
                    aOptions: AndroidOptions(encryptedSharedPreferences: true),
                    wOptions: WindowsOptions(useBackwardCompatibility: false),
                  ),
            );

  final SecureTokenStore _secure;
  static const _fallbackKey = 'riyada_jwt_fallback';

  Future<void> write(String token) async {
    if (!isUsableJwt(token)) throw const FormatException('Refusing to store an invalid or expired JWT');
    await _secure.write(key: ApiConfig.tokenKey, value: token);
    await _deleteLegacyFallback();
  }

  Future<String?> read() async {
    String? secure;
    try {
      secure = await _secure.read(key: ApiConfig.tokenKey);
    } catch (_) {
      await _deleteLegacyFallback();
      rethrow;
    }
    if (secure != null && secure.isNotEmpty) {
      if (isUsableJwt(secure)) {
        await _deleteLegacyFallback();
        return secure;
      }
      await delete();
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_fallbackKey);
    if (legacy == null) return null;
    try {
      if (!isUsableJwt(legacy)) return null;
      await _secure.write(key: ApiConfig.tokenKey, value: legacy);
      return legacy;
    } catch (e, st) {
      apiLogError('Legacy token migration failed; session discarded', e, st);
      return null;
    } finally {
      await prefs.remove(_fallbackKey);
    }
  }

  Future<void> delete() async {
    try {
      await _secure.delete(key: ApiConfig.tokenKey);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fallbackKey);
  }

  Future<void> _deleteLegacyFallback() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fallbackKey);
  }

  static bool isUsableJwt(String token, {DateTime? now}) {
    final parts = token.split('.');
    if (parts.length != 3) return false;
    try {
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
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
  Future<void> write({required String key, required String? value}) => _storage.write(key: key, value: value);
  @override
  Future<String?> read({required String key}) => _storage.read(key: key);
  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}
