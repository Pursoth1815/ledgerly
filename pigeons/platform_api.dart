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

/// How a background job run ended (ADR 0013).
enum JobOutcome {
  /// The job finished its work.
  done,

  /// The job saved its progress and stopped early because it was asked to;
  /// it continues from that point the next time it runs.
  stopped,

  /// The job cannot finish, or its kind is unknown. It is not retried.
  failed,
}

/// The result of one job run. [detail] holds safe fields only, such as
/// `step=412/900`, never personal data.
class JobResult {
  JobResult({required this.outcome, required this.detail});

  JobOutcome outcome;
  String detail;
}

/// Called by the Dart side of an engine about background work and the
/// single database writer (ADR 0013).
@HostApi()
abstract class BackgroundHostApi {
  /// The app's own engine calls this before opening the database. It
  /// returns once this engine is the only writer. A background job that is
  /// writing is first asked to stop at its next checkpoint; the job then
  /// continues in this engine.
  @async
  void acquireWriter();

  /// The database is open and this engine can run jobs.
  void engineReady();

  /// The database could not be opened; [code] is the `AppException` code.
  void engineFailed(String code);
}

/// Called by Kotlin to run background jobs in a Dart engine (ADR 0013).
@FlutterApi()
abstract class BackgroundJobApi {
  /// Runs the job [kind]. [runId] names this run, and [attempt] counts the
  /// earlier runs of the same work.
  @async
  JobResult runJob(String runId, String kind, int attempt);

  /// Asks the run [runId] to save its progress and stop at its next
  /// checkpoint. Its `runJob` call then returns [JobOutcome.stopped].
  void stopJob(String runId);
}
