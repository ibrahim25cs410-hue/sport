import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../utils/api_logger.dart';

/// تخزين JWT — يحاول التخزين الآمن أولاً ثم SharedPreferences كاحتياطي (Windows/تطوير).
class TokenStorage {
  TokenStorage({FlutterSecureStorage? secure})
      : _secure = secure ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              wOptions: WindowsOptions(useBackwardCompatibility: false),
            );

  final FlutterSecureStorage _secure;
  static const _fallbackKey = 'riyada_jwt_fallback';

  Future<void> write(String token) async {
    try {
      await _secure.write(key: ApiConfig.tokenKey, value: token);
      return;
    } catch (e, st) {
      apiLogError('secure token write failed — using fallback', e, st);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fallbackKey, token);
  }

  Future<String?> read() async {
    try {
      final secure = await _secure.read(key: ApiConfig.tokenKey);
      if (secure != null && secure.isNotEmpty) return secure;
    } catch (e, st) {
      apiLogError('secure token read failed — using fallback', e, st);
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fallbackKey);
  }

  Future<void> delete() async {
    try {
      await _secure.delete(key: ApiConfig.tokenKey);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fallbackKey);
  }
}
