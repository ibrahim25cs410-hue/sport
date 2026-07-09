import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/service_providers.dart';
import '../models/realtime_booking_event.dart';
import '../models/slot_hold.dart';
import '../services/socket_service.dart';

class SocketConnectionState {
  const SocketConnectionState({
    this.status = RealtimeConnectionStatus.disconnected,
    this.lastEvent,
    this.generation = 0,
    this.lastSlotSelection,
    this.lastSlotRelease,
    this.slotGeneration = 0,
  });

  final RealtimeConnectionStatus status;
  final BookingUpdatedEvent? lastEvent;
  final int generation;
  final SlotSelectionEvent? lastSlotSelection;
  final SlotReleaseEvent? lastSlotRelease;
  final int slotGeneration;

  SocketConnectionState copyWith({
    RealtimeConnectionStatus? status,
    BookingUpdatedEvent? lastEvent,
    int? generation,
    SlotSelectionEvent? lastSlotSelection,
    SlotReleaseEvent? lastSlotRelease,
    int? slotGeneration,
  }) =>
      SocketConnectionState(
        status: status ?? this.status,
        lastEvent: lastEvent ?? this.lastEvent,
        generation: generation ?? this.generation,
        lastSlotSelection: lastSlotSelection ?? this.lastSlotSelection,
        lastSlotRelease: lastSlotRelease ?? this.lastSlotRelease,
        slotGeneration: slotGeneration ?? this.slotGeneration,
      );
}

/// Real-time Socket.io connection state for bookings and slot holds.
final socketProvider = NotifierProvider<SocketNotifier, SocketConnectionState>(SocketNotifier.new);

class SocketNotifier extends Notifier<SocketConnectionState> {
  SocketService get _service => ref.read(socketServiceProvider);

  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  SocketConnectionState build() {
    ref.onDispose(_teardown);
    return const SocketConnectionState();
  }

  void _teardown() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }

  Future<void> ensureConnected() async {
    if (_service.isConnected) {
      state = state.copyWith(status: RealtimeConnectionStatus.connected);
      return;
    }
    await connect();
  }

  Future<void> connect() async {
    if (_service.isConnected) return;
    _wireSubscriptions();
    try {
      await _service.connect();
    } catch (_) {
      state = state.copyWith(status: RealtimeConnectionStatus.disconnected);
      rethrow;
    }
  }

  void _wireSubscriptions() {
    if (_subs.isNotEmpty) return;
    _subs.add(_service.connectionStatusStream.listen((status) {
      state = state.copyWith(status: status);
    }));
    _subs.add(_service.bookingUpdatedStream.listen((event) {
      state = state.copyWith(
        lastEvent: event,
        generation: state.generation + 1,
      );
    }));
    _subs.add(_service.slotSelectionStream.listen((event) {
      state = state.copyWith(
        lastSlotSelection: event,
        slotGeneration: state.slotGeneration + 1,
      );
    }));
    _subs.add(_service.slotReleaseStream.listen((event) {
      state = state.copyWith(
        lastSlotRelease: event,
        slotGeneration: state.slotGeneration + 1,
      );
    }));
  }

  void joinField(int fieldId) => _service.joinField(fieldId);

  void leaveField(int fieldId) => _service.leaveField(fieldId);

  void joinStadium(int stadiumId) => _service.joinStadium(stadiumId);

  void leaveStadium(int stadiumId) => _service.leaveStadium(stadiumId);

  Future<void> disconnect() async {
    _teardown();
    await _service.disconnect();
    state = const SocketConnectionState();
  }
}
