import 'package:logging/logging.dart';

import '../platform/platform_api.g.dart';
import 'background_job.dart';

final _log = Logger('core.background');

/// Runs the jobs Kotlin asks for (ADR 0013). Set up in every engine that
/// writes the database, with `BackgroundJobApi.setUp(runner)`.
class JobRunner implements BackgroundJobApi {
  JobRunner(Iterable<BackgroundJob> jobs) : _jobs = {for (final job in jobs) job.kind: job};

  final Map<String, BackgroundJob> _jobs;
  final Map<String, JobRun> _running = {};

  @override
  Future<JobResult> runJob(String runId, String kind, int attempt) async {
    final job = _jobs[kind];
    if (job == null) {
      _log.warning('job_unknown kind=$kind');
      return JobResult(outcome: JobOutcome.failed, detail: 'reason=unknown_kind');
    }
    if (_running.containsKey(runId)) {
      return JobResult(outcome: JobOutcome.failed, detail: 'reason=already_running');
    }
    final run = JobRun(runId: runId, attempt: attempt);
    _running[runId] = run;
    _log.info('job_started kind=$kind attempt=$attempt');
    try {
      final result = await job.run(run);
      _log.info('job_ended kind=$kind outcome=${result.outcome.name}');
      return result;
    } on Object catch (error) {
      _log.severe('job_failed kind=$kind', error);
      return JobResult(outcome: JobOutcome.failed, detail: 'error=${error.runtimeType}');
    } finally {
      _running.remove(runId);
    }
  }

  @override
  void stopJob(String runId) => _running[runId]?.requestStop();
}
