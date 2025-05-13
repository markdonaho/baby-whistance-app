import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:baby_whistance_app/features/auth/application/auth_providers.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<User?> build() {
    print('[AuthController] build() CALLED');
    // Listen to auth state changes and return the user object
    // This will automatically update when the auth state changes
    final authStateChanges = ref.watch(authStateChangesProvider);
    print('[AuthController] build() - authStateChangesProvider WATCHED. Current stream value (might be async): ${authStateChanges.toString()}');
    final user = authStateChanges.asData?.value;
    print('[AuthController] build() - Current user from stream: ${user?.uid}, Verified: ${user?.emailVerified}');
    return user;
  }

  // Sign up method
  Future<void> signUpWithEmailAndPassword(String email, String password, String? displayName) async {
    print('[AuthController] signUpWithEmailAndPassword CALLED with email: $email, displayName: $displayName');
    state = const AsyncValue.loading();
    print('[AuthController] State set to loading for signup.');
    state = await AsyncValue.guard<User?>(
      () async {
        print('[AuthController] AsyncValue.guard (signUp): Attempting actual signup via repository...');
        final userCredential = await ref
            .read(authRepositoryProvider)
            .signUpWithEmailAndPassword(
              email: email,
              password: password,
              displayName: displayName,
            );
        print('[AuthController] AsyncValue.guard (signUp): Repository call completed. UserCredential UID: ${userCredential?.user?.uid}');
        return userCredential?.user; // Extract User from UserCredential
      },
    );
    print('[AuthController] signUpWithEmailAndPassword COMPLETED. Final state: User: ${state.value?.uid}, Verified: ${state.value?.emailVerified}, HasError: ${state.hasError}, IsLoading: ${state.isLoading}');
    // The repository already sends a verification email on successful signup
    // and creates the user document in Firestore.
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    print('[AuthController] sendEmailVerification CALLED');
    final authRepository = ref.read(authRepositoryProvider);
    final User? currentUser = state.asData?.value;
    print('[AuthController] sendEmailVerification - Current user before sending: ${currentUser?.uid}');
    state = const AsyncValue.loading();
    print('[AuthController] sendEmailVerification - State set to loading.');
    try {
      await authRepository.sendEmailVerification();
      print('[AuthController] sendEmailVerification - Repository call successful.');
      state = AsyncValue.data(currentUser); // Reset to current user state
      print('[AuthController] sendEmailVerification - State set back to data with user: ${currentUser?.uid}');
    } catch (e, stackTrace) {
      print('[AuthController] sendEmailVerification - ERROR: $e, StackTrace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Check email verification status
  Future<bool> checkIsEmailVerified() async {
    print('[AuthController] checkIsEmailVerified CALLED');
    state = const AsyncValue.loading(); 
    print('[AuthController] checkIsEmailVerified - State set to loading.');
    try {
      final User? reloadedUser = await ref.read(authRepositoryProvider).reloadCurrentUser();
      print('[AuthController] checkIsEmailVerified - Current user reloaded: ${reloadedUser?.uid}, Verified: ${reloadedUser?.emailVerified}');
      
      if (reloadedUser != null) {
        state = AsyncValue.data(reloadedUser);
        print('[AuthController] checkIsEmailVerified - State updated with reloaded user.');
        return reloadedUser.emailVerified;
      } else {
        state = const AsyncValue.data(null);
        print('[AuthController] checkIsEmailVerified - Reloaded user is null. State set to data(null).');
        return false;
      }
    } catch (e, stackTrace) {
      print('[AuthController] checkIsEmailVerified - ERROR: $e, StackTrace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  // Sign out method
  Future<void> signOut() async {
    print('[AuthController] signOut CALLED');
    final authRepository = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    print('[AuthController] signOut - State set to loading.');
    await authRepository.signOut(); 
    print('[AuthController] signOut - Repository call successful.');
    state = const AsyncValue.data(null); 
    print('[AuthController] signOut - State set to data(null).');
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    print('[AuthController] signInWithEmailAndPassword CALLED with email: $email');
    state = const AsyncValue.loading();
    print('[AuthController] signInWithEmailAndPassword - State set to loading.');
    try {
      print('[AuthController] signInWithEmailAndPassword - Attempting to get authRepositoryProvider.');
      final authRepository = ref.read(authRepositoryProvider);
      print('[AuthController] signInWithEmailAndPassword - authRepositoryProvider obtained. Attempting to call repository.signInWithEmailAndPassword.');

      final user = await authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('[AuthController] signInWithEmailAndPassword - repository.signInWithEmailAndPassword COMPLETED. User: ${user?.uid}, Verified: ${user?.emailVerified}');

      if (user == null) {
        print('[AuthController] signInWithEmailAndPassword - User is null after repository call.');
        state = AsyncValue.error(
            "Login failed. Please check your credentials or verify your email.",
            StackTrace.current);
        return null;
      } else {
        print('[AuthController] signInWithEmailAndPassword - User is NOT null. UID: ${user.uid}, EmailVerified: ${user.emailVerified}');
        state = AsyncValue.data(user);
        return user;
      }
    } catch (e, stackTrace) {
      print('[AuthController] signInWithEmailAndPassword - EXCEPTION CAUGHT: ${e.toString()}');
      print('[AuthController] signInWithEmailAndPassword - StackTrace: ${stackTrace.toString()}');
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    print('[AuthController] sendPasswordResetEmail CALLED for email: $email');
    state = const AsyncValue.loading();
    print('[AuthController] sendPasswordResetEmail - State set to loading.');
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      print('[AuthController] sendPasswordResetEmail - Repository call successful.');
      state = const AsyncValue.data(null); 
      print('[AuthController] sendPasswordResetEmail - State set to data(null) to indicate success/completion.');
    } catch (e, stackTrace) {
      print('[AuthController] sendPasswordResetEmail - ERROR: $e, StackTrace: $stackTrace');
      state = AsyncValue.error(e, stackTrace);
    }
  }

} 