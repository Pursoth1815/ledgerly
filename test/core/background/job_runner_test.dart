import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/background/background_job.dart';
import 'package:loopd/core/background/job_runner.dart';
import 'package:loopd/core/platform/platform_api.g.dart';

void main() {
  test('an unknown job kind fails without running anything', () async {
    final result = await JobRunner([]).runJob('run-1', 'nothing.here', 0);

    expect(result.outcome, JobOutcome.failed);
    expect(result.detail, 'reason=unknown_kind');
  });

  test('a job that throws fails with its error type only', () async {
    final runner = JobRunner([_FakeJob('boom', (_) => throw StateError('secret text'))]);

    final result = await runner.runJob('run-1', 'boom', 0);

    expect(result.outcome, JobOutcome.failed);
    expect(result.detail, 'error=StateError');
  });

  test('stopJob reaches the running job, which then reports stopped', () async {
    final started = Completer<void>();
    final runner = JobRunner([
      _FakeJob('wait', (run) async {
        started.complete();
        while (!run.stopRequested) {
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        return JobResult(outcome: JobOutcome.stopped, detail: 'attempt=${run.attempt}');
      }),
    ]);

    final result = runner.runJob('run-1', 'wait', 2);
    await started.future;
    runner.stopJob('run-1');

    expect((await result).outcome, JobOutcome.stopped);
    expect((await result).detail, 'attempt=2');
  });

  test('the same run cannot start twice at once', () async {
    final release = Completer<JobResult>();
    final runner = JobRunner([_FakeJob('slow', (_) => release.future)]);

    final first = runner.runJob('run-1', 'slow', 0);
    final second = await runner.runJob('run-1', 'slow', 0);
    release.complete(JobResult(outcome: JobOutcome.done, detail: ''));

    expect(second.detail, 'reason=already_running');
    expect((await first).outcome, JobOutcome.done);
  });
}

class _FakeJob implements BackgroundJob {
  _FakeJob(this.kind, this._body);

  @override
  final String kind;
  final Future<JobResult> Function(JobRun run) _body;

  @override
  Future<JobResult> run(JobRun run) => _body(run);
}
