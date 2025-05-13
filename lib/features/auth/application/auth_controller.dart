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
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    final authRepository = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => authRepository.signUpWithEmailAndPassword(email: email, password: password),
    );
    // The repository already sends a verification email on successful signup.
    // If not, we would call it here: await sendEmailVerification();
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    final authRepository = ref.read(authRepositoryProvider);
    // We might want to handle loading/error states here too if it's a user-initiated action
    // For now, just call it directly.
    await authRepository.sendEmailVerification();
  }

  // Check email verification status
  Future<bool> checkIsEmailVerified() async {
    final authRepository = ref.read(authRepositoryProvider);
    return await authRepository.isEmailVerified();
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

  // TODO: Add other methods like signInWithEmailAndPassword, etc.
} 