// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_auth.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The phone's check and window; replaced in tests.

@ProviderFor(deviceAuth)
final deviceAuthProvider = DeviceAuthProvider._();

/// The phone's check and window; replaced in tests.

final class DeviceAuthProvider extends $FunctionalProvider<DeviceAuth, DeviceAuth, DeviceAuth>
    with $Provider<DeviceAuth> {
  /// The phone's check and window; replaced in tests.
  DeviceAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceAuthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceAuthHash();

  @$internal
  @override
  $ProviderElement<DeviceAuth> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  DeviceAuth create(Ref ref) {
    return deviceAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceAuth value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<DeviceAuth>(value));
  }
}

String _$deviceAuthHash() => r'2137caa8d46e5a2b8f4672a76a05bbf56be3e0ad';
