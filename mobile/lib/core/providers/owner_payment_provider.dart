import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/owner_payment_account.dart';
import '../payment/owner_payment_orchestrator.dart';
import '../repositories/owner_payment_repository.dart';
import '../../providers/session_key.dart';
import '../../services/api_client.dart';

final ownerPaymentRepositoryProvider = Provider.family<OwnerPaymentRepository, ApiClient>(
  (_, client) => OwnerPaymentRepository(client),
);

final ownerPaymentOrchestratorProvider = Provider.family<OwnerPaymentOrchestrator, ApiClient>(
  (_, client) => OwnerPaymentOrchestrator(repository: OwnerPaymentRepository(client)),
);

/// حدث نجاح الدفع الأخير — يُصفَّر بعد عرض رسالة النجاح.
final ownerPaymentVerifiedEventProvider = StateProvider<OwnerPaymentVerifiedEvent?>((ref) => null);

final ownerPaymentAccountProvider =
    AsyncNotifierProvider.family<OwnerPaymentAccountNotifier, OwnerPaymentAccount, UserSessionKey>(
  OwnerPaymentAccountNotifier.new,
);

class OwnerPaymentAccountNotifier extends FamilyAsyncNotifier<OwnerPaymentAccount, UserSessionKey> {
  @override
  Future<OwnerPaymentAccount> build(UserSessionKey arg) async {
    return ref.read(ownerPaymentOrchestratorProvider(arg.client)).loadAccount(arg.userId);
  }

  Future<void> refreshPreservingData() async {
    final previous = state.valueOrNull;
    try {
      final data = await ref.read(ownerPaymentOrchestratorProvider(arg.client)).loadAccount(arg.userId);
      state = AsyncData(data);
    } catch (e, st) {
      if (previous != null) {
        state = AsyncData(previous);
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  void applyVerified(OwnerPaymentVerifiedEvent event) {
    ref.read(ownerPaymentVerifiedEventProvider.notifier).state = event;
  }
}
