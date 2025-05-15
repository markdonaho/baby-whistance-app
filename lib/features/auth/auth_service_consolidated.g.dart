// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint

part of 'auth_service_consolidated.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firebaseAuthInstanceHash() =>
    r'6ef5ee9e45a86d4d860cdea108db0d1172f85e83';

/// See also [firebaseAuthInstance].
@ProviderFor(firebaseAuthInstance)
final firebaseAuthInstanceProvider =
    AutoDisposeProvider<firebase_auth.FirebaseAuth>.internal(
      firebaseAuthInstance,
      name: r'firebaseAuthInstanceProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$firebaseAuthInstanceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseAuthInstanceRef =
    AutoDisposeProviderRef<firebase_auth.FirebaseAuth>;
String _$firebaseFirestoreInstanceHash() =>
    r'61f08d99be908bcf239586847028e42d3dff76f5';

/// See also [firebaseFirestoreInstance].
@ProviderFor(firebaseFirestoreInstance)
final firebaseFirestoreInstanceProvider =
    AutoDisposeProvider<FirebaseFirestore>.internal(
      firebaseFirestoreInstance,
      name: r'firebaseFirestoreInstanceProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$firebaseFirestoreInstanceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseFirestoreInstanceRef =
    AutoDisposeProviderRef<FirebaseFirestore>;
String _$firebaseStorageInstanceHash() =>
    r'9bcfba61dd1a89a8ad13846d4bd7ff4fd372c37d';

/// See also [firebaseStorageInstance].
@ProviderFor(firebaseStorageInstance)
final firebaseStorageInstanceProvider =
    AutoDisposeProvider<FirebaseStorage>.internal(
      firebaseStorageInstance,
      name: r'firebaseStorageInstanceProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$firebaseStorageInstanceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseStorageInstanceRef = AutoDisposeProviderRef<FirebaseStorage>;
String _$authRepositoryHash() => r'285af7f7661bf287db6d9ff93423adfe02009a6f';

/// See also [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = AutoDisposeProvider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthRepositoryRef = AutoDisposeProviderRef<AuthRepository>;
String _$authStateChangesStreamHash() =>
    r'0de2e440a3135e9e568e638f17ec9dd34e6453ab';

/// See also [authStateChangesStream].
@ProviderFor(authStateChangesStream)
final authStateChangesStreamProvider =
    AutoDisposeStreamProvider<firebase_auth.User?>.internal(
      authStateChangesStream,
      name: r'authStateChangesStreamProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$authStateChangesStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthStateChangesStreamRef =
    AutoDisposeStreamProviderRef<firebase_auth.User?>;
String _$appUserStreamHash() => r'ddc949f8fabcee5edf6745480ddf670c1249ddf6';

/// See also [appUserStream].
@ProviderFor(appUserStream)
final appUserStreamProvider = AutoDisposeStreamProvider<AppUser?>.internal(
  appUserStream,
  name: r'appUserStreamProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$appUserStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppUserStreamRef = AutoDisposeStreamProviderRef<AppUser?>;
String _$authControllerHash() => r'14ad45e56ee2ff27666fec20fb5e52cb8697b8dd';

/// See also [AuthController].
@ProviderFor(AuthController)
final authControllerProvider = AutoDisposeAsyncNotifierProvider<
  AuthController,
  firebase_auth.User?
>.internal(
  AuthController.new,
  name: r'authControllerProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthController = AutoDisposeAsyncNotifier<firebase_auth.User?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
