import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; // aliased
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_service_consolidated.g.dart';

// --- From: lib/shared/models/app_user.dart ---
enum AppUserRole { user, admin, whistance }

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final AppUserRole role;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    required this.role,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return AppUser(
      uid: snapshot.id,
      email: data?['email'],
      displayName: data?['displayName'],
      role: AppUserRole.values.firstWhere(
        (e) => e.toString() == 'AppUserRole.' + (data?['role'] ?? 'user'), // Added default for role
        orElse: () => AppUserRole.user,
      ),
      createdAt: (data?['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data?['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (email != null) "email": email,
      if (displayName != null) "displayName": displayName,
      "role": role.toString().split('.').last,
      "createdAt": createdAt,
      "updatedAt": FieldValue.serverTimestamp(),
    };
  }

  static AppUser initial({
    required String uid,
    String? email,
    String? displayName,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      role: AppUserRole.user,
      createdAt: DateTime.now(),
    );
  }

  AppUser copyWith({
    String? displayName,
    AppUserRole? role,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// --- From: lib/features/auth/domain/repositories/auth_repository.dart ---
abstract class AuthRepository {
  Future<firebase_auth.UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  Future<void> sendEmailVerification();
  Future<bool> isEmailVerified(); // Note: This might need reconsideration if reloadCurrentUser is preferred
  Stream<firebase_auth.User?> get authStateChanges;

  Future<void> signOut();

  Future<firebase_auth.User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<firebase_auth.User?> reloadCurrentUser();
}

// --- From: lib/features/auth/infrastructure/repositories/firebase_auth_repository.dart ---
class FirebaseAuthRepository implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> _createNewUserDocumentInFirestore(firebase_auth.User firebaseUser, String? displayName) async {
    try {
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
      // Consider logging this error to a proper logging service in production
    }
  }

  @override
  Future<firebase_auth.UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      firebase_auth.UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebase_auth.User? firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(displayName);
        await firebaseUser.sendEmailVerification();
        await _createNewUserDocumentInFirestore(firebaseUser, displayName ?? firebaseUser.displayName);
      }
      return userCredential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw e;
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    firebase_auth.User? user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _firebaseAuth.currentUser;
    await user?.reload();
    return user?.emailVerified ?? false;
  }

  @override
  Stream<firebase_auth.User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser;
    });
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<firebase_auth.User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw e;
    } catch (e) {
      throw e;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<firebase_auth.User?> reloadCurrentUser() async {
    firebase_auth.User? user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.reload();
      return _firebaseAuth.currentUser; // Return the latest instance
    }
    return null;
  }
}

// --- From: lib/features/auth/application/auth_providers.dart (and adapted) ---
@riverpod
firebase_auth.FirebaseAuth firebaseAuthInstance(FirebaseAuthInstanceRef ref) {
  return firebase_auth.FirebaseAuth.instance;
}

@riverpod
FirebaseFirestore firebaseFirestoreInstance(FirebaseFirestoreInstanceRef ref) {
  return FirebaseFirestore.instance;
}

@riverpod
FirebaseStorage firebaseStorageInstance(FirebaseStorageInstanceRef ref) {
  return FirebaseStorage.instance;
}

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  final fbAuth = ref.watch(firebaseAuthInstanceProvider); // Use the new provider name
  final fs = ref.watch(firebaseFirestoreInstanceProvider); // Use the new provider name
  return FirebaseAuthRepository(firebaseAuth: fbAuth, firestore: fs);
}

@riverpod
Stream<firebase_auth.User?> authStateChangesStream(AuthStateChangesStreamRef ref) {
  // Directly use the repository's stream
  return ref.watch(authRepositoryProvider).authStateChanges;
}

@riverpod
Stream<AppUser?> appUserStream(AppUserStreamRef ref) {
  final firebaseAuthUser = ref.watch(authStateChangesStreamProvider).asData?.value;
  if (firebaseAuthUser == null) {
    return Stream.value(null);
  }
  try {
    final firestore = ref.watch(firebaseFirestoreInstanceProvider);
    return firestore
        .collection('users')
        .doc(firebaseAuthUser.uid)
        .withConverter<AppUser>(
          fromFirestore: (snapshot, _) => AppUser.fromFirestore(snapshot, null),
          toFirestore: (appUser, _) => appUser.toFirestore(),
        )
        .snapshots()
        .map((snapshot) {
          return snapshot.data();
        });
  } catch (e) {
    return Stream.value(null);
  }
}

// --- From: lib/features/auth/application/auth_controller.dart (and adapted) ---
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<firebase_auth.User?> build() {
    final authState = ref.watch(authStateChangesStreamProvider); // Use the new provider name
    return authState.asData?.value;
  }

  Future<void> signUpWithEmailAndPassword(String email, String password, String? displayName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<firebase_auth.User?>(
      () async {
        final userCredential = await ref
            .read(authRepositoryProvider)
            .signUpWithEmailAndPassword(
              email: email,
              password: password,
              displayName: displayName,
            );
        return userCredential?.user;
      },
    );
  }

  Future<void> sendEmailVerification() async {
    final repo = ref.read(authRepositoryProvider);
    final currentUser = state.asData?.value;
    state = const AsyncValue.loading();
    try {
      await repo.sendEmailVerification();
      state = AsyncValue.data(currentUser); // Reset to current user state, or re-fetch if necessary
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<bool> checkIsEmailVerified() async {
    state = const AsyncValue.loading();
    try {
      final firebase_auth.User? reloadedUser = await ref.read(authRepositoryProvider).reloadCurrentUser();
      if (reloadedUser != null) {
        state = AsyncValue.data(reloadedUser);
        return reloadedUser.emailVerified;
      } else {
        state = const AsyncValue.data(null);
        return false;
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncValue.data(null); // User is now null
  }

  Future<firebase_auth.User?> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref.read(authRepositoryProvider).signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (user == null) {
        state = AsyncValue.error("Login failed. Please check credentials.", StackTrace.current);
        return null;
      } else {
        state = AsyncValue.data(user);
        return user;
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return null;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      state = const AsyncValue.data(null); // Indicate completion, user state might not change here.
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
} 