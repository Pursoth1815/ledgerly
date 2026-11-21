// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lock_setting.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The settings read in `bootstrap()` before the first frame, so a locked
/// app never shows its content first. Overridden there.

@ProviderFor(initialAppLock)
final initialAppLockProvider = InitialAppLockProvider._();

/// The settings read in `bootstrap()` before the first frame, so a locked
/// app never shows its content first. Overridden there.

final class InitialAppLockProvider extends $FunctionalProvider<AppLockSettings, AppLockSettings, AppLockSettings>
    with $Provider<AppLockSettings> {
  /// The settings read in `bootstrap()` before the first frame, so a locked
  /// app never shows its content first. Overridden there.
  InitialAppLockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialAppLockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$initialAppLockHash();

  @$internal
  @override
  $ProviderElement<AppLockSettings> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AppLockSettings create(Ref ref) {
    return initialAppLock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLockSettings value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AppLockSettings>(value));
  }
}

String _$initialAppLockHash() => r'52d9ddedb8bb617aa42b87706e20764fe264d1ae';
