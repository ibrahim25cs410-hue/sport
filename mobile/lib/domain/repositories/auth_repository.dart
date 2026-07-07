import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> currentUser();
  Future<UserEntity> signInWithEmail(String email, String password);
  Future<UserEntity> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String province,
  });
  Future<UserEntity> signInWithGoogle();
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Stream<UserEntity?> authStateChanges();
}
