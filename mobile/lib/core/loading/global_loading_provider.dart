import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks in-flight API operations for the global loading overlay.
class GlobalLoadingState {
  const GlobalLoadingState({this.activeCount = 0, this.message});

  final int activeCount;
  final String? message;

  bool get isVisible => activeCount > 0;

  GlobalLoadingState copyWith({int? activeCount, String? message, bool clearMessage = false}) =>
      GlobalLoadingState(
        activeCount: activeCount ?? this.activeCount,
        message: clearMessage ? null : (message ?? this.message),
      );
}

final globalLoadingProvider =
    NotifierProvider<GlobalLoadingNotifier, GlobalLoadingState>(GlobalLoadingNotifier.new);

class GlobalLoadingNotifier extends Notifier<GlobalLoadingState> {
  static const int _maxNested = 64;
  static const Duration _showDelay = Duration(milliseconds: 280);

  Timer? _showTimer;
  int _pendingShows = 0;

  @override
  GlobalLoadingState build() => const GlobalLoadingState();

  /// Clears a stale overlay after hot-restart or interrupted requests.
  void reset() {
    _showTimer?.cancel();
    _showTimer = null;
    _pendingShows = 0;
    state = const GlobalLoadingState();
  }

  void show({String? message}) {
    if (state.activeCount > 0) {
      final next = state.activeCount + 1;
      state = state.copyWith(
        activeCount: next > _maxNested ? _maxNested : next,
        message: message ?? state.message,
      );
      return;
    }

    _pendingShows++;
    _showTimer ??= Timer(_showDelay, () {
      if (_pendingShows <= 0) return;
      final count = _pendingShows > _maxNested ? _maxNested : _pendingShows;
      _pendingShows = 0;
      _showTimer = null;
      state = state.copyWith(activeCount: count, message: message ?? state.message);
    });
  }

  void hide() {
    if (state.activeCount <= 0) {
      if (_pendingShows > 0) {
        _pendingShows--;
        if (_pendingShows <= 0) {
          _showTimer?.cancel();
          _showTimer = null;
        }
      } else {
        state = const GlobalLoadingState();
      }
      return;
    }

    final next = state.activeCount - 1;
    state = next == 0
        ? const GlobalLoadingState()
        : state.copyWith(activeCount: next, clearMessage: true);
  }

  /// Runs [action] while the overlay is visible — safe for nested calls.
  Future<T> run<T>(Future<T> Function() action, {String? message}) async {
    show(message: message);
    try {
      return await action();
    } finally {
      hide();
    }
  }
}
