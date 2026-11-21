import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/security/device_auth.dart';
import '../../../../core/settings/app_lock_setting.dart';

part 'app_lock_providers.g.dart';

/// Where App lock stands.
class AppLockState {
  const AppLockState({required this.settings, this.locked = false, this.failed = false, this.checking = false});

  final AppLockSettings settings;

  /// The lock screen covers the app.
  final bool locked;

  /// The last unlock try did not pass.
  final bool failed;

  /// The phone's check is up.
  final bool checking;

  AppLockState copyWith({AppLockSettings? settings, bool? locked, bool? failed, bool? checking}) => AppLockState(
    settings: settings ?? this.settings,
    locked: locked ?? this.locked,
    failed: failed ?? this.failed,
    checking: checking ?? this.checking,
  );
}

/// Why turning App lock on did not happen.
enum AppLockRefusal {
  /// The phone has no fingerprint, face or screen lock to ask for.
  noScreenLock,

  /// The check was cancelled or did not pass.
  notConfirmed,
}

/// The clock App lock measures time away with; replaced in tests.
@Riverpod(keepAlive: true)
DateTime Function() appLockClock(Ref ref) => DateTime.now;

/// App lock (proposal section 11): fingerprint, face or the phone's PIN when
/// Loopd starts, and when it comes back after the chosen time away. While it
/// is on, Loopd is hidden in recent apps and screenshots are blocked (owner,
/// 21 Nov 2026). It guards opening the app; the data is encrypted either way
/// (ADR 0009).
@Riverpod(keepAlive: true)
class AppLock extends _$AppLock {
  DateTime? _awaySince;

  DeviceAuth get _device => ref.read(deviceAuthProvider);

  @override
  AppLockState build() {
    final settings = ref.watch(initialAppLockProvider);
    final listener = AppLifecycleListener(onStateChange: _onLifecycle);
    ref.onDispose(listener.dispose);
    unawaited(_device.setPrivateWindow(settings.enabled));
    // A fresh start asks straight away.
    return AppLockState(settings: settings, locked: settings.enabled);
  }

  void _onLifecycle(AppLifecycleState lifecycle) {
    final now = ref.read(appLockClockProvider)();
    switch (lifecycle) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        // Loopd's own errands (a picker, the fingerprint prompt) are not away.
        if (_awaySince == null && !OutsideActivity.active) _awaySince = now;
      case AppLifecycleState.resumed:
        final since = _awaySince;
        _awaySince = null;
        if (since == null || !state.settings.enabled || state.locked) return;
        if (now.difference(since) >= Duration(minutes: state.settings.afterMinutes)) {
          state = state.copyWith(locked: true, failed: false);
        }
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  /// Asks for the phone's check; unlocks when it passes.
  Future<void> unlock() async {
    if (state.checking || !state.locked) return;
    state = state.copyWith(checking: true);
    final ok = await _device.checkOwner(title: 'Unlock Loopd', subtitle: 'Fingerprint, face or your phone’s PIN');
    state = state.copyWith(locked: !ok, failed: !ok, checking: false);
  }

  /// Turns App lock on (after one check, to be sure it works) or off.
  /// Returns why it stayed off, or null.
  Future<AppLockRefusal?> setEnabled({required bool on}) async {
    if (on) {
      if (!await _device.canCheckOwner()) return AppLockRefusal.noScreenLock;
      final ok = await _device.checkOwner(title: 'Turn on App lock', subtitle: 'Confirm it’s you once');
      if (!ok) return AppLockRefusal.notConfirmed;
    }
    await _save(state.settings.copyWith(enabled: on));
    await _device.setPrivateWindow(on);
    return null;
  }

  /// How long Loopd may be away before it asks again: 0 (Now), 1, 5 or 15 minutes.
  Future<void> setAfterMinutes(int minutes) => _save(state.settings.copyWith(afterMinutes: minutes));

  Future<void> _save(AppLockSettings settings) async {
    state = state.copyWith(settings: settings);
    await AppLockSettingStore(ref.read(appDatabaseProvider)).save(settings);
  }
}
