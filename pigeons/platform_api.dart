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

/// A folder picked with the system folder picker, kept with permanent access.
class BackupFolderInfo {
  BackupFolderInfo({required this.uri, required this.name});

  /// The tree URI, kept to write there later.
  String uri;

  /// What to show, such as "Drive › Loopd backups".
  String name;
}

/// One backup run to write (ADR 0011).
class BackupRequest {
  BackupRequest({
    required this.runId,
    required this.folderUri,
    required this.databasePath,
    required this.databaseKeyHex,
    required this.createdAt,
    required this.appVersion,
    required this.schemaVersion,
  });

  String runId;
  String folderUri;

  /// The encrypted database copy (`sqlcipher_export` under a fresh key).
  String databasePath;

  /// That copy's key; it travels only inside the encrypted manifest.
  String databaseKeyHex;
  int createdAt;
  String appVersion;
  int schemaVersion;
}

/// What a run wrote.
class BackupWritten {
  BackupWritten({required this.indexName, required this.files, required this.totalBytes});

  String indexName;
  List<String> files;
  int totalBytes;
}

/// A backup found in a folder, from its file names (no passphrase needed).
class FoundBackupInfo {
  FoundBackupInfo({required this.indexName, required this.runId, required this.parts, required this.totalBytes});

  String indexName;

  /// Starts with the local date and time it was made: `20261115-020000-4f2a`.
  String runId;
  int parts;
  int totalBytes;
}

/// What an unlocked backup says about itself.
class OpenedBackupInfo {
  OpenedBackupInfo({
    required this.runId,
    required this.createdAt,
    required this.appVersion,
    required this.schemaVersion,
    required this.parts,
  });

  String runId;
  int createdAt;
  String appVersion;
  int schemaVersion;
  int parts;
}

/// Encrypted backups (ADR 0011). Errors are `PlatformException`s whose `code`
/// is one of: `not_set_up`, `wrong_passphrase`, `keystore_unavailable`,
/// `folder_lost`, `out_of_space`, `write_failed`, `verify_failed`,
/// `not_a_backup`, `cancelled`.
@HostApi()
abstract class BackupApi {
  /// Opens the system folder picker; null when nothing was picked.
  @async
  BackupFolderInfo? pickFolder();

  /// Whether Loopd can still write to [folderUri].
  bool canWrite(String folderUri);

  /// Makes the backup key, wrapped by the Keystore and by [passphrase]
  /// (Argon2id, about a second).
  @async
  void setUp(String passphrase);

  /// Whether a backup key exists on this phone.
  bool isSetUp();

  /// Writes the parts, then the index.
  @async
  BackupWritten writeBackup(BackupRequest request);

  /// Reads the backup in [indexName] back and checks every part.
  @async
  void verifyBackup(String folderUri, String indexName);

  /// Removes [names] from the folder; files already gone are fine.
  @async
  void deleteFiles(String folderUri, List<String> names);

  /// The backups in [folderUri], newest first.
  @async
  List<FoundBackupInfo> listBackups(String folderUri);

  /// Unlocks [indexName] with [passphrase] (Argon2id, about a second) and
  /// reads its manifest. Fails with `wrong_passphrase` or `not_a_backup`.
  /// The unlocked backup is kept for the next two calls.
  @async
  OpenedBackupInfo openBackup(String folderUri, String indexName, String passphrase);

  /// Reads every part of the opened backup back and checks it.
  @async
  void verifyOpenedBackup();

  /// Writes the opened backup's database copy to [targetPath] and returns
  /// that copy's key (hex). Forgets the unlocked backup afterwards.
  @async
  String extractOpenedDatabase(String targetPath);

  /// Starts Loopd again, so a restored database is switched in at start-up.
  void restartApp();
}
