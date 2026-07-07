import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import '../models/realtime_booking_event.dart';
import '../models/slot_hold.dart';
import '../utils/api_logger.dart';

/// طبقة الخدمة — اتصال SignalR مع إعادة اتصال تلقائية.
class SignalRService {
  SignalRService({
    required this.hubUrl,
    required this.getToken,
  });

  final String hubUrl;
  final Future<String?> Function() getToken;

  HubConnection? _connection;
  void Function(BookingUpdatedEvent event)? onBookingUpdated;
  void Function(SlotSelectionEvent event)? onSlotSelection;
  void Function(SlotReleaseEvent event)? onSlotRelease;
  void Function(SignalRConnectionStatus status)? onConnectionStatus;

  HubConnection? get connection => _connection;

  Future<void> start() async {
    await stop();
    onConnectionStatus?.call(SignalRConnectionStatus.connecting);

    final connection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async {
              final token = await getToken();
              return token ?? '';
            },
            transport: HttpTransportType.WebSockets,
            skipNegotiation: true,
          ),
        )
        .withAutomaticReconnect(retryDelays: [0, 500, 1000, 2000, 5000, 10000])
        .build();

    connection.on('BookingUpdated', _handleBookingUpdated);
    connection.on('NotifySlotSelection', _handleSlotSelection);
    connection.on('ReleaseSlot', _handleSlotRelease);
    connection.onreconnecting(({Exception? error}) {
      apiLog('SignalR reconnecting', error?.toString() ?? '');
      onConnectionStatus?.call(SignalRConnectionStatus.reconnecting);
    });
    connection.onreconnected(({String? connectionId}) {
      apiLog('SignalR reconnected', connectionId ?? '');
      onConnectionStatus?.call(SignalRConnectionStatus.connected);
    });
    connection.onclose(({Exception? error}) {
      apiLog('SignalR closed', error?.toString() ?? '');
      onConnectionStatus?.call(SignalRConnectionStatus.disconnected);
    });

    _connection = connection;
    await connection.start();
    onConnectionStatus?.call(SignalRConnectionStatus.connected);
    apiLog('SignalR connected', hubUrl);
  }

  Future<void> joinField(int fieldId) async {
    await _connection?.invoke('JoinField', args: [fieldId]);
    apiLog('SignalR JoinField', '$fieldId');
  }

  Future<void> leaveField(int fieldId) async {
    await _connection?.invoke('LeaveField', args: [fieldId]);
    apiLog('SignalR LeaveField', '$fieldId');
  }

  void _handleBookingUpdated(List<Object?>? args) {
    final map = _firstMap(args);
    if (map == null) return;
    final event = BookingUpdatedEvent.fromJson(map);
    apiLog('SignalR BookingUpdated', '${event.bookingId} ${event.status}');
    onBookingUpdated?.call(event);
  }

  void _handleSlotSelection(List<Object?>? args) {
    final map = _firstMap(args);
    if (map == null) return;
    final event = SlotSelectionEvent.fromJson(map);
    apiLog('SignalR NotifySlotSelection', '${event.fieldId} ${event.startTime}');
    onSlotSelection?.call(event);
  }

  void _handleSlotRelease(List<Object?>? args) {
    final map = _firstMap(args);
    if (map == null) return;
    final event = SlotReleaseEvent.fromJson(map);
    apiLog('SignalR ReleaseSlot', '${event.fieldId} ${event.startTime}');
    onSlotRelease?.call(event);
  }

  Map<String, dynamic>? _firstMap(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final raw = args.first;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<void> stop() async {
    final c = _connection;
    _connection = null;
    if (c != null) {
      try {
        await c.stop();
      } catch (_) {}
    }
    onConnectionStatus?.call(SignalRConnectionStatus.disconnected);
  }

  Future<void> dispose() => stop();
}
