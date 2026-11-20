// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_engine.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The backup engine. Restore and passphrase changes join it in parts 6b and 6c.

@ProviderFor(backupEngine)
final backupEngineProvider = BackupEngineProvider._();

/// The backup engine. Restore and passphrase changes join it in parts 6b and 6c.

final class BackupEngineProvider extends $FunctionalProvider<BackupEngine, BackupEngine, BackupEngine>
    with $Provider<BackupEngine> {
  /// The backup engine. Restore and passphrase changes join it in parts 6b and 6c.
  BackupEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupEngineHash();

  @$internal
  @override
  $ProviderElement<BackupEngine> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  BackupEngine create(Ref ref) {
    return backupEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupEngine value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<BackupEngine>(value));
  }
}

String _$backupEngineHash() => r'76acaa90a914bd99ecbf8b29a5e3d8c79abe9449';
