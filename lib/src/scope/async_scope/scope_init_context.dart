part of '../scope.dart';

/// A job context with progress reporting for scope initialization.
///
/// [progress] is the scope's addition. Cancellation, child jobs and the cleanup
/// stack come from [JobContext]; read `ctx.job.isCancelled` to inspect the
/// cancellation without throwing. A body that asks the context nothing runs
/// to its end, and the scope releases what it returns after cancellation while
/// its teardown is still waiting.
///
/// See [JobContext.abandonable], [JobContext.join],
/// [JobContext.uncancellable] and [JobContext.unattended] for the waiting
/// family. For an acquisition wrapped in `abandonable` or `join`, supply
/// `discard:` so a value that never reaches the body still has someone to
/// release it. Register cleanup of a value already received through
/// [JobContext.onDiscard] or [JobContext.onDispose].
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

/// The scope asked for this cancellation itself, taking its job down.
///
/// What the settlement of an initialization asks of a `Cancelled` outcome is
/// whose cancellation it was, not which name the kernel gave it. A body may
/// give itself up with a reason of its own, and a later kernel may add
/// reasons nobody here has heard of; both end an initialization that never
/// became ready, which is a failure. Only the one the teardown asked for is
/// expected, and only that one is quiet -- so the teardown asks for it by
/// name.
final class _ScopeDisposalCancelReason extends CancelReason {
  const _ScopeDisposalCancelReason();

  @override
  String get name => 'scope disposal';
}

final class _ScopeInitObserver extends JobObserver with JobAnswerer {
  final ScopeObservable _scope;

  // What the scope observer has already been told, by identity.
  //
  // A child job inherits the observer of the job that ran it, so one failure
  // can pass here twice: once as the child's, where nothing defers it and it
  // is named at once, and once as the parent's, where the body caught it from
  // `child.value` and the report is left to the outcome. The two passes look
  // alike from inside this method, and the flag they set is read as "nobody
  // has spoken about this yet" -- which was true only of the first. The
  // settlement of the outcome asks the same question through [announced].
  //
  // Identity, not equality: two failures that compare equal are still two.
  final _announced = Set<Object>.identity();

  _ScopeInitObserver(this._scope);

  /// Whether the scope observer has already been told about [error].
  bool announced(Object error) => _announced.contains(error);

  // The two channels split where the kernel splits its own two hooks. This
  // one tells the scope observer, which is a log of what failed and where,
  // and hears everything -- a child failure the body went on to handle
  // included, since the child did fail. `FlutterError` is for the failures
  // nobody else can be handed, and which those are is decided by the kernel
  // in [onUnanswered]: the outcomes somebody read, the children a body
  // caught and the errors the app's `Job.isCancellationError` calls
  // cancellations are all settled there before it asks.
  @override
  void onError(Job<Object?> job, Object error, StackTrace stackTrace) {
    if (job is ScopeInitJob<Object?> &&
        identical(job._bodyError, error) &&
        !job.isCancelled) {
      // The outcome of this job is about to carry the failure, and the
      // element tells the observer when it settles it. A cancellation arriving
      // while the cleanup unwinds can take the outcome over, and then the
      // failure has nobody -- which is exactly when the kernel hands it to
      // [onUnanswered], where it is told after all.
      return;
    }

    // The kernel names none of the errors it hands this hook -- a child's
    // failure, or one of the four kinds with no outcome to carry them. What
    // it does say is when: a job that has already finished cannot be failing
    // its initialization any more, so what arrives then is work whose end
    // nobody was left to hear -- an action abandoned by `abandonable`, or
    // something handed over with `unattended`. Calling that an initialization
    // failure points the reader at the wrong half of the scope's life.
    final phase = switch (job) {
      _ when job.isFinished => ScopePhase.abandonedWait,
      _ when job.isCancelled => ScopePhase.initializationCancellation,
      _ => ScopePhase.initialization,
    };
    _announce(error, stackTrace, phase);
  }

  // The kernel asks here once nothing else will carry an error: no outcome
  // that somebody read holds it, no body caught it, and the app's filter did
  // not call it a cancellation. A `Cancelled` never comes here -- "a
  // cancellation is a decision somebody made, not a failure, and none of
  // them reaches the zone" -- so there is no red line for a decision either.
  //
  // `FlutterError` takes the place of the zone, which is where `super` would
  // send it. The scope observer has normally heard the error in `onError`
  // already; the one exception is the body failure [onError] stood aside
  // for, whose outcome a cancellation took over during the cleanup.
  @override
  void onUnanswered(Job<Object?> job, Object error, StackTrace stackTrace) {
    if (!_announced.contains(error)) {
      _announce(error, stackTrace, ScopePhase.initializationCancellation);
    }

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'scopo',
      ),
    );
  }

  /// Tells the scope observer, and remembers having told it.
  void _announce(Object error, StackTrace stackTrace, ScopePhase phase) {
    _announced.add(error);
    notifyObserver(
      (observer) => observer.onError(_scope, phase, error, stackTrace),
    );
  }

  @override
  void onLog(Job<Object?> job, Object? message) => notifyObserver(
        (observer) => observer.onTrace(_scope, '$message'),
      );
}
