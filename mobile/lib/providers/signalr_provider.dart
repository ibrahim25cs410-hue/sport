import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/realtime_booking_event.dart';
import '../models/slot_hold.dart';
import '../services/signalr_service.dart';

class SignalRConnectionState {
  const SignalRConnectionState({
    this.status = SignalRConnectionStatus.disconnected,
    this.lastEvent,
    this.generation = 0,
    this.lastSlotSelection,
    this.lastSlotRelease,
    this.slotGeneration = 0,
  });

  final SignalRConnectionStatus status;
  final BookingUpdatedEvent? lastEvent;
  final int generation;
  final SlotSelectionEvent? lastSlotSelection;
  final SlotReleaseEvent? lastSlotRelease;
  final int slotGeneration;

  SignalRConnectionState copyWith({
    SignalRConnectionStatus? status,
    BookingUpdatedEvent? lastEvent,
    int? generation,
    SlotSelectionEvent? lastSlotSelection,
    SlotReleaseEvent? lastSlotRelease,
    int? slotGeneration,
  }) =>
      SignalRConnectionState(
        status: status ?? this.status,
        lastEvent: lastEvent ?? this.lastEvent,
        generation: generation ?? this.generation,
        lastSlotSelection: lastSlotSelection ?? this.lastSlotSelection,
        lastSlotRelease: lastSlotRelease ?? this.lastSlotRelease,
        slotGeneration: slotGeneration ?? this.slotGeneration,
      );
}

/// يراقب اتصال SignalR وأحداث الحجز واختيار الأوقات.
final signalRProvider = NotifierProvider<SignalRNotifier, SignalRConnectionState>(SignalRNotifier.new);

class SignalRNotifier extends Notifier<SignalRConnectionState> {
  SignalRService? _service;

  @override
  SignalRConnectionState build() {
    ref.onDispose(() {
      _service?.dispose();
      _service = null;
    });
    return const SignalRConnectionState();
  }

  Future<void> ensureConnected({
    required String hubUrl,
    required Future<String?> Function() getToken,
  }) async {
    if (_service != null && state.status == SignalRConnectionStatus.connected) return;
    await connect(hubUrl: hubUrl, getToken: getToken);
  }

  Future<void> connect({
    required String hubUrl,
    required Future<String?> Function() getToken,
  }) async {
    if (_service != null && state.status == SignalRConnectionStatus.connected) return;

    if (_service == null) {
      final service = SignalRService(hubUrl: hubUrl, getToken: getToken);
      service.onConnectionStatus = (status) {
        state = state.copyWith(status: status);
      };
      service.onBookingUpdated = (event) {
        state = state.copyWith(
          lastEvent: event,
          generation: state.generation + 1,
        );
      };
      service.onSlotSelection = (event) {
        state = state.copyWith(
          lastSlotSelection: event,
          slotGeneration: state.slotGeneration + 1,
        );
      };
      service.onSlotRelease = (event) {
        state = state.copyWith(
          lastSlotRelease: event,
          slotGeneration: state.slotGeneration + 1,
        );
      };
      _service = service;
      try {
        await service.start();
      } catch (_) {
        state = state.copyWith(status: SignalRConnectionStatus.disconnected);
        rethrow;
      }
    }
  }

  Future<void> joinField(int fieldId) async {
    await _service?.joinField(fieldId);
  }

  Future<void> leaveField(int fieldId) async {
    await _service?.leaveField(fieldId);
  }

  Future<void> disconnect() async {
    await _service?.dispose();
    _service = null;
    state = const SignalRConnectionState();
  }
}
