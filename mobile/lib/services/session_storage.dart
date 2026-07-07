import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/field.dart';
import '../models/user.dart';

class SessionStorage {
  static const _userKey = 'session_user';
  static const _fieldKey = 'session_field';

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
  }

  static Future<({User? user, Field? field})> load() async {
    final prefs = await SharedPreferences.getInstance();
    final u = prefs.getString(_userKey);
    if (u == null) return (user: null, field: null);
    final user = User.fromJson(jsonDecode(u) as Map<String, dynamic>);
    final f = prefs.getString(_fieldKey);
    final field = f != null ? Field.fromJson(jsonDecode(f) as Map<String, dynamic>) : null;
    return (user: user, field: field);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_fieldKey);
  }
}
