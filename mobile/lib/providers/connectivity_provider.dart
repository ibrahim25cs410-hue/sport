import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/api_client.dart';

/// يتحقق من صحة الاتصال بالـ API عبر /health.
class ConnectivityProvider extends ChangeNotifier {
  bool _online = true;
  Timer? _timer;
  int _failStreak = 0;

  bool get isOnline => _online;

  void start(ApiClient client) {
    _timer?.cancel();
    _failStreak = 0;
    _check(client);
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _check(client));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _failStreak = 0;
  }

  Future<void> recheck(ApiClient client) => _check(client);

  Future<void> _check(ApiClient client) async {
    try {
      await client.dio.get('/health');
      _failStreak = 0;
      if (!_online) {
        _online = true;
        notifyListeners();
      }
    } catch (_) {
      _failStreak++;
      if (_online && _failStreak >= 2) {
        _online = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
