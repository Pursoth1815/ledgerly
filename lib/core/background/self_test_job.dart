import '../database/app_database.dart';
import '../platform/platform_api.g.dart';
import 'background_job.dart';
import 'job_checkpoints_dao.dart';

/// The Phase 0B background self-test jobs, registered in profile builds only.
///
/// - `self_test.quick`: 3 one-second steps, about the work of saving one
///   SMS, to see whether it finishes while the phone is locked.
/// - `self_test.short`: 30 one-second steps, to check that a job runs while
///   the phone is locked (which also needs the Keystore, to open the
///   database).
/// - `self_test.long`: 900 one-second steps (15 minutes), to see when Android
///   stops a job and check that it continues from its checkpoint.
List<BackgroundJob> selfTestJobs(AppDatabase database) {
  final checkpoints = JobCheckpointsDao(database);
  return [
    SelfTestJob(kind: 'self_test.quick', steps: 3, checkpoints: checkpoints),
    SelfTestJob(kind: 'self_test.short', steps: 30, checkpoints: checkpoints),
    SelfTestJob(kind: 'self_test.long', steps: 900, checkpoints: checkpoints),
  ];
}

/// Counts [steps] steps of [stepDuration], writing a checkpoint to the
/// database after each one, as a backup writes one part at a time.
class SelfTestJob implements BackgroundJob {
  SelfTestJob({
    required this.kind,
    required this.steps,
    required this._checkpoints,
    this.stepDuration = const Duration(seconds: 1),
  });

  @override
  final String kind;
  final int steps;
  final Duration stepDuration;
  final JobCheckpointsDao _checkpoints;

  @override
  Future<JobResult> run(JobRun run) async {
    final saved = await _checkpoints.read(kind);
    var step = saved?.step ?? 0;
    final resumes = saved == null ? 0 : saved.resumes + 1;
    final firstStep = step;
    if (saved != null) await _checkpoints.save(kind, step: step, resumes: resumes);

    String detail() => 'step=$step/$steps resumes=$resumes this_run=${step - firstStep}';

    while (step < steps) {
      if (run.stopRequested) return JobResult(outcome: JobOutcome.stopped, detail: detail());
      await Future<void>.delayed(stepDuration);
      step++;
      await _checkpoints.save(kind, step: step, resumes: resumes);
    }
    await _checkpoints.clear(kind);
    return JobResult(outcome: JobOutcome.done, detail: detail());
  }
}
