import 'dart:async';

/// Runs [body] in a guarded zone whose uncaught errors go to [onError].
///
/// The returned future completes when [body] does, and with its error if it
/// threw. `await runZonedGuarded(...)` would never come back from a body that
/// threw -- the error belongs to the guarded zone, so it goes to the guard and
/// the awaited future stays open until the test times out, without naming the
/// failure -- so the body is waited for through a completer of the caller's
/// zone instead. Errors of futures the body discards still reach [onError].
Future<void> runGuarded(
  Future<void> Function() body,
  void Function(Object error, StackTrace stackTrace) onError,
) {
  final done = Completer<void>();
  unawaited(
    runZonedGuarded(() async {
      try {
        await body();
        done.complete();
        // ignore: avoid_catching_errors
      } on Object catch (error, stackTrace) {
        done.completeError(error, stackTrace);
      }
    }, onError),
  );

  return done.future;
}
