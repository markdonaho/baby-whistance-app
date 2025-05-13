import 'package:firebase_auth/firebase_auth.dart';
import 'package:baby_whistance_app/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  // Constructor allowing for dependency injection, useful for testing
  FirebaseAuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Send verification email
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase auth errors (e.g., email-already-in-use, weak-password)
      // For now, we'll just print and rethrow, but we can make this more robust.
      print('FirebaseAuthException during sign up: ${e.code} - ${e.message}');
      // It's often better to throw a custom exception or return a result type
      // that the UI layer can understand and display to the user.
      rethrow; // Or handle more gracefully
    } catch (e) {
      // Handle other errors
      print('Generic exception during sign up: $e');
      rethrow; // Or handle more gracefully
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    // It's important to reload the user data to get the latest verification status
    await user?.reload(); 
    return user?.emailVerified ?? false;
  }

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
} 