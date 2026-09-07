// [ScopeConfig] is a namespace for the package-wide switches and has no
// instance members by design. The suppression is file-wide because analyzers
// disagree on where a documented declaration starts — some anchor this
// diagnostic at the dartdoc comment, some at the class name — and a
// single-line `ignore` then lands on the wrong side of it.
// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';

import 'package:flutter/foundation.dart';

part 'scope_observer.dart';
part 'scope_timeout.dart';

/// {@category debug}
abstract final class ScopeConfig {
  /// Where the package reports its lifecycle.
  ///
  /// `null` by default: the package says nothing until an observer is
  /// assigned. [reset] leaves it alone: it is an object rather than a switch,
  /// and it is usually the whole point of the run it was assigned for.
  static ScopeObserver? observer;

  /// Whether a notification is already running.
  static bool _notifying = false;

  /// Whether a `pauseAfterInitialization` is honoured at all.
  ///
  /// On by default. Set it to `false` to turn every such pause off at once —
  /// in a test suite, say, where a scope that holds its ready branch back only
  /// makes the run longer.
  static bool pauseAfterInitializationEnabled =
      _pauseAfterInitializationEnabled;

  /// Whether an expired wait is reported through [FlutterError.reportError].
  ///
  /// On by default. Set it to `false` in an application that has an [observer]
  /// of its own and reports expiries from there: an expiry arriving twice —
  /// once as an event, once as a Flutter error — is what makes one of them
  /// look like a second problem. The observer hears about the expiry either
  /// way, and hears it with the very `TimeoutException` the report would have
  /// carried, so nothing is lost by switching this off.
  ///
  /// Only the report goes. The wait still gives up on time, the scope still
  /// goes on as if it had succeeded, and the four callbacks of the scope —
  /// `onScopeKeyTimeout`, `onInitCancellationTimeout`, `onDisposeScopeTimeout`
  /// and `onWaitForChildrenTimeout` — are still called.
  static bool timeoutReportsEnabled = _timeoutReportsEnabled;

  /// Timeout for waiting for a `scopeKey` to be released.
  ///
  /// If `null`, then there is no timeout and the wait is unbounded.
  ///
  /// If zero, then the timeout expires immediately.
  ///
  /// [ScopeTimeout.none] says the same as `null` here, and is what a single
  /// scope writes to say it for itself.
  static Duration? defaultScopeKeyTimeout = _timeout;

  /// Timeout for waiting for scopes to be disposed of.
  ///
  /// If `null`, then there is no timeout and the wait is unbounded.
  ///
  /// If zero, then the timeout expires immediately.
  ///
  /// [ScopeTimeout.none] says the same as `null` here, and is what a single
  /// scope writes to say it for itself.
  static Duration? defaultWaitForChildrenTimeout = _timeout;

  /// Timeout for waiting for the asynchronous teardown of one scope.
  ///
  /// A teardown that never completes held the release that follows it, and
  /// with it the `scopeKey` of a scope that had already left the tree. When
  /// this expires, the expiry is reported and the release goes on without
  /// waiting for the teardown to finish.
  ///
  /// If `null`, then there is no timeout and the wait is unbounded.
  ///
  /// If zero, then the timeout expires immediately.
  ///
  /// [ScopeTimeout.none] says the same as `null` here, and is what a single
  /// scope writes to say it for itself.
  static Duration? defaultDisposeScopeTimeout = _timeout;

  /// Timeout for waiting for an initialization to be cancelled.
  ///
  /// A generator suspended on a future that never completes cannot be
  /// cancelled, and a teardown that waited for it with no limit never reached
  /// the release that follows. When this expires, the expiry is reported and
  /// the teardown goes on without the initialization.
  ///
  /// If `null`, then there is no timeout and the wait is unbounded.
  ///
  /// If zero, then the timeout expires immediately.
  ///
  /// This is the one timeout a single scope cannot remove for itself:
  /// `initCancellationTimeout` refuses [ScopeTimeout.none] with an assert, so
  /// an unbounded cancellation is a decision for the whole application and is
  /// made here — as `null`, or as the [ScopeTimeout.none] that means the same
  /// thing here as it does on the other three.
  static Duration? defaultInitCancellationTimeout = _timeout;

  /// The default every timeout above starts at.
  static const _timeout = Duration(seconds: 3);

  /// The default of [pauseAfterInitializationEnabled].
  static const _pauseAfterInitializationEnabled = true;

  /// The default of [timeoutReportsEnabled].
  static const _timeoutReportsEnabled = true;

  /// Puts every switch above back to its default.
  ///
  /// These are global and outlive the code that changed them, so a test that
  /// raises a timeout and forgets to put it back hands the next test a
  /// different package. Call this from a `tearDown`, or from a `setUp` — which
  /// also covers a test that failed before its own teardown ran.
  ///
  /// [observer] is left alone: it is an object rather than a switch, and it
  /// is usually the whole point of the run it was assigned for.
  static void reset() {
    pauseAfterInitializationEnabled = _pauseAfterInitializationEnabled;
    timeoutReportsEnabled = _timeoutReportsEnabled;
    defaultScopeKeyTimeout = _timeout;
    defaultWaitForChildrenTimeout = _timeout;
    defaultDisposeScopeTimeout = _timeout;
    defaultInitCancellationTimeout = _timeout;
  }
}

/// Tells the observer that a bounded wait ran out of time.
///
/// The other half of an expiry is [reportTimeout], and the two are separate
/// because they are not always sent from the same place: a wait for children
/// is recorded by the parent, which is the one point all three ways of asking
/// for that wait pass through, while the report belongs to whoever asked and
/// may be replaced by them. What is never conditional is this half — the
/// recording is what the package says about itself, and
/// [ScopeConfig.timeoutReportsEnabled] has nothing to say about it.
///
/// Not exported: the package notifies, an application observes.
void notifyTimeout(
  ScopeObservable target,
  String what,
  TimeoutException error,
  StackTrace stackTrace,
) =>
    notifyObserver(
      (observer) => observer.onTimeout(target, what, error, stackTrace),
    );

/// Reports an expired wait through [FlutterError.reportError].
///
/// Silent when the application switched these reports off — see
/// [ScopeConfig.timeoutReportsEnabled], which is the one switch this obeys —
/// and the reason every expiry of the package is reported from here rather
/// than from the four places that used to write this out for themselves.
///
/// Not exported: the package reports, an application decides what to do about
/// it.
void reportTimeout(TimeoutException error, StackTrace stackTrace) {
  if (!ScopeConfig.timeoutReportsEnabled) {
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

/// Calls [call] on [ScopeConfig.observer], guarded.
///
/// Not exported: the package notifies, an application observes.
///
/// The observer is consumer code called from a build, an initialization or a
/// teardown — the same three places a throwing logger used to take a scope
/// down from. A failure is reported through [FlutterError.reportError] and the
/// caller goes on. An observer that produces an event of its own — one that
/// builds a scope from a hook — would otherwise recurse without end, so the
/// second entry is refused and reported, once per refused call.
void notifyObserver(void Function(ScopeObserver observer) call) {
  final observer = ScopeConfig.observer;
  if (observer == null) {
    return;
  }

  if (ScopeConfig._notifying) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError(
          'A scope observer produced a scope event while it was being '
          'notified. The second notification is refused: it would not end.',
        ),
        library: 'scopo',
        context: ErrorDescription('while notifying a scope observer'),
      ),
    );

    return;
  }

  ScopeConfig._notifying = true;
  try {
    call(observer);
    // ignore: avoid_catching_errors
  } on Object catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'scopo',
        context: ErrorDescription('while notifying a scope observer'),
      ),
    );
  } finally {
    ScopeConfig._notifying = false;
  }
}
