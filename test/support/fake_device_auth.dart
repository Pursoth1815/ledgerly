import 'package:loopd/core/security/device_auth.dart';

/// The phone's check and window, faked: answers as told and records calls.
class FakeDeviceAuth implements DeviceAuth {
  bool hasScreenLock = true;
  bool passes = true;
  bool? private;
  final calls = <String>[];

  @override
  Future<bool> canCheckOwner() async => hasScreenLock;

  @override
  Future<bool> checkOwner({required String title, required String subtitle}) async {
    calls.add('check');
    return passes;
  }

  @override
  Future<void> setPrivateWindow(bool private) async => this.private = private;
}
