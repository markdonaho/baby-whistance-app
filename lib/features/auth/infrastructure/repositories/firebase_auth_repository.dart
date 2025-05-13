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
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Send verification email
        if (!userCredential.user!.emailVerified) {
          await userCredential.user!.sendEmailVerification();
        }
        // Create user document in Firestore
        await _createNewUserDocumentInFirestore(userCredential.user!, displayName); 
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

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    print('[FirebaseAuthRepository] signInWithEmailAndPassword CALLED with email: $email');
    try {
      print('[FirebaseAuthRepository] Attempting _firebaseAuth.signInWithEmailAndPassword...');
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('[FirebaseAuthRepository] _firebaseAuth.signInWithEmailAndPassword SUCCEEDED. User UID: ${userCredential.user?.uid}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('[FirebaseAuthRepository] FirebaseAuthException CAUGHT: ${e.code} - ${e.message}');
      // Consider specific error handling here (e.g., user-not-found, wrong-password)
      // For now, rethrow or handle generically
      print('Firebase Auth Exception during sign in: ${e.code} - ${e.message}');
      throw e; // Rethrow to be handled by the controller or UI
    } catch (e, stackTrace) {
      print('[FirebaseAuthRepository] Generic EXCEPTION CAUGHT: ${e.toString()}');
      print('[FirebaseAuthRepository] StackTrace: ${stackTrace.toString()}');
      throw e; // Rethrow to ensure it's handled upstream
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Handle errors, e.g., user not found
      print('Firebase Auth Exception during password reset: ${e.code} - ${e.message}');
      throw e; // Rethrow to be handled by the controller or UI
    }
  }

  @override
  Future<User?> reloadCurrentUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
      return _firebaseAuth.currentUser;
    } catch (e) {
      print('Error reloading user: $e');
      // Optionally rethrow or handle more gracefully
      // Consider returning null or rethrowing if reload is critical and fails
      return _firebaseAuth.currentUser; // Or null if preferred on failure
    }
  }
} 