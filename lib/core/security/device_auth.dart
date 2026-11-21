import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../platform/platform_api.g.dart';

part 'device_auth.g.dart';

/// The phone's own fingerprint, face or PIN check, and the private window.
/// App lock uses them; they guard opening the app and are not the encryption
/// (ADR 0009). An interface so App lock can be tested without a phone.
abstract interface class DeviceAuth {
  /// Whether the phone has a fingerprint, face or screen lock to ask for.
  Future<bool> canCheckOwner();

  /// True once the owner passes the phone's check.
  Future<bool> checkOwner({required String title, required String subtitle});

  /// Hides Loopd in recent apps and blocks screenshots while [private].
  Future<void> setPrivateWindow(bool private);
}

class PigeonDeviceAuth implements DeviceAuth {
  PigeonDeviceAuth([DeviceApi? api]) : _api = api ?? DeviceApi();

  final DeviceApi _api;

  @override
  Future<bool> canCheckOwner() async {
    try {
      return await _api.canCheckOwner();
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> checkOwner({required String title, required String subtitle}) => OutsideActivity.during(() async {
    try {
      return await _api.checkOwner(title, subtitle);
    } on PlatformException {
      return false;
    }
  });

  @override
  Future<void> setPrivateWindow(bool private) async {
    try {
      await _api.setPrivateWindow(private);
    } on PlatformException {
      // No window yet (a test, or the headless engine): nothing to hide.
    }
  }
}

/// The phone's check and window; replaced in tests.
@Riverpod(keepAlive: true)
DeviceAuth deviceAuth(Ref ref) => PigeonDeviceAuth();

/// Android screens Loopd opens itself (the folder picker, the fingerprint
/// prompt) send Loopd to the background for a moment. App lock does not
/// count that as being away, so picking a backup folder never locks you out.
abstract final class OutsideActivity {
  static int _open = 0;

  /// True while one of those screens is up.
  static bool get active => _open > 0;

  static Future<T> during<T>(Future<T> Function() action) async {
    _open++;
    try {
      return await action();
    } finally {
      // Leave it set until the app has come back to the front.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _open--;
    }
  }
}
