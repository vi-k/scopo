import 'dart:async';

import 'package:scopo/scopo.dart';

/// `target.debugLabel` without the trailing `(#hash)`.
///
/// The hash changes from run to run, so an expectation that compared it
/// verbatim would be comparing against a value nobody can predict. A `tag` is
/// left where it is: it is the half of a label the test chose itself, and the
/// only way to tell two scopes of the same type apart in the recording — a
/// parent from the child whose teardown it waits out, say.
String _label(ScopeObservable target) =>
    target.debugLabel.replaceFirst(RegExp(r'\(#[0-9a-f]+\)$'), '');

/// Records what the package reports, in order, as plain strings.
///
/// Strings, not objects: a test that compares the whole list at once catches
/// both a missing event and one too many, and the reason a comparison failed
/// is readable without a debugger.
final class RecordingObserver extends ScopeObserver {
  /// Every event so far, oldest first.
  final events = <String>[];

  /// The error of every [onTimeout], in order — the half the line for it
  /// leaves out.
  final timeouts = <TimeoutException>[];

  /// Whether [onTrace] is recorded too.
  final bool trace;

  /// Creates a recorder; pass `trace: true` to record traces as well.
  RecordingObserver({this.trace = false});

  @override
  void onInit(ScopeObservable target) => events.add('init ${_label(target)}');

  @override
  void onStepStarted(ScopeObservable target, String path) =>
      events.add('step ${_label(target)} $path');

  @override
  void onProgress(ScopeObservable target, Object? progress) =>
      events.add('progress ${_label(target)} $progress');

  @override
  void onReady(ScopeObservable target) => events.add('ready ${_label(target)}');

  @override
  void onCancelled(ScopeObservable target) =>
      events.add('cancelled ${_label(target)}');

  @override
  void onDispose(ScopeObservable target) =>
      events.add('dispose ${_label(target)}');

  @override
  void onDisposalStepStarted(ScopeObservable target, String path) =>
      events.add('disposal step ${_label(target)} $path');

  @override
  void onDisposalProgress(ScopeObservable target, String path) =>
      events.add('disposal progress ${_label(target)} $path');

  @override
  void onDisposed(ScopeObservable target) =>
      events.add('disposed ${_label(target)}');

  @override
  void onError(
    ScopeObservable target,
    ScopePhase phase,
    Object error,
    StackTrace? stackTrace,
  ) =>
      events.add('error ${_label(target)} ${phase.name} $error');

  // The error goes beside the line rather than into it: it repeats `what` in
  // prose and carries names with hashes in them, and every expectation over
  // [events] compares whole lists of strings. A test that is about the error
  // reads [timeouts].
  @override
  void onTimeout(
    ScopeObservable target,
    String what,
    TimeoutException error,
    StackTrace stackTrace,
  ) {
    events.add('timeout ${_label(target)} $what');
    timeouts.add(error);
  }

  @override
  void onTrace(ScopeObservable target, String message) {
    if (trace) {
      events.add('trace ${_label(target)} $message');
    }
  }
}
