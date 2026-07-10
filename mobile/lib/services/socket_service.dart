import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/api_config.dart';
import '../models/notification.dart';
import '../models/realtime_booking_event.dart';
import '../models/slot_hold.dart';
import '../utils/api_logger.dart';
import 'token_storage.dart';

typedef NotificationHandler = void Function(AppNotification notification);

/// Socket.io client — notifications, booking updates, and slot sync.
class SocketService {
  SocketService({TokenStorage? tokenStorage}) : _tokens = tokenStorage ?? TokenStorage();

  final TokenStorage _tokens;
  io.Socket? _socket;
  int? _joinedFieldId;
  int? _joinedStadiumId;

  final _notificationController = StreamController<AppNotification>.broadcast();
  final _bookingUpdatedController = StreamController<BookingUpdatedEvent>.broadcast();
  final _slotSelectionController = StreamController<SlotSelectionEvent>.broadcast();
  final _slotReleaseController = StreamController<SlotReleaseEvent>.broadcast();
  final _statusController = StreamController<RealtimeConnectionStatus>.broadcast();

  RealtimeConnectionStatus _status = RealtimeConnectionStatus.disconnected;

  bool get isConnected => _socket?.connected ?? false;
  RealtimeConnectionStatus get status => _status;

  Stream<AppNotification> get notificationStream => _notificationController.stream;
  Stream<BookingUpdatedEvent> get bookingUpdatedStream => _bookingUpdatedController.stream;
  Stream<SlotSelectionEvent> get slotSelectionStream => _slotSelectionController.stream;
  Stream<SlotReleaseEvent> get slotReleaseStream => _slotReleaseController.stream;
  Stream<RealtimeConnectionStatus> get connectionStatusStream => _statusController.stream;

  void _setStatus(RealtimeConnectionStatus next) {
    _status = next;
    if (!_statusController.isClosed) _statusController.add(next);
  }

  Future<void> connect() async {
    final token = await _tokens.read();
    if (token == null || token.isEmpty) {
      apiLog('SocketService.connect skipped — no token');
      return;
    }

    if (_socket?.connected == true) return;

    await disconnect();
    _setStatus(RealtimeConnectionStatus.connecting);

    final socket = io.io(
      ApiConfig.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .build(),
    );

    socket.onConnect((_) {
      apiLog('Socket connected', socket.id);
      _setStatus(RealtimeConnectionStatus.connected);
      _rejoinRooms();
    });
    socket.onDisconnect((_) {
      apiLog('Socket disconnected');
      _setStatus(RealtimeConnectionStatus.disconnected);
    });
    socket.onConnectError((error) {
      apiLogError('Socket connect error', error);
      _setStatus(RealtimeConnectionStatus.disconnected);
    });
    socket.onReconnect((_) {
      _setStatus(RealtimeConnectionStatus.connected);
      _rejoinRooms();
    });
    socket.onReconnectAttempt((_) => _setStatus(RealtimeConnectionStatus.reconnecting));
    socket.onReconnectError((_) => _setStatus(RealtimeConnectionStatus.reconnecting));

    socket.on('connected', (data) => apiLog('Socket handshake', data));
    socket.on('notification', _onNotification);
    socket.on('bookingUpdated', _onBookingUpdated);
    socket.on('slotSelection', _onSlotSelection);
    socket.on('slotRelease', _onSlotRelease);

    _socket = socket;
    socket.connect();
  }

  void joinField(int fieldId) {
    _joinedFieldId = fieldId;
    _socket?.emit('joinField', fieldId);
    apiLog('Socket joinField', '$fieldId');
  }

  void leaveField(int fieldId) {
    if (_joinedFieldId == fieldId) _joinedFieldId = null;
    _socket?.emit('leaveField', fieldId);
    apiLog('Socket leaveField', '$fieldId');
  }

  void joinStadium(int stadiumId) {
    _joinedStadiumId = stadiumId;
    _socket?.emit('joinStadium', stadiumId);
    apiLog('Socket joinStadium', '$stadiumId');
  }

  void leaveStadium(int stadiumId) {
    if (_joinedStadiumId == stadiumId) _joinedStadiumId = null;
    _socket?.emit('leaveStadium', stadiumId);
    apiLog('Socket leaveStadium', '$stadiumId');
  }

  void _rejoinRooms() {
    if (_joinedFieldId != null) {
      _socket?.emit('joinField', _joinedFieldId);
      apiLog('Socket rejoinField', '$_joinedFieldId');
    }
    if (_joinedStadiumId != null) {
      _socket?.emit('joinStadium', _joinedStadiumId);
      apiLog('Socket rejoinStadium', '$_joinedStadiumId');
    }
  }

  void _onNotification(dynamic payload) => _parseMap(payload, (map) {
        _notificationController.add(AppNotification.fromJson(map));
      });

  void _onBookingUpdated(dynamic payload) => _parseMap(payload, (map) {
        final event = BookingUpdatedEvent.fromJson(map);
        apiLog('Socket bookingUpdated', '${event.bookingId} ${event.status}');
        _bookingUpdatedController.add(event);
      });

  void _onSlotSelection(dynamic payload) => _parseMap(payload, (map) {
        _slotSelectionController.add(SlotSelectionEvent.fromJson(map));
      });

  void _onSlotRelease(dynamic payload) => _parseMap(payload, (map) {
        _slotReleaseController.add(SlotReleaseEvent.fromJson(map));
      });

  void _parseMap(dynamic payload, void Function(Map<String, dynamic> map) onMap) {
    if (payload is! Map) return;
    try {
      onMap(Map<String, dynamic>.from(payload));
    } catch (e, st) {
      apiLogError('Socket payload parse failed', e, st);
    }
  }

  Future<void> disconnect() async {
    _socket?.off('notification');
    _socket?.off('bookingUpdated');
    _socket?.off('slotSelection');
    _socket?.off('slotRelease');
    _socket?.dispose();
    _socket = null;
    _joinedFieldId = null;
    _joinedStadiumId = null;
    _setStatus(RealtimeConnectionStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _notificationController.close();
    _bookingUpdatedController.close();
    _slotSelectionController.close();
    _slotReleaseController.close();
    _statusController.close();
  }
}
