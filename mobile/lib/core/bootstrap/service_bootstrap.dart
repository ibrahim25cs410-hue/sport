import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../di/service_providers.dart';

/// Eagerly wires API, booking, and Socket.io services at cold start.
abstract final class ServiceBootstrap {
  static void initialize(ProviderContainer container) {
    container.read(authInterceptorProvider);
    container.read(apiServiceProvider);
    container.read(authServiceProvider);
    container.read(bookingServiceProvider);
    container.read(stadiumServiceProvider);
    container.read(socketServiceProvider);
  }
}

/// Keeps core services alive for the widget tree (see [RiyadaApp]).
final servicesReadyProvider = Provider<bool>((ref) {
  ref.watch(authInterceptorProvider);
  ref.watch(apiServiceProvider);
  ref.watch(bookingServiceProvider);
  ref.watch(socketServiceProvider);
  return true;
});
