import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/firebase_app.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firebase_field_repository.dart';
import '../../domain/entities/field_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/field_repository.dart';

final firebaseAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!FirebaseAppService.isReady) return FirebaseAuthRepositoryDisabled();
  return FirebaseAuthRepository();
});

final firebaseFieldRepositoryProvider = Provider<FieldRepository>((ref) {
  if (!FirebaseAppService.isReady) return _DisabledFieldRepository();
  return FirebaseFieldRepository();
});

class _DisabledFieldRepository implements FieldRepository {
  @override
  Future<FieldEntity?> getField(String id) async => null;

  @override
  Future<List<FieldEntity>> getPopularFields({int limit = 10}) async => [];

  @override
  Stream<List<FieldEntity>> watchFields({FieldFilter? filter}) => Stream.value([]);
}
