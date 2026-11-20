// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where backup stands, for the Backup & restore page.

@ProviderFor(backupStatus)
final backupStatusProvider = BackupStatusProvider._();

/// Where backup stands, for the Backup & restore page.

final class BackupStatusProvider
    extends $FunctionalProvider<AsyncValue<BackupStatus>, BackupStatus, Stream<BackupStatus>>
    with $FutureModifier<BackupStatus>, $StreamProvider<BackupStatus> {
  /// Where backup stands, for the Backup & restore page.
  BackupStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupStatusHash();

  @$internal
  @override
  $StreamProviderElement<BackupStatus> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<BackupStatus> create(Ref ref) {
    return backupStatus(ref);
  }
}

String _$backupStatusHash() => r'786a34244ffef28f29399421f55bc38b2472ed20';
