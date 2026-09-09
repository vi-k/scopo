part of '../scope.dart';

/// Owns the `scopeKey` queues of its subtree, and is the wait root for the
/// scopes in it that have no parent scope above them.
///
/// A scope with a `scopeKey` waits on the queue owned by the nearest
/// [AsyncScopeCoordinator] above it, so two scopes under different
/// coordinators never wait for one another even when their `scopeKey`s are
/// equal. Independently, a scope also registers with the nearest
/// [AsyncScopeParent] above it — a parent scope if there is one, or this
/// coordinator otherwise — so that something waits for it to finish disposing
/// of itself; [waitForChildren] waits for exactly those scopes.
///
/// {@category AsyncScope}
final class AsyncScopeCoordinator extends ScopeWidgetCore<AsyncScopeCoordinator,
    _AsyncScopeCoordinatorElement> {
  /// Creates a coordinator over [child].
  const AsyncScopeCoordinator({
    super.key,
    super.tag,
    required super.child,
  });

  @override
  // ignore: library_private_types_in_public_api
  _AsyncScopeCoordinatorElement createScopeElement() =>
      _AsyncScopeCoordinatorElement(this);

  /// The nearest coordinator above [context], the one whose queues a scope
  /// with a `scopeKey` takes its place in.
  ///
  /// Each coordinator keeps its own keys: scopes under different coordinators
  /// never wait for one another, even when their keys are equal.
  ///
  /// A scope resolves this *before* it creates its [AccessEntry], so the one
  /// failure that can happen while the entry does not yet exist stays where
  /// there is nothing to release.
  static _AsyncScopeCoordinatorElement _elementOf(BuildContext context) =>
      ScopeWidgetCore.maybeOf<AsyncScopeCoordinator,
          _AsyncScopeCoordinatorElement>(
        context,
        listen: false,
      ) ??
      (throw FlutterError(
        'No `$AsyncScopeCoordinator`.\n'
        'The `$AsyncScopeCoordinator` is missing in the context. Add it to'
        ' the widget tree so that all your scopes that need it can access it.'
        ' The most universal solution is to place it above `$MaterialApp`.'
        ' A scope with a `scopeKey` needs it to be coordinated with the other'
        ' scopes that share the key.',
      ));

  /// Waits for the scopes registered with the nearest coordinator at the time
  /// of the call.
  ///
  /// These are the scopes that have no parent scope above them; a scope with a
  /// parent scope is awaited by that parent instead. A scope that registers
  /// while the wait is already running is not awaited by it, and is still
  /// registered once it is over.
  ///
  /// [timeout] defaults to [ScopeConfig.defaultWaitForChildrenTimeout], the
  /// same default the scopes themselves use; pass a [Duration] to override it
  /// for this call only. An expiry is not fatal: the awaited scopes that never
  /// finished are dropped and the future completes normally, so a scope that
  /// never finishes disposing of itself degrades into a delay instead of a
  /// deadlock. Pass [ScopeTimeout.none] to remove the limit for this call
  /// alone, or set [ScopeConfig.defaultWaitForChildrenTimeout] to `null` to
  /// remove it everywhere.
  ///
  /// [onTimeout] defaults to reporting the [TimeoutException] through
  /// [FlutterError.reportError] — unless
  /// [ScopeConfig.timeoutReportsEnabled] is off, which is the one switch that
  /// silences that half for the whole application. The observer hears the
  /// expiry either way. Pass a callback to handle it instead.
  static Future<void> waitForChildren(
    BuildContext context, {
    Duration? timeout,
    void Function(TimeoutException error, StackTrace stackTrace)? onTimeout,
  }) =>
      _elementOf(context).waitForChildren(
        // Resolved by `waitForChildren` below, and only there: resolving twice
        // turns a `ScopeTimeout.none` into the `null` that means "take the
        // default" on the way in.
        timeout: timeout,
        // Passed on as it stands, `null` and all. The default report of
        // `AsyncScopeParent.waitForChildren` puts `reportName` of this element
        // in front of the registry's message, and that is the very expression a
        // copy here used to write out -- so the line was the same, while the
        // report itself sat outside the one place the package reports an expiry
        // from, and `ScopeConfig.timeoutReportsEnabled` would have missed it.
        onTimeout: onTimeout,
      );
}

final class _AsyncScopeCoordinatorElement extends ScopeWidgetElementBase<
    AsyncScopeCoordinator,
    _AsyncScopeCoordinatorElement> with AsyncScopeParent {
  _AsyncScopeCoordinatorElement(super.widget);

  final _queues = KeyedAccessQueues();

  /// The same name [AsyncScopeCoordinator.waitForChildren] builds for itself.
  @override
  String get reportName => widget.toStringShort(showHashCode: true);

  /// The label taken while there was still a widget to take it from.
  ///
  /// A wait for children outlives the tree in the very cases it exists for,
  /// and this element is the second one that can be asked its name after it
  /// has left -- `AsyncScopeElementBase.debugLabel` keeps a copy for exactly
  /// that and says why. The observer reads the label at the expiry, not at
  /// the start: asking an unmounted element raised a `_TypeError` inside the
  /// observer's own hook, the guard then named the observer as the thing that
  /// had failed, and the expiry itself reached nobody.
  @override
  String get debugLabel => _debugLabel ?? super.debugLabel;
  String? _debugLabel;

  @override
  void unmount() {
    // Before `super`, which is where the framework lets go of the widget --
    // and inside a guard, because `super.debugLabel` interpolates the `tag`,
    // an object of the application's. The caller here is
    // `BuildOwner._inactiveElements._unmountAll()`, which walks the whole
    // batch with no boundary around any one element: a raise on this line
    // therefore left every element behind this one -- everything shallower in
    // the tree, scopes included -- mounted for good, with no teardown at all.
    // A label that cannot be built is a diagnostic that failed, and this
    // method has a promise to keep behind it.
    try {
      _debugLabel = super.debugLabel;
      // ignore: avoid_catching_errors
    } on Object catch (error, stackTrace) {
      _reportFailure(
        error,
        stackTrace,
        'while reading the label of a scope coordinator',
      );
    }
    super.unmount();
  }

  @override
  Widget buildChild() => widget.child;

  Future<void> enter(
    Object key,
    AccessEntry entry, {
    Duration? timeout,
    void Function(TimeoutException error, StackTrace stackTrace)? onTimeout,
  }) =>
      _queues.enter(key, entry, timeout: timeout, onTimeout: onTimeout);
}
