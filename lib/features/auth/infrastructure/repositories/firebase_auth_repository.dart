import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:baby_whistance_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:baby_whistance_app/shared/models/app_user.dart'; // Import the AppUser model

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore; // Add Firestore instance

  // Constructor allowing for dependency injection, useful for testing
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore, // Add Firestore to constructor
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance; // Initialize Firestore

  // Private helper to create user document in Firestore
  Future<void> _createNewUserDocumentInFirestore(User firebaseUser, String? displayName) async {
    try {
      // Use the provided displayName, or fallback to Firebase's displayName if available,
      // otherwise it will be null, which is handled by the AppUser model.
      final String? finalDisplayName = displayName ?? firebaseUser.displayName;

      final appUser = AppUser.initial(
        uid: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: finalDisplayName,
      );
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(appUser.toFirestore());
    } catch (e) {
      // Log error or handle as needed. This operation should ideally not fail often.
      // If it does, it might leave an auth user without a corresponding Firestore document.
      print('Error creating user document in Firestore: $e');
      // Optionally rethrow or have a more robust error handling/retry mechanism.
    }
  }

  @override
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName, // Add displayName
  }) async {
    print('[FirebaseAuthRepository] signUpWithEmailAndPassword CALLED with email: $email, displayName: $displayName');
    try {
      print('[FirebaseAuthRepository] Attempting _firebaseAuth.createUserWithEmailAndPassword...');
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('[FirebaseAuthRepository] _firebaseAuth.createUserWithEmailAndPassword SUCCEEDED. User UID: ${userCredential.user?.uid}');

      User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        print('[FirebaseAuthRepository] Attempting to update display name to: $displayName');
        await firebaseUser.updateDisplayName(displayName);
        print('[FirebaseAuthRepository] Display name update attempted.');
        // Reload user to get updated info including displayName
        // await firebaseUser.reload();
        // firebaseUser = _firebaseAuth.currentUser; 
        // print('[FirebaseAuthRepository] User reloaded. New displayName: ${firebaseUser?.displayName}');

        print('[FirebaseAuthRepository] Attempting to send email verification...');
        await firebaseUser.sendEmailVerification();
        print('[FirebaseAuthRepository] Email verification sent.');

        print('[FirebaseAuthRepository] Attempting to create user document in Firestore...');
        await _createNewUserDocumentInFirestore(firebaseUser, displayName);
        print('[FirebaseAuthRepository] User document creation attempted.');
      }
      return userCredential;
    } on FirebaseAuthException catch (e, stackTrace) {
      print('[FirebaseAuthRepository] signUpWithEmailAndPassword FirebaseAuthException: ${e.code} - ${e.message}');
      print('[FirebaseAuthRepository] StackTrace: $stackTrace');
      throw e;
    } catch (e, stackTrace) {
      print('[FirebaseAuthRepository] signUpWithEmailAndPassword Generic Exception: ${e.toString()}');
      print('[FirebaseAuthRepository] StackTrace: $stackTrace');
      throw e;
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    print('[FirebaseAuthRepository] sendEmailVerification CALLED');
    User? user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      try {
        print('[FirebaseAuthRepository] Current user: ${user.uid}. Attempting to send verification email...');
        await user.sendEmailVerification();
        print('[FirebaseAuthRepository] Email verification sent successfully to ${user.email}.');
      } catch (e, stackTrace) {
        print('[FirebaseAuthRepository] sendEmailVerification FAILED for ${user.email}. Error: $e');
        print('[FirebaseAuthRepository] StackTrace: $stackTrace');
        throw e;
      }
    } else if (user == null) {
      print('[FirebaseAuthRepository] sendEmailVerification: No user is currently signed in.');
    } else {
      print('[FirebaseAuthRepository] sendEmailVerification: Email ${user.email} is already verified.');
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
  Stream<User?> get authStateChanges {
    print('[FirebaseAuthRepository] authStateChanges getter CALLED');
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      print('[FirebaseAuthRepository] authStateChanges - Stream EMITTED Firebase User: ${firebaseUser?.uid}');
      return firebaseUser;
    });
  }

  @override
  Future<void> signOut() async {
    print('[FirebaseAuthRepository] signOut CALLED');
    try {
      await _firebaseAuth.signOut();
      print('[FirebaseAuthRepository] _firebaseAuth.signOut() SUCCEEDED.');
    } catch (e, stackTrace) {
      print('[FirebaseAuthRepository] signOut FAILED. Error: $e');
      print('[FirebaseAuthRepository] StackTrace: $stackTrace');
      throw e;
    }
  }

  @override
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    print('[FirebaseAuthRepository] signInWithEmailAndPassword CALLED with email: $email');
    try {
      print('[FirebaseAuthRepository] Attempting _firebaseAuth.signInWithEmailAndPassword...');
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('[FirebaseAuthRepository] _firebaseAuth.signInWithEmailAndPassword SUCCEEDED. User UID: ${userCredential.user?.uid}');
      return userCredential.user;
    } on FirebaseAuthException catch (e, stackTrace) {
      print('[FirebaseAuthRepository] signInWithEmailAndPassword FirebaseAuthException: ${e.code} - ${e.message}');
      print('[FirebaseAuthRepository] StackTrace: $stackTrace');
      // Consider re-throwing a domain-specific exception or handling appropriately
      throw e; // Re-throw for now, AuthController will catch it
    } catch (e, stackTrace) {
      print('[FirebaseAuthRepository] signInWithEmailAndPassword Generic Exception: ${e.toString()}');
      print('[FirebaseAuthRepository] StackTrace: $stackTrace');
      throw e; // Re-throw
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    print('[FirebaseAuthRepository] sendPasswordResetEmail CALLED for email: $email');
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      print('[FirebaseAuthRepository] Password reset email sent successfully to $email.');
    } catch (e, stackTrace) {
      print('[FirebaseAuthRepository] sendPasswordResetEmail FAILED for $email. Error: $e');
      print('[FirebaseAuthRepository] StackTrace: $stackTrace');
      throw e;
    }
  }

  @override
  Future<User?> reloadCurrentUser() async {
    print('[FirebaseAuthRepository] reloadCurrentUser CALLED');
    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        print('[FirebaseAuthRepository] Attempting to reload user: ${user.uid}');
        await user.reload();
        final reloadedUser = _firebaseAuth.currentUser; // Get the fresh user instance
        print('[FirebaseAuthRepository] User reloaded successfully: ${reloadedUser?.uid}, Verified: ${reloadedUser?.emailVerified}');
        return reloadedUser;
      } catch (e, stackTrace) {
        print('[FirebaseAuthRepository] reloadCurrentUser FAILED for ${user.uid}. Error: $e');
        print('[FirebaseAuthRepository] StackTrace: $stackTrace');
        throw e;
      }
    }
    print('[FirebaseAuthRepository] reloadCurrentUser: No user to reload.');
    return null;
  }
} 