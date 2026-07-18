import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

abstract final class FirebaseAppService {
  static bool _initialized = false;
  static bool get isReady => _initialized;

  static Future<bool> initialize() async {
    if (_initialized) return true;
    if (!DefaultFirebaseOptions.isConfigured) {
      debugPrint('Firebase disabled: provide platform FIREBASE_* values with --dart-define.');
      return false;
    }
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _initialized = true;
      return true;
    } catch (e, st) {
      debugPrint('Firebase init skipped: $e\n$st');
      return false;
    }
  }
}
