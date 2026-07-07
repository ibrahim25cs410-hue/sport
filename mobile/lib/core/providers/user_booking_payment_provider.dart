import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../payment/user_booking_payment_orchestrator.dart';
import '../repositories/user_booking_payment_repository.dart';
import '../../services/api_client.dart';

final userBookingPaymentOrchestratorProvider = Provider.family<UserBookingPaymentOrchestrator, ApiClient>(
  (_, client) => UserBookingPaymentOrchestrator(repository: UserBookingPaymentRepository(client)),
);
