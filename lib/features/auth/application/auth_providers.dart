import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:baby_whistance_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:baby_whistance_app/features/auth/infrastructure/repositories/firebase_auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:baby_whistance_app/shared/models/app_user.dart';
import 'package:firebase_storage/firebase_storage.dart';

part 'auth_providers.g.dart'; // Part directive for generated code

@riverpod
FirebaseAuth firebaseAuth(FirebaseAuthRef ref) {
  print('[AuthProviders] firebaseAuth provider CALLED');
  return FirebaseAuth.instance;
}

@riverpod
FirebaseFirestore firebaseFirestore(FirebaseFirestoreRef ref) {
  print('[AuthProviders] firebaseFirestore provider CALLED');
  return FirebaseFirestore.instance;
}

@riverpod
FirebaseStorage firebaseStorage(FirebaseStorageRef ref) {
  print('[AuthProviders] firebaseStorage provider CALLED');
  return FirebaseStorage.instance;
}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  print('[AuthProviders] authRepository provider CALLED');
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  print('[AuthProviders] authRepository - firebaseAuth and firebaseFirestore WATCHED');
  return FirebaseAuthRepository(
    firebaseAuth: firebaseAuth,
    firestore: firestore,
  );
}

@riverpod
Stream<User?> authStateChanges(AuthStateChangesRef ref) {
  print('[AuthProviders] authStateChanges provider CALLED');
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  print('[AuthProviders] authStateChanges - firebaseAuth WATCHED');
  return firebaseAuth.authStateChanges().map((user) {
    print('[AuthProviders] authStateChanges - Stream EMITTED User: ${user?.uid}, Verified: ${user?.emailVerified}');
    return user;
  });
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