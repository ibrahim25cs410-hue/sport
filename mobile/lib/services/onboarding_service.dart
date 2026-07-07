import 'package:shared_preferences/shared_preferences.dart';

/// يتتبع إكمال شاشة التعريف بالتطبيق (مرة واحدة).
class OnboardingService {
  static const _key = 'onboarding_complete_v1';

  Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
