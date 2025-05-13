import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  Future<void> sendEmailVerification();
  Future<bool> isEmailVerified();
  Stream<User?> get authStateChanges;

  Future<void> signOut();

  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<User?> reloadCurrentUser();
} 