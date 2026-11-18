// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capture_button_visibility.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the capture button shows now.

@ProviderFor(captureButtonVisible)
final captureButtonVisibleProvider = CaptureButtonVisibleProvider._();

/// Whether the capture button shows now.

final class CaptureButtonVisibleProvider extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  /// Whether the capture button shows now.
  CaptureButtonVisibleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'captureButtonVisibleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$captureButtonVisibleHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return captureButtonVisible(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<bool>(value));
  }
}

String _$captureButtonVisibleHash() => r'8ce0b02ac63cf83306f57c43b9362235871124ed';

/// The path of the page on screen, such as `/more`. The router
/// keeps it current.

@ProviderFor(ShellLocation)
final shellLocationProvider = ShellLocationProvider._();

/// The path of the page on screen, such as `/more`. The router
/// keeps it current.
final class ShellLocationProvider extends $NotifierProvider<ShellLocation, String> {
  /// The path of the page on screen, such as `/more`. The router
  /// keeps it current.
  ShellLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shellLocationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shellLocationHash();

  @$internal
  @override
  ShellLocation create() => ShellLocation();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<String>(value));
  }
}

String _$shellLocationHash() => r'fd4b927622956ba7775d76bd1d82ce12c0dd9ab1';

/// The path of the page on screen, such as `/more`. The router
/// keeps it current.

abstract class _$ShellLocation extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<String, String>, String, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// How many sheets and dialogs are open, across every navigator.

@ProviderFor(OpenOverlays)
final openOverlaysProvider = OpenOverlaysProvider._();

/// How many sheets and dialogs are open, across every navigator.
final class OpenOverlaysProvider extends $NotifierProvider<OpenOverlays, int> {
  /// How many sheets and dialogs are open, across every navigator.
  OpenOverlaysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openOverlaysProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openOverlaysHash();

  @$internal
  @override
  OpenOverlays create() => OpenOverlays();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<int>(value));
  }
}

String _$openOverlaysHash() => r'71dae4f759c215252e793da3ce1aeb2970d4eb8b';

/// How many sheets and dialogs are open, across every navigator.

abstract class _$OpenOverlays extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element = ref.element as $ClassProviderElement<AnyNotifier<int, int>, int, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
