part of '../scope.dart';

/// A job context with progress reporting for scope initialization.
///
/// [progress] is the scope's addition. Cancellation, child jobs and the cleanup
/// stack come from [JobContext]; read `ctx.job.isCancelled` to inspect the
/// cancellation without throwing. A body that asks the context nothing runs
/// to its end, and the scope releases what it returns after cancellation while
/// its teardown is still waiting.
///
/// See [JobContext.wait], [JobContext.join], [JobContext.uncancellable] and
/// [JobContext.unattended] for the waiting family. For an acquisition wrapped
/// in `wait` or `join`, supply `discard:` so a value that never reaches the
/// body still has someone to release it. Register cleanup of a value already
/// received through [JobContext.onDiscard] or [JobContext.onDispose].
abstract interface class ScopeInitContext implements JobContext {
  /// Reports what `buildOnProgress` will receive, after [JobContext.check].
  ///
  /// Throws [Cancelled] once the job is cancelled, without reporting the step.
  void progress(Object progress);
}

/// Drives a scope initialization with the lifecycle of a deferred [Job].
///
/// The body receives [ScopeInitContext], including its [ScopeInitContext.progress]
/// member. A scope starts its own job; a caller driving a dependency container
/// by hand starts one explicitly and awaits [value] or reads [done]:
///
/// ```dart
/// final job = ScopeInitJob((ctx) => deps.init(context, ctx));
/// job.start();
/// final dependencies = await job.value;
/// ```
///
/// [cancel] requests cancellation and waits for the body, children and cleanup
/// to finish. Do not await it from the body itself. A job cancelled before
/// [start] ends as [Cancelled] with `started: false` and never calls the body.
final class ScopeInitJob<T> extends JobBase<T> implements DeferredJob<T> {
  final Future<T> Function(ScopeInitContext ctx) _body;
  final void Function(Object progress)? _onProgress;

  // The scope settles a body failure through its model. Other errors from the
  // same running job have no outcome of their own and must still be reported.
  Object? _bodyError;

  // Finishing without observing, so a `Failed` nobody looked at still reaches
  // the zone by the kernel's own road. The observer waits on this to find out
  // whether the outcome ended up carrying the failure it stood aside for.
  Future<void> get _finished => whenDone;

  /// Creates an initialization that waits for [start] or [JobContext.run].
  ///
  /// [onProgress] receives the body's steps. The remaining options have the
  /// same meaning as on [Job.deferred].
  ScopeInitJob(
    this._body, {
    void Function(Object progress)? onProgress,
    super.key,
    super.describe,
    super.cancellable,
    super.observer,
  }) : _onProgress = onProgress;

  @override
  void start() => super.start();

  @protected
  @override
  JobContextBase createContext() => _ScopeInitContext(this);

  @protected
  @override
  Future<T> execute(JobContextBase ctx) async {
    try {
      return await _body(ctx as ScopeInitContext);
    } on Object catch (error) {
      _bodyError = error;
      rethrow;
    }
  }
}

final class _ScopeInitContext extends JobContextBase
    implements ScopeInitContext {
  final ScopeInitJob<Object?> _job;

  _ScopeInitContext(this._job) : super(_job);

  @override
  void progress(Object progress) {
    check();
    _job._onProgress?.call(progress);
  }
}

final class _ScopeInitObserver extends JobObserver {
  final ScopeObservable _scope;

  // What this initialization has already said out loud, by identity.
  //
  // A child job inherits the observer of the job that ran it, so one failure
  // can pass here twice: once as the child's, where nothing defers it and it
  // is named at once, and once as the parent's, where the body caught it from
  // `child.value` and the report is left to the outcome. The two passes look
  // alike from inside this method, and the flag they set is read as "nobody
  // has spoken about this yet" -- which was true only of the first.
  //
  // Identity, not equality: two failures that compare equal are still two.
  final _announced = Set<Object>.identity();

  _ScopeInitObserver(this._scope);

  @override
  void onError(Job<Object?> job, Object error, StackTrace stackTrace) {
    if (job is ScopeInitJob<Object?> &&
        identical(job._bodyError, error) &&
        !job.isCancelled) {
      // The outcome of this job is about to carry the failure, so nothing is
      // said here -- unless the error was already named on its way up from a
      // child, in which case it has an owner and a second report of it is what
      // the wave of 2026-09-07 existed to remove.
      if (_announced.contains(error)) {
        return;
      }

      // Standing aside is a promise that somebody else will speak, and the
      // outcome keeps it only while it stays a `Failed`. A cancellation
      // arriving while the cleanup unwinds takes the outcome over, and then
      // the failure has nobody: the kernel's own late report is for an outcome
      // nobody looked at, and a scope looks at every one of them. This used to
      // be the element's net, which meant it was spread under the one job the
      // element owns -- a child of that job fell straight through.
      unawaited(
        job._finished.then((_) {
          if (job.outcome is Failed || _announced.contains(error)) {
            return;
          }
          _report(error, stackTrace, ScopePhase.initializationCancellation);
        }),
      );
      return;
    }

    // The kernel hands this hook four kinds of error with no outcome to
    // carry them, and names none of them. What it does say is when: a job
    // that has already finished cannot be failing its initialization any
    // more, so what arrives then is work whose end nobody was left to hear
    // -- an action abandoned by `wait`, or something handed over with
    // `unattended`. Calling that an initialization failure points the reader
    // at the wrong half of the scope's life.
    final phase = switch (job) {
      _ when job.isFinished => ScopePhase.abandonedWait,
      _ when job.isCancelled => ScopePhase.initializationCancellation,
      _ => ScopePhase.initialization,
    };
    _report(error, stackTrace, phase);
  }

  /// Says it once, to both places, and remembers having said it.
  void _report(Object error, StackTrace stackTrace, ScopePhase phase) {
    _announced.add(error);
    notifyObserver(
      (observer) => observer.onError(_scope, phase, error, stackTrace),
    );

    // A cancellation stops with the observer, which is where the kernel
    // stops it too: "a cancellation is a decision somebody made, not a
    // failure, and none of them reaches the zone". Passing it on would put a
    // red line in the console for a decision, and fail the widget test of a
    // consumer who had no exception to take.
    if (error is Cancelled) {
      return;
    }

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'scopo',
      ),
    );
  }

  @override
  void onLog(Job<Object?> job, Object? message) => notifyObserver(
        (observer) => observer.onTrace(_scope, '$message'),
      );
}
