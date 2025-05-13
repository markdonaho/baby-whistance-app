import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:baby_whistance_app/features/auth/application/auth_providers.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<User?> build() {
    // Listen to auth state changes and return the user object
    // This will automatically update when the auth state changes
    return ref.watch(authStateChangesProvider).asData?.value;
  }

  // Sign up method
  Future<void> signUpWithEmailAndPassword(String email, String password, String? displayName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<User?>(
      () async {
        final userCredential = await ref
            .read(authRepositoryProvider)
            .signUpWithEmailAndPassword(
              email: email,
              password: password,
              displayName: displayName,
            );
        return userCredential?.user; // Extract User from UserCredential
      },
    );
    // The repository already sends a verification email on successful signup
    // and creates the user document in Firestore.
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    final authRepository = ref.read(authRepositoryProvider);
    // Get current user from this controller's state
    final User? currentUser = state.asData?.value;
    state = const AsyncValue.loading();
    try {
      await authRepository.sendEmailVerification();
      state = AsyncValue.data(currentUser); // Reset to current user state
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Check email verification status
  Future<bool> checkIsEmailVerified() async {
    // Indicate loading while we check and reload the user
    state = const AsyncValue.loading(); 
    try {
      // Reload the user from the repository
      final User? reloadedUser = await ref.read(authRepositoryProvider).reloadCurrentUser();
      
      if (reloadedUser != null) {
        // Update the controller's state with the fresh user data
        state = AsyncValue.data(reloadedUser);
        return reloadedUser.emailVerified;
      } else {
        // If reloadedUser is null (e.g., user signed out, or error during reload),
        // set an error state or revert to a non-error state with null data.
        // For simplicity, mirroring the authStateChanges stream which would yield null.
        state = const AsyncValue.data(null);
        return false;
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  // Sign out method
  Future<void> signOut() async {
    final authRepository = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    // Firebase signout doesn't return a future that resolves to the new user state directly in the same way.
    // The authStateChangesProvider will reflect the change.
    await authRepository.signOut(); // Assuming signOut is added to AuthRepository
    state = const AsyncValue.data(null); // Explicitly set state to null after signout
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    print('[AuthController] signInWithEmailAndPassword CALLED with email: $email');
    state = const AsyncValue.loading();
    print('[AuthController] State set to loading.');
    try {
      print('[AuthController] Attempting to get authRepositoryProvider.');
      final authRepository = ref.read(authRepositoryProvider);
      print('[AuthController] authRepositoryProvider obtained. Attempting to call repository.signInWithEmailAndPassword.');

      final user = await authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('[AuthController] repository.signInWithEmailAndPassword COMPLETED. User: ${user?.uid}');

      if (user == null) {
        print('[AuthController] User is null after repository call.');
        state = AsyncValue.error(
            "Login failed. Please check your credentials or verify your email.",
            StackTrace.current);
        return null;
      } else {
        print('[AuthController] User is NOT null. UID: ${user.uid}, EmailVerified: ${user.emailVerified}');
        state = AsyncValue.data(user);
        return user;
      }
    } catch (e, stackTrace) {
      print('[AuthController] EXCEPTION CAUGHT: ${e.toString()}');
      print('[AuthController] StackTrace: ${stackTrace.toString()}');
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      state = const AsyncValue.data(null); // Indicate success, maybe with a message
      // UI should inform the user to check their email
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

} 