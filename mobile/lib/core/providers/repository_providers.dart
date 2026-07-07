import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_providers.dart';
import '../../services/api_client.dart';
import '../repositories/auth_repository.dart';
import '../repositories/booking_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/review_repository.dart';
import '../repositories/slot_repository.dart';

/// مزوّدات المستودعات — تُنشأ من [ApiClient] المرتبط بالجلسة.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(authServiceProvider),
  ),
);

final bookingRepositoryProvider = Provider.family<BookingRepository, ApiClient>(
  (_, client) => BookingRepository(client),
);

final slotRepositoryProvider = Provider.family<SlotRepository, ApiClient>(
  (_, client) => SlotRepository(client),
);

final notificationRepositoryProvider = Provider.family<NotificationRepository, ApiClient>(
  (_, client) => NotificationRepository(client),
);

final reviewRepositoryProvider = Provider.family<ReviewRepository, ApiClient>(
  (_, client) => ReviewRepository(client),
);
