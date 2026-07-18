import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:riyada/config/payment_policy.dart';
import 'package:riyada/router/app_router.dart';
import 'package:riyada/router/router_provider.dart';
import 'package:riyada/services/session_storage.dart';
import 'package:riyada/services/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemorySecureStore implements SecureTokenStore {
  String? value;

  @override
  Future<void> delete({required String key}) async => value = null;

  @override
  Future<String?> read({required String key}) async => value;

  @override
  Future<void> write({required String key, required String? value}) async {
    this.value = value;
  }
}

class _UnavailableSecureStore implements SecureTokenStore {
  @override
  Future<void> delete({required String key}) async {}

  @override
  Future<String?> read({required String key}) =>
      throw StateError('unavailable');

  @override
  Future<void> write({required String key, required String? value}) =>
      throw StateError('unavailable');
}

String _jwtExpiringAt(DateTime instant) {
  final header = base64Url
      .encode(utf8.encode('{"alg":"none"}'))
      .replaceAll('=', '');
  final seconds = instant.toUtc().millisecondsSinceEpoch ~/ 1000;
  final payload = base64Url
      .encode(utf8.encode('{"exp":$seconds}'))
      .replaceAll('=', '');
  return '$header.$payload.signature';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('production defaults to cash-only and guards every payment route', () {
    expect(PaymentPolicy.cashOnly, isTrue);
    expect(
      () => PaymentPolicy.requireElectronicPayments(),
      throwsA(isA<ElectronicPaymentsDisabledException>()),
    );
    for (final path in paymentRoutePaths) {
      expect(guardDisabledPaymentRoute(path), AppRoutes.userHome);
    }
  });

  test('JWT validation rejects malformed and expired values', () {
    final now = DateTime.utc(2030);
    expect(TokenStorage.isUsableJwt('not-a-jwt', now: now), isFalse);
    expect(
      TokenStorage.isUsableJwt(
        _jwtExpiringAt(now.subtract(const Duration(minutes: 1))),
        now: now,
      ),
      isFalse,
    );
    expect(
      TokenStorage.isUsableJwt(
        _jwtExpiringAt(now.add(const Duration(hours: 1))),
        now: now,
      ),
      isTrue,
    );
  });

  test('legacy plaintext token migrates once then is deleted', () async {
    final token = _jwtExpiringAt(DateTime.now().add(const Duration(hours: 1)));
    SharedPreferences.setMockInitialValues({'riyada_jwt_fallback': token});
    final secure = _MemorySecureStore();
    final storage = TokenStorage(store: secure);

    expect(await storage.read(), token);
    expect(secure.value, token);
    expect(
      (await SharedPreferences.getInstance()).containsKey(
        'riyada_jwt_fallback',
      ),
      isFalse,
    );
  });

  test(
    'stale plaintext token is deleted when secure storage is unavailable',
    () async {
      SharedPreferences.setMockInitialValues({
        'riyada_jwt_fallback': _jwtExpiringAt(
          DateTime.now().add(const Duration(hours: 1)),
        ),
      });
      final storage = TokenStorage(store: _UnavailableSecureStore());

      await expectLater(storage.read(), throwsStateError);
      expect(
        (await SharedPreferences.getInstance()).containsKey(
          'riyada_jwt_fallback',
        ),
        isFalse,
      );
    },
  );

  test('corrupt cached session is cleared without throwing', () async {
    SharedPreferences.setMockInitialValues({
      'session_user': '{broken',
      'session_saved_at': DateTime.now().millisecondsSinceEpoch,
    });

    final session = await SessionStorage.load();
    expect(session.user, isNull);
    expect(
      (await SharedPreferences.getInstance()).containsKey('session_user'),
      isFalse,
    );
  });

  test('stale cached session expires safely', () async {
    SharedPreferences.setMockInitialValues({
      'session_user':
          '{"id":1,"name":"Test","email":"t@example.com","role":"user"}',
      'session_saved_at': DateTime.utc(2020).millisecondsSinceEpoch,
    });

    final session = await SessionStorage.load(now: DateTime.utc(2021));
    expect(session.user, isNull);
  });
}
