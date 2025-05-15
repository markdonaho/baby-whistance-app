// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: type=lint

part of 'app_status_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appStatusFirestoreHash() =>
    r'acdcfd2c084138da715b3d0c667ea1c6becbc576';

/// See also [appStatusFirestore].
@ProviderFor(appStatusFirestore)
final appStatusFirestoreProvider =
    AutoDisposeProvider<FirebaseFirestore>.internal(
      appStatusFirestore,
      name: r'appStatusFirestoreProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$appStatusFirestoreHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppStatusFirestoreRef = AutoDisposeProviderRef<FirebaseFirestore>;
String _$appStatusServiceHash() => r'a2658b875db64b18170bf959a29b1641c943800b';

/// See also [AppStatusService].
@ProviderFor(AppStatusService)
final appStatusServiceProvider =
    AutoDisposeStreamNotifierProvider<AppStatusService, AppStatus>.internal(
      AppStatusService.new,
      name: r'appStatusServiceProvider',
      debugGetCreateSourceHash:
          const bool.fromEnvironment('dart.vm.product')
              ? null
              : _$appStatusServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AppStatusService = AutoDisposeStreamNotifier<AppStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
