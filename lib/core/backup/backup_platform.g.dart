// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_platform.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The native backup bridge; replaced in tests.

@ProviderFor(backupPlatform)
final backupPlatformProvider = BackupPlatformProvider._();

/// The native backup bridge; replaced in tests.

final class BackupPlatformProvider extends $FunctionalProvider<BackupPlatform, BackupPlatform, BackupPlatform>
    with $Provider<BackupPlatform> {
  /// The native backup bridge; replaced in tests.
  BackupPlatformProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupPlatformProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupPlatformHash();

  @$internal
  @override
  $ProviderElement<BackupPlatform> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  BackupPlatform create(Ref ref) {
    return backupPlatform(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupPlatform value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<BackupPlatform>(value));
  }
}

String _$backupPlatformHash() => r'ebfd8e13c1c8e00a2dc05d7d62b93fb3b84949da';
