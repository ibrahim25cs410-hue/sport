import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/review.dart';
import 'repository_providers.dart';
import '../../providers/session_key.dart';

final fieldReviewEligibilityProvider =
    AsyncNotifierProvider.family<FieldReviewEligibilityNotifier, FieldReviewEligibility, FieldReviewKey>(
  FieldReviewEligibilityNotifier.new,
);

class FieldReviewKey {
  const FieldReviewKey({required this.session, required this.fieldId});
  final UserSessionKey session;
  final int fieldId;

  @override
  bool operator ==(Object other) =>
      other is FieldReviewKey && other.session == session && other.fieldId == fieldId;

  @override
  int get hashCode => Object.hash(session, fieldId);
}

class FieldReviewEligibilityNotifier extends FamilyAsyncNotifier<FieldReviewEligibility, FieldReviewKey> {
  @override
  Future<FieldReviewEligibility> build(FieldReviewKey arg) async {
    return ref.read(reviewRepositoryProvider(arg.session.client)).getEligibility(arg.fieldId);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(arg));
  }
}
