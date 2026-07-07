import 'package:shared_preferences/shared_preferences.dart';

/// وضع المطوّر — يُفعّل بالضغط المتكرر على «عن التطبيق» في الإعدادات.
class DevMode {
  static const _key = 'developer_mode';
  static const tapTarget = 7;

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_key, true);
    } else {
      await prefs.remove(_key);
    }
  }
}
