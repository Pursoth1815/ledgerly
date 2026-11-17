import '../platform/platform_api.g.dart';

/// Work that may run while the app is closed (ADR 0013).
///
/// A job runs in whichever engine holds the database: the app's own engine
/// or the headless one. A long job saves a checkpoint after each step and
/// checks [JobRun.stopRequested] between steps, so it can stop within
/// seconds and continue from the same point later.
abstract interface class BackgroundJob {
  /// The name Kotlin schedules it by, for example `self_test.long`.
  String get kind;

  Future<JobResult> run(JobRun run);
}

/// One run of a [BackgroundJob].
class JobRun {
  JobRun({required this.runId, required this.attempt});

  final String runId;

  /// How many earlier runs of the same work there were.
  final int attempt;

  bool _stopRequested = false;

  /// True once the run should save its progress and return
  /// [JobOutcome.stopped].
  bool get stopRequested => _stopRequested;

  void requestStop() => _stopRequested = true;
}
