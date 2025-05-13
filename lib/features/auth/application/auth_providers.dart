import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:baby_whistance_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:baby_whistance_app/features/auth/infrastructure/repositories/firebase_auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:baby_whistance_app/shared/models/app_user.dart';

part 'auth_providers.g.dart'; // Part directive for generated code

@riverpod
FirebaseAuth firebaseAuth(FirebaseAuthRef ref) {
  return FirebaseAuth.instance;
}

@riverpod
FirebaseFirestore firebaseFirestore(FirebaseFirestoreRef ref) {
  return FirebaseFirestore.instance;
}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return FirebaseAuthRepository(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@riverpod
Stream<User?> authStateChanges(AuthStateChangesRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

// Provider to get the current AppUser data from Firestore
@riverpod
Stream<AppUser?> appUser(AppUserRef ref) {
  final firebaseAuthUser = ref.watch(authStateChangesProvider).asData?.value;
  if (firebaseAuthUser == null) {
    return Stream.value(null);
  }
  try {
    final firestore = ref.watch(firebaseFirestoreProvider);
    return firestore
        .collection('users')
        .doc(firebaseAuthUser.uid)
        .withConverter<AppUser>(
          fromFirestore: (snapshot, _) => AppUser.fromFirestore(snapshot, null),
          toFirestore: (appUser, _) => appUser.toFirestore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.data());
  } catch (e) {
    // Log error or handle appropriately
    print('Error fetching AppUser stream: $e');
    return Stream.value(null);
  }
} 