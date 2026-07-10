import '../models/field.dart';
import '../models/user.dart';
import '../utils/api_logger.dart';
import '../utils/paged_response.dart';
import '../core/paging/paged_list_state.dart';
import 'api_service.dart';
import 'token_storage.dart';

/// Handles JWT persistence and authentication API calls.
class AuthService {
  AuthService(this._client, this._tokenStorage);

  final ApiService _client;
  final TokenStorage _tokenStorage;

  /// Persists the JWT in [flutter_secure_storage] (with platform fallback).
  Future<void> saveToken(String token) async {
    try {
      await _tokenStorage.write(token);
    } catch (e, st) {
      apiLogError('saveToken failed', e, st);
      rethrow;
    }
  }

  /// Returns the stored JWT, or `null` when the user is not logged in.
  Future<String?> getToken() async {
    try {
      return await _tokenStorage.read();
    } catch (e, st) {
      apiLogError('getToken failed', e, st);
      return null;
    }
  }

  /// Removes the stored JWT.
  Future<void> logout() async {
    try {
      await _tokenStorage.delete();
    } catch (e, st) {
      apiLogError('logout failed', e, st);
      rethrow;
    }
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<({String token, User user, Field? field})> login(String email, String password) async {
    final res = await _client.dio.post('/login', data: {'email': email, 'password': password});
    final data = res.data as Map<String, dynamic>;
    final token = data['token'] as String;
    await saveToken(token);
    final field = _parseOptionalField(data);
    final user = _parseUser(data['user'], fallbackOwner: field != null);
    return (token: token, user: user, field: field);
  }

  Future<({String token, User user})> registerUser(Map<String, dynamic> body) async {
    final payload = Map<String, dynamic>.from(body)..remove('password');
    apiLog('POST /register-user', payload);
    try {
      final res = await _client.dio.post('/register-user', data: body);
      apiLog('register-user OK', res.statusCode);
      final data = res.data as Map<String, dynamic>;
      final token = data['token'] as String;
      await saveToken(token);
      return (token: token, user: _parseUser(data['user']));
    } catch (e, st) {
      apiLogError('register-user failed', e, st);
      rethrow;
    }
  }

  Future<({String token, User user, Field? field})> registerOwner(Map<String, dynamic> body) async {
    final res = await _client.dio.post('/register-owner', data: body);
    final data = res.data as Map<String, dynamic>;
    final token = data['token'] as String;
    await saveToken(token);
    final field = _parseOptionalField(data);
    final user = _parseUser(data['user'], fallbackOwner: true);
    return (token: token, user: user, field: field);
  }

  User _parseUser(dynamic raw, {bool fallbackOwner = false}) {
    final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    var user = User.fromJson(map);
    if (fallbackOwner && !user.isOwner && !user.isAdmin) {
      user = user.copyWith(role: 'owner');
    }
    return user;
  }

  Field? _parseOptionalField(Map<String, dynamic> data) {
    final fj = data['field'] ?? data['stadium'];
    if (fj is! Map<String, dynamic>) return null;
    try {
      return Field.fromJson(fj);
    } catch (e, st) {
      apiLogError('field parse skipped', e, st);
      return null;
    }
  }

  Future<List<Field>> getFields({int page = 1, int limit = defaultPageSize}) async {
    final res = await _client.dio.get('/fields', queryParameters: {'page': page, 'limit': limit});
    return unwrapPagedList(res.data, Field.fromJson);
  }

  Future<Field> getField(int fieldId) async {
    final res = await _client.dio.get('/fields/$fieldId');
    return Field.fromJson(res.data as Map<String, dynamic>);
  }

  Future<User> updateProfile({
    required String name,
    required String phone,
    String? image,
    String? password,
  }) async {
    final res = await _client.dio.put('/me', data: {
      'name': name,
      'phone': phone,
      if (image != null) 'image': image,
      if (password != null && password.isNotEmpty) 'password': password,
    });
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Field> updateField({
    required int fieldId,
    required String name,
    required String address,
    required String phone,
    required int pricePerHour,
    String? image,
  }) async {
    final res = await _client.dio.put('/fields/$fieldId', data: {
      'name': name,
      'address': address,
      'phone': phone,
      'pricePerHour': pricePerHour,
      if (image != null) 'image': image,
    });
    return Field.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Field> createField({
    required String name,
    required String address,
    required String phone,
    required int pricePerHour,
    String? image,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _client.dio.post('/fields', data: {
      'name': name,
      'address': address,
      'phone': phone,
      'pricePerHour': pricePerHour,
      if (image != null) 'image': image,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    return Field.fromJson(res.data as Map<String, dynamic>);
  }
}
