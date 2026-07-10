import '../../models/field.dart';
import '../../models/user.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../paging/paged_list_state.dart';

/// مستودع المصادقة والملف الشخصي — الوحيد المسموح له بالوصول لـ Auth API.
class AuthRepository {
  AuthRepository(this._client, this._remote);

  final ApiClient _client;
  final AuthService _remote;

  ApiClient get client => _client;
  AuthService get authService => _remote;

  Future<({String token, User user, Field? field})> login(String email, String password) =>
      _remote.login(email, password);

  Future<({String token, User user})> registerUser(Map<String, dynamic> body) =>
      _remote.registerUser(body);

  Future<({String token, User user, Field? field})> registerOwner(Map<String, dynamic> body) =>
      _remote.registerOwner(body);

  Future<void> logout() => _remote.logout();

  Future<List<Field>> getFields({int page = 1, int limit = defaultPageSize}) =>
      _remote.getFields(page: page, limit: limit);

  Future<({User user, Field? field})> bootstrapFromToken() async {
    final res = await _client.dio.get('/me');
    final data = res.data as Map<String, dynamic>;
    final fj = data['field'] ?? data['stadium'];
    Field? field;
    if (fj is Map<String, dynamic>) {
      try {
        field = Field.fromJson(fj);
      } catch (_) {
        field = null;
      }
    }
    var user = User.fromJson(
      data['user'] is Map<String, dynamic> ? data['user'] as Map<String, dynamic> : <String, dynamic>{},
    );
    if (field != null && !user.isOwner && !user.isAdmin) {
      user = user.copyWith(role: 'owner');
    }
    return (user: user, field: field);
  }

  Future<User> updateProfile({
    required String name,
    required String phone,
    String? image,
    String? password,
  }) =>
      _remote.updateProfile(name: name, phone: phone, image: image, password: password);

  Future<Field> updateField({
    required int fieldId,
    required String name,
    required String address,
    required String phone,
    required int pricePerHour,
    String? image,
  }) =>
      _remote.updateField(
        fieldId: fieldId,
        name: name,
        address: address,
        phone: phone,
        pricePerHour: pricePerHour,
        image: image,
      );

  Future<Field> createField({
    required String name,
    required String address,
    required String phone,
    required int pricePerHour,
    String? image,
    double? latitude,
    double? longitude,
  }) =>
      _remote.createField(
        name: name,
        address: address,
        phone: phone,
        pricePerHour: pricePerHour,
        image: image,
        latitude: latitude,
        longitude: longitude,
      );
}
