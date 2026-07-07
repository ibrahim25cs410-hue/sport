import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/firebase/firestore_paths.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/firestore_mappers.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _google = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _google;

  @override
  Stream<UserEntity?> authStateChanges() => _auth.authStateChanges().asyncMap((u) async {
        if (u == null) return null;
        return _fetchProfile(u.uid);
      });

  @override
  Future<UserEntity?> currentUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    return _fetchProfile(u.uid);
  }

  Future<UserEntity?> _fetchProfile(String uid) async {
    final doc = await _db.collection(FirestorePaths.users).doc(uid).get();
    if (!doc.exists) {
      final fb = _auth.currentUser;
      if (fb == null) return null;
      final entity = UserEntity(
        id: uid,
        name: fb.displayName ?? '',
        email: fb.email ?? '',
        phone: fb.phoneNumber ?? '',
        province: 'نينوى',
        imageUrl: fb.photoURL,
        role: UserRole.customer,
      );
      await _db.collection(FirestorePaths.users).doc(uid).set(FirestoreMappers.userToMap(entity));
      return entity;
    }
    return FirestoreMappers.userFromDoc(doc);
  }

  @override
  Future<UserEntity> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final profile = await _fetchProfile(cred.user!.uid);
    return profile!;
  }

  @override
  Future<UserEntity> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String province,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = cred.user!.uid;
    final entity = UserEntity(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      province: province,
      role: UserRole.customer,
      referralCode: uid.substring(0, 8).toUpperCase(),
    );
    await _db.collection(FirestorePaths.users).doc(uid).set(FirestoreMappers.userToMap(entity));
    return entity;
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) throw StateError('Google sign-in cancelled');
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    final profile = await _fetchProfile(cred.user!.uid);
    return profile!;
  }

  @override
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _google.signOut()]);
  }

  @override
  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);
}

class FirebaseAuthRepositoryDisabled implements AuthRepository {
  @override
  Future<UserEntity?> currentUser() async => null;

  @override
  Stream<UserEntity?> authStateChanges() => const Stream.empty();

  @override
  Future<UserEntity> signInWithEmail(String email, String password) {
    throw UnsupportedError('Firebase not configured');
  }

  @override
  Future<UserEntity> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String province,
  }) {
    throw UnsupportedError('Firebase not configured');
  }

  @override
  Future<UserEntity> signInWithGoogle() => throw UnsupportedError('Firebase not configured');

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordReset(String email) => throw UnsupportedError('Firebase not configured');
}
