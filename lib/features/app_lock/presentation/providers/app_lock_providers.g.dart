// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lock_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The clock App lock measures time away with; replaced in tests.

@ProviderFor(appLockClock)
final appLockClockProvider = AppLockClockProvider._();

/// The clock App lock measures time away with; replaced in tests.

final class AppLockClockProvider
    extends $FunctionalProvider<DateTime Function(), DateTime Function(), DateTime Function()>
    with $Provider<DateTime Function()> {
  /// The clock App lock measures time away with; replaced in tests.
  AppLockClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockClockHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return appLockClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<DateTime Function()>(value));
  }
}

String _$appLockClockHash() => r'41bfbf68fae8f2e3341a1494506bdb6a4b20a5fa';

/// App lock (proposal section 11): fingerprint, face or the phone's PIN when
/// Loopd starts, and when it comes back after the chosen time away. While it
/// is on, Loopd is hidden in recent apps and screenshots are blocked (owner,
/// 21 Nov 2026). It guards opening the app; the data is encrypted either way
/// (ADR 0009).

@ProviderFor(AppLock)
final appLockProvider = AppLockProvider._();

/// App lock (proposal section 11): fingerprint, face or the phone's PIN when
/// Loopd starts, and when it comes back after the chosen time away. While it
/// is on, Loopd is hidden in recent apps and screenshots are blocked (owner,
/// 21 Nov 2026). It guards opening the app; the data is encrypted either way
/// (ADR 0009).
final class AppLockProvider extends $NotifierProvider<AppLock, AppLockState> {
  /// App lock (proposal section 11): fingerprint, face or the phone's PIN when
  /// Loopd starts, and when it comes back after the chosen time away. While it
  /// is on, Loopd is hidden in recent apps and screenshots are blocked (owner,
  /// 21 Nov 2026). It guards opening the app; the data is encrypted either way
  /// (ADR 0009).
  AppLockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLockHash();

  @$internal
  @override
  AppLock create() => AppLock();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppLockState value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AppLockState>(value));
  }
}

String _$appLockHash() => r'106de327b52b7ef7e46b9d8c11972db45f9ec332';

/// App lock (proposal section 11): fingerprint, face or the phone's PIN when
/// Loopd starts, and when it comes back after the chosen time away. While it
/// is on, Loopd is hidden in recent apps and screenshots are blocked (owner,
/// 21 Nov 2026). It guards opening the app; the data is encrypted either way
/// (ADR 0009).

abstract class _$AppLock extends $Notifier<AppLockState> {
  AppLockState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AppLockState, AppLockState>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<AppLockState, AppLockState>, AppLockState, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
