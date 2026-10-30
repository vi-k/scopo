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

  // Identifies the body failure carried by the outcome. For the root and
  // group-arm jobs, their owners report it when they settle that outcome.
  Object? _bodyError;
  StackTrace? _bodyStackTrace;

  // _ScopeDependencyConcurrent marks its arms: it carries the first failure
  // upwards and announces the others. The observer leaves those reports to
  // the group rather than announcing the same failures from the arm jobs.
  bool _failureCarriedByOwner = false;

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
    } on Object catch (error, stackTrace) {
      _bodyError = error;
      _bodyStackTrace = stackTrace;
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
  // Bound before start: the job whose outcome the element settles.
  late final ScopeInitJob<void> _rootJob;

  // What the scope observer has already been told, by identity.
  //
  // Children inherit the observer, so one failure can pass through several
  // jobs before the root settles. Both kernel hooks and settlement use
  // [_announce], keeping the first report and its phase even if the same
  // error arrives later from work nobody waited for.
  //
  // Identity, not equality: two failures that compare equal are still two.
  final _announced = Set<Object>.identity();

  // What the scope observer was told goes nowhere else, while there was an
  // observer to tell. The route is final when it is announced, so an answer
  // the kernel asks for afterwards -- for a child failure nobody read, told
  // as [JobErrorAnswer.later] -- does not send the same error to
  // `FlutterError` after all: a crash reporter that forwards
  // [ScopeErrorRoute.observer] has it already. Without an observer nobody has
  // heard it, and the red line is all there is.
  final _observerOnly = Set<Object>.identity();

  _ScopeInitObserver(this._scope);

  // The two channels split where the kernel splits its own two hooks. This
  // one tells the scope observer, which is a log of what failed and where,
  // and hears everything -- a child failure the body went on to handle
  // included, since the child did fail. `FlutterError` is for the failures
  // nobody else can be handed, and which those are is decided by the kernel
  // in [onUnanswered]: the outcomes somebody read, the children a body
  // caught and the errors the app's `Job.isCancellationError` calls
  // cancellations are all settled there before it asks.
  //
  // [answer] is the kernel saying what it does with the error next, and the
  // route follows from it. [JobErrorAnswer.answered]: it asks [onUnanswered]
  // -- right away for cleanup, callbacks and late work, at the end for the
  // body of a job already cancelled -- so the route is `FlutterError`. The
  // one leftover is the kernel's to set: for the body of a cancelled job, a
  // `Job.ignoreFailure()` called after this hook takes that answer away, and
  // then the route says `FlutterError` and no report comes.
  // [JobErrorAnswer.cancellation]: nobody reports it, the app's
  // `Job.isCancellationError` included. [JobErrorAnswer.later]: the outcome
  // may still be read, so this call is the only one that may tell the
  // observer, and an answer that comes afterwards is kept out of
  // `FlutterError` -- see [_observerOnly]. [JobErrorAnswer.never]: nothing
  // else will hear it.
  @override
  void onError(
    Job<Object?> job,
    Object error,
    StackTrace stackTrace, {
    required JobErrorAnswer answer,
  }) {
    // The object is remembered as heard by the observer alone, but the kernel
    // is about to ask about it again: a cleanup failure, a callback, late
    // work. That may be the same failure thrown again or a second failure
    // that shares a `const` object, and identity cannot tell which. A
    // duplicate report is better than a lost one, so the ask is answered.
    // Before the stand-aside below: the body may have thrown this very object.
    if (answer == JobErrorAnswer.answered) _observerOnly.remove(error);

    if (job is ScopeInitJob<Object?> &&
        (identical(job, _rootJob) || job._failureCarriedByOwner) &&
        identical(job._bodyError, error) &&
        !job.isCancelled) {
      // The outcome of this job is about to carry the failure, and whoever
      // settles it -- the element for its root job, the group for an arm --
      // tells the observer then. Any other job's outcome is settled by
      // nobody here, so a child of the caller's own is told at once. A
      // cancellation arriving while the cleanup unwinds can take the outcome
      // over, and then the failure has nobody -- which is when the kernel
      // hands it to [onUnanswered], where it is told after all. Unless the
      // app's `Job.isCancellationError` names it: then the kernel asks
      // nobody, this hook is not called again, and the element tells the
      // observer once the outcome is settled -- see
      // [_announceNamedBodyFailure].
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
    // No `default`: a value the kernel adds has to be given its route here
    // before the package builds.
    final route = error is Cancelled
        ? ScopeErrorRoute.cancellation
        : switch (answer) {
            JobErrorAnswer.cancellation => ScopeErrorRoute.cancellation,
            JobErrorAnswer.answered => ScopeErrorRoute.flutterError,
            JobErrorAnswer.later => ScopeErrorRoute.observer,
            JobErrorAnswer.never => ScopeErrorRoute.observer,
          };
    _announce(error, stackTrace, phase, route);
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
  // for, whose outcome a cancellation took over during the cleanup, and that
  // one is told here with the route it takes. An error the observer was told
  // goes nowhere else stays there.
  @override
  void onUnanswered(Job<Object?> job, Object error, StackTrace stackTrace) {
    _announce(
      error,
      stackTrace,
      ScopePhase.initializationCancellation,
      ScopeErrorRoute.flutterError,
    );
    if (_observerOnly.contains(error)) return;

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'scopo',
      ),
    );
  }

  /// Tells the observer of a body failure of [job] that the cancellation
  /// took the outcome from and the app's `Job.isCancellationError` names.
  ///
  /// [onError] stood aside for it, and the kernel hands such a failure to
  /// nobody, [onUnanswered] included. It did happen, before the cancellation,
  /// so the observer hears of it, with the route the app chose for it.
  /// A failure the filter does not name has reached [onUnanswered] by the
  /// time the outcome is settled, and [_announce] keeps it from being told
  /// twice; a `Cancelled` the body threw is the cancellation itself.
  void _announceNamedBodyFailure(ScopeInitJob<Object?> job) {
    final error = job._bodyError;
    if (error == null || error is Cancelled || _announced.contains(error)) {
      return;
    }

    bool named;
    try {
      named = Job.isCancellationError?.call(error) ?? false;
      // ignore: avoid_catching_errors
    } on Object {
      // The kernel asked the same filter and has dealt with its failure.
      named = false;
    }
    if (!named) return;

    _announce(
      error,
      job._bodyStackTrace ?? StackTrace.empty,
      ScopePhase.initializationCancellation,
      ScopeErrorRoute.cancellation,
    );
  }

  /// Tells the scope observer, and remembers having told it.
  ///
  /// [route] is final: an error the observer heard as
  /// [ScopeErrorRoute.observer] is remembered in [_observerOnly], and
  /// [onUnanswered] keeps it out of `FlutterError`. Heard, not only sent: an
  /// observer whose hook threw, or whose call was refused as recursive, has
  /// heard nothing, and the error is reported as if there were none.
  void _announce(
    Object error,
    StackTrace stackTrace,
    ScopePhase phase,
    ScopeErrorRoute route,
  ) {
    if (!_announced.add(error)) return;
    final heard = notifyObserver(
      (observer) => observer.onError(_scope, phase, route, error, stackTrace),
    );
    if (heard && route == ScopeErrorRoute.observer) _observerOnly.add(error);
  }

  @override
  void onLog(Job<Object?> job, Object? message) =>
      notifyObserver((observer) => observer.onTrace(_scope, '$message'));
}
