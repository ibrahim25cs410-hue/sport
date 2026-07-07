import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Latest FCM message and a generation counter for [ref.listen].
class PushNotificationState {
  const PushNotificationState({
    this.lastMessage,
    this.generation = 0,
  });

  final RemoteMessage? lastMessage;
  final int generation;

  PushNotificationState copyWith({
    RemoteMessage? lastMessage,
    int? generation,
  }) =>
      PushNotificationState(
        lastMessage: lastMessage ?? this.lastMessage,
        generation: generation ?? this.generation,
      );
}

final pushNotificationProvider =
    NotifierProvider<PushNotificationNotifier, PushNotificationState>(PushNotificationNotifier.new);

class PushNotificationNotifier extends Notifier<PushNotificationState> {
  @override
  PushNotificationState build() => const PushNotificationState();

  void handleMessage(RemoteMessage message) {
    state = state.copyWith(
      lastMessage: message,
      generation: state.generation + 1,
    );
  }
}
