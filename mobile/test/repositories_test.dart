import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riyada/core/providers/repository_providers.dart';
import 'package:riyada/core/repositories/auth_repository.dart';
import 'package:riyada/exceptions/booking_conflict_exception.dart';
import 'package:riyada/core/repositories/booking_repository.dart';
import 'package:riyada/models/field.dart';
import 'package:riyada/models/user.dart';
import 'package:riyada/providers/auth_provider.dart';
import 'package:riyada/services/api_client.dart';
import 'package:riyada/services/auth_service.dart';
import 'package:riyada/services/token_storage.dart';

const _testUser = User(
  id: 1,
  name: 'Test User',
  email: 'user@test.com',
  phone: '07700000000',
  province: 'نينوى',
  role: 'user',
);

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository(ApiClient client) : super(client, AuthService(client, TokenStorage()));

  bool loginCalled = false;

  @override
  Future<({String token, User user, Field? field})> login(String email, String password) async {
    loginCalled = true;
    return (token: 'fake-token', user: _testUser, field: null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BookingRepository', () {
    test('isConflict detects BookingConflictException', () {
      final repo = BookingRepository(ApiClient());
      expect(repo.isConflict(const BookingConflictException(messageKey: 'slotTaken')), isTrue);
      expect(repo.isConflict(Exception('other')), isFalse);
    });
  });

  group('AuthNotifier', () {
    late FakeAuthRepository fakeRepo;

    ProviderContainer createContainer() {
      final client = ApiClient();
      fakeRepo = FakeAuthRepository(client);
      return ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(client),
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    }

    test('login updates state with user', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final ok = await container.read(authProvider.notifier).login('user@test.com', '123456');
      expect(ok, isTrue);
      expect(fakeRepo.loginCalled, isTrue);
      expect(container.read(authProvider).user?.email, 'user@test.com');
      expect(container.read(authProvider).isLoggedIn, isTrue);
    });

    test('logout clears session state', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).login('user@test.com', '123456');
      await container.read(authProvider.notifier).logout();

      expect(container.read(authProvider).isLoggedIn, isFalse);
      expect(container.read(authProvider).user, isNull);
    });
  });
}
