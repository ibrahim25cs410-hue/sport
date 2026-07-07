import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/session_key.dart';
import '../providers/repository_providers.dart';

/// اختيار وإطلاق قفل الوقت — عبر المستودع فقط.
final slotActionsProvider = Provider.family<SlotActions, UserSessionKey>(
  (ref, session) => SlotActions(ref, session),
);

class SlotActions {
  SlotActions(this._ref, this._session);

  final Ref _ref;
  final UserSessionKey _session;

  Future<DateTime?> select({
    required int fieldId,
    required DateTime startTime,
    required int hours,
  }) =>
      _ref.read(slotRepositoryProvider(_session.client)).selectSlot(
            fieldId: fieldId,
            startTime: startTime,
            hours: hours,
          );

  Future<void> release({
    required int fieldId,
    required DateTime startTime,
    required int hours,
  }) =>
      _ref.read(slotRepositoryProvider(_session.client)).releaseSlot(
            fieldId: fieldId,
            startTime: startTime,
            hours: hours,
          );
}
