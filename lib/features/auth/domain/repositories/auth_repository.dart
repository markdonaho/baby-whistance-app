import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> sendEmailVerification();
  Future<bool> isEmailVerified();
  Stream<User?> get authStateChanges;

  // We'll add other methods like signIn, signOut, getCurrentUser later
} 