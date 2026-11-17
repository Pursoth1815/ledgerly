import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/background/background_job.dart';
import 'package:loopd/core/background/job_checkpoints_dao.dart';
import 'package:loopd/core/background/self_test_job.dart';
import 'package:loopd/core/database/app_database.dart';
import 'package:loopd/core/platform/platform_api.g.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase database;
  late JobCheckpointsDao checkpoints;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    checkpoints = JobCheckpointsDao(database);
  });
  tearDown(() => database.close());

  SelfTestJob job({int steps = 5}) =>
      SelfTestJob(kind: 'self_test.unit', steps: steps, checkpoints: checkpoints, stepDuration: Duration.zero);

  test('a job that is not stopped finishes and clears its checkpoint', () async {
    final result = await job().run(JobRun(runId: 'a', attempt: 0));

    expect(result.outcome, JobOutcome.done);
    expect(result.detail, 'step=5/5 resumes=0 this_run=5');
    expect(await checkpoints.read('self_test.unit'), isNull);
  });

  test('a stopped job keeps its checkpoint and the next run continues from it', () async {
    final first = JobRun(runId: 'a', attempt: 0);
    final stopping = _StopAfter(first, steps: 2, checkpoints: checkpoints);
    final stopped = await job(steps: 10).run(stopping.run);

    expect(stopped.outcome, JobOutcome.stopped);
    final saved = await checkpoints.read('self_test.unit');
    expect(saved, isNotNull);
    expect(stopped.detail, startsWith('step=${saved!.step}/10 resumes=0'));
    expect(saved.step, inInclusiveRange(2, 9));

    final resumed = await job(steps: 10).run(JobRun(runId: 'a', attempt: 1));
    expect(resumed.outcome, JobOutcome.done);
    expect(resumed.detail, 'step=10/10 resumes=1 this_run=${10 - saved.step}');
  });

  test('the self-test jobs are the quick, the short and the long one', () {
    expect(selfTestJobs(database).map((job) => job.kind), ['self_test.quick', 'self_test.short', 'self_test.long']);
  });
}

/// Requests a stop once the job has saved [steps] checkpoints.
class _StopAfter {
  _StopAfter(this.run, {required int steps, required JobCheckpointsDao checkpoints}) {
    checkpoints.attachedDatabase.select(checkpoints.jobCheckpoints).watch().listen((rows) {
      if (rows.isNotEmpty && rows.first.step >= steps) run.requestStop();
    });
  }

  final JobRun run;
}
