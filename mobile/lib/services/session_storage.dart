import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/field.dart';
import '../models/user.dart';

class SessionStorage {
  static const _userKey = 'session_user';
  static const _fieldKey = 'session_field';
  static const _savedAtKey = 'session_saved_at';
  static const maxCacheAge = Duration(days: 30);

  static Future<void> save(User user, Field? field) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'province': user.province,
      'image': user.image,
      'role': user.role,
    }));
    if (field != null) {
      await prefs.setString(_fieldKey, jsonEncode({
        'id': field.id,
        'name': field.name,
        'address': field.address,
        'phone': field.phone,
        'image': field.image,
        'pricePerHour': field.pricePerHour,
        'ownerId': field.ownerId,
      }));
    } else {
      await prefs.remove(_fieldKey);
    }
    await prefs.setInt(_savedAtKey, DateTime.now().toUtc().millisecondsSinceEpoch);
  }

  static Future<({User? user, Field? field})> load({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final u = prefs.getString(_userKey);
      final savedAtMs = prefs.getInt(_savedAtKey);
      if (u == null || savedAtMs == null) {
        await clear();
        return (user: null, field: null);
      }
      final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtMs, isUtc: true);
      if ((now ?? DateTime.now()).toUtc().difference(savedAt) > maxCacheAge) {
        await clear();
        return (user: null, field: null);
      }
      final decodedUser = jsonDecode(u);
      if (decodedUser is! Map<String, dynamic>) throw const FormatException('Invalid cached user');
      final user = User.fromJson(decodedUser);
      final f = prefs.getString(_fieldKey);
      Field? field;
      if (f != null) {
        final decodedField = jsonDecode(f);
        if (decodedField is! Map<String, dynamic>) throw const FormatException('Invalid cached field');
        field = Field.fromJson(decodedField);
      }
      return (user: user, field: field);
    } catch (_) {
      await clear();
      return (user: null, field: null);
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_fieldKey);
    await prefs.remove(_savedAtKey);
  }
}
