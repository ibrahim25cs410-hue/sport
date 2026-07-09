import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:riyada/models/notification.dart';
import 'package:riyada/models/stadium_booking.dart';
import 'package:riyada/services/api_service.dart';
import 'package:riyada/services/auth_interceptor.dart';
import 'package:riyada/services/auth_service.dart';
import 'package:riyada/services/booking_service.dart';
import 'package:riyada/services/stadium_service.dart';
import 'package:riyada/services/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simulates: Register → Login → Create Stadium → Book → Confirm booking.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio dio;
  late DioAdapter adapter;
  late TokenStorage tokenStorage;
  late ApiService apiService;
  late AuthService authService;
  late StadiumService stadiumService;
  late BookingService bookingService;

  const ownerToken = 'owner-jwt-token';
  const userToken = 'user-jwt-token';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tokenStorage = TokenStorage();
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api'));
    adapter = DioAdapter(dio: dio);
    apiService = ApiService(tokenStorage: tokenStorage, dio: dio);
    authService = AuthService(apiService, tokenStorage);
    stadiumService = StadiumService(apiService);
    bookingService = BookingService(apiService);

    adapter.onPost('/register-owner', (server) {
      server.reply(201, {
        'token': ownerToken,
        'user': {'id': 10, 'name': 'Owner', 'email': 'owner@test.com', 'role': 'owner', 'phone': '', 'province': 'نينوى'},
        'field': {'id': 1, 'name': 'Legacy Field', 'address': '', 'phone': '', 'pricePerHour': 0, 'ownerId': 10},
      });
    }, data: Matchers.any);

    adapter.onPost('/login', (server) {
      server.reply(200, {
        'token': userToken,
        'user': {'id': 20, 'name': 'User', 'email': 'user@test.com', 'role': 'user', 'phone': '', 'province': 'نينوى'},
      });
    }, data: Matchers.any);

    adapter.onPost('/stadiums', (server) {
      server.reply(201, {
        'id': 1,
        'name': 'Test Arena',
        'address': 'Main St',
        'phone': '',
        'pricePerHour': 50000,
        'ownerId': 10,
        'description': '',
      });
    }, data: Matchers.any);

    adapter.onPost('/bookings', (server) {
      server.reply(201, {
        'id': 100,
        'userId': 20,
        'stadiumId': 1,
        'startTime': '2026-08-01T14:00:00.000Z',
        'endTime': '2026-08-01T16:00:00.000Z',
        'status': 'pending',
        'stadium': {
          'id': 1,
          'name': 'Test Arena',
          'address': 'Main St',
          'phone': '',
          'pricePerHour': 50000,
          'ownerId': 10,
        },
      });
    }, data: Matchers.any);

    adapter.onPatch('/bookings/100/status', (server) {
      server.reply(200, {
        'id': 100,
        'userId': 20,
        'stadiumId': 1,
        'startTime': '2026-08-01T14:00:00.000Z',
        'endTime': '2026-08-01T16:00:00.000Z',
        'status': 'confirmed',
      });
    }, data: Matchers.any);
  });

  test('full service journey with mocked API', () async {
    final owner = await authService.registerOwner({
      'name': 'Owner',
      'email': 'owner@test.com',
      'password': 'secret123',
      'stadiumName': 'Legacy Field',
    });
    expect(owner.user.role, 'owner');
    expect(await tokenStorage.read(), ownerToken);

    await tokenStorage.write(userToken);
    final login = await authService.login('user@test.com', 'secret123');
    expect(login.user.role, 'user');

    await tokenStorage.write(ownerToken);
    final stadium = await stadiumService.createStadium(name: 'Test Arena', address: 'Main St');
    expect(stadium.id, 1);
    expect(stadium.ownerId, 10);

    await tokenStorage.write(userToken);
    final booking = await bookingService.createStadiumBooking(
      stadiumId: stadium.id,
      startTime: DateTime.parse('2026-08-01T14:00:00.000Z'),
      endTime: DateTime.parse('2026-08-01T16:00:00.000Z'),
    );
    expect(booking.status, 'pending');

    await tokenStorage.write(ownerToken);
    final confirmed = await bookingService.updateBookingStatus(
      bookingId: booking.id,
      status: 'confirmed',
    );
    expect(confirmed.status, 'confirmed');
  });

  test('AuthInterceptor marks public auth paths', () {
    expect(AuthInterceptor.isPublicAuthPath('/auth/login'), isTrue);
    expect(AuthInterceptor.isPublicAuthPath('/bookings/user/me'), isFalse);
  });

  test('401 is detected as strict unauthorized', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/bookings/user/me'),
      response: Response(requestOptions: RequestOptions(path: '/bookings/user/me'), statusCode: 401),
      type: DioExceptionType.badResponse,
    );
    expect(AuthInterceptor.isStrictUnauthorized(error), isTrue);
  });

  test('AppNotification parses socket payload', () {
    final notification = AppNotification.fromJson({
      'id': 1,
      'title': 'Booking confirmed',
      'message': 'Your booking was confirmed',
      'isRead': false,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
    expect(notification.title, 'Booking confirmed');
  });

  test('StadiumBooking model parses API payload', () {
    final booking = StadiumBooking.fromJson({
      'id': 100,
      'userId': 20,
      'stadiumId': 1,
      'startTime': '2026-08-01T14:00:00.000Z',
      'endTime': '2026-08-01T16:00:00.000Z',
      'status': 'pending',
    });
    expect(booking.stadiumId, 1);
    expect(booking.status, 'pending');
  });
}
