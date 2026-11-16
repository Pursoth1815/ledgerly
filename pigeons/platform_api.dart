// The typed interface between Dart and the Kotlin code in android/app.
// See docs/adr/0012-native-code-in-the-app-module.md.
//
// Regenerate after editing:
//   dart run pigeon --input pigeons/platform_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/core/platform/platform_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/app/src/main/kotlin/com/pursoth/loopd/bridge/PlatformApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.pursoth.loopd.bridge'),
    dartPackageName: 'loopd',
  ),
)
/// Keys protected by the Android Keystore (ADR 0009).
///
/// Errors are reported as `PlatformException`s whose `code` is one of:
/// `key_missing`, `key_corrupt`, `keystore_unavailable`.
@HostApi()
abstract class KeyStoreApi {
  /// Returns the 32-byte database key.
  ///
  /// When no key has been stored yet, a new one is created only if
  /// [createIfMissing] is true; otherwise the call fails with `key_missing`.
  /// Runs on one background thread, so Keystore calls never overlap.
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  Uint8List databaseKey(bool createIfMissing);
}
