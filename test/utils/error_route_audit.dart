import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

/// Which second channel an error reached, beside the observer.
enum SeenIn { flutterError, zone }

/// Records FlutterError reports and uncaught zone errors while a test runs,
/// and checks every announced route against them.
///
/// A route is a promise about the future: "this error goes to
/// `FlutterError` as well", "this one goes nowhere else". The only way to
/// keep such a promise honest is to watch where the error really went, in the
/// same test that reads the route -- otherwise the route and the fact drift
/// apart one path at a time, and the consumer who trusted the route gets a
/// double report or a lost one.
final class RouteAudit {
  final _seen = <(SeenIn, Object)>[];
  FlutterExceptionHandler? _previous;
  bool _installed = false;

  /// Swaps `FlutterError.onError` for a recorder, and keeps the old one.
  ///
  /// Call it from inside the test body: `testWidgets` puts its own handler in
  /// when the body starts, and one installed before that is replaced by it.
  /// The old handler comes back in [uninstall], which is also registered as a
  /// tear-down here, so a test that fails halfway still gives it back.
  void install() {
    assert(!_installed, 'The audit is already installed.');
    _previous = FlutterError.onError;
    FlutterError.onError = (details) =>
        _seen.add((SeenIn.flutterError, details.exception));
    _installed = true;
    addTearDown(uninstall);
  }

  /// Gives `FlutterError.onError` back; does nothing the second time.
  ///
  /// Call it before the expectations. While the recorder is in place a
  /// failing `expect` is reported through it and collected rather than
  /// raised, which leaves the run hanging instead of red.
  void uninstall() {
    if (!_installed) return;
    FlutterError.onError = _previous;
    _installed = false;
  }

  /// Records an uncaught error of the zone; feed it from the test's guard.
  void zoneError(Object error, StackTrace stackTrace) =>
      _seen.add((SeenIn.zone, error));

  /// Runs [body] in a guarded zone whose uncaught errors go to [zoneError].
  ///
  /// The returned future completes when [body] does, and with its error if it
  /// threw. `await runZonedGuarded(...)` would never come back from a body
  /// that threw -- the error goes to the guard and the awaited future stays
  /// open -- so the body is waited for through a completer of the caller's
  /// zone instead. Nothing inside [body] should `expect`: a failure there is
  /// an error of the guarded zone like any other.
  Future<void> runGuarded(Future<void> Function() body) {
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
      }, zoneError),
    );

    return done.future;
  }

  /// The errors that reached [channel], in order.
  List<Object> seenIn(SeenIn channel) => [
    for (final (seenIn, error) in _seen)
      if (seenIn == channel) error,
  ];

  /// Fails the test unless every entry of [routes] matches what was seen.
  ///
  /// `observer`, `cancellation` and `caller` must have reached neither
  /// channel; `flutterError` exactly one `FlutterError` report and no zone
  /// error; `zone` exactly one zone error and no report. An error is matched
  /// by identity, with itself or with the error a [ScopeDependencyException]
  /// carries -- the observer is often told the named failure while the report
  /// carries the bare one, or the other way round, and those are the same
  /// failure.
  ///
  /// Gives `FlutterError.onError` back first, for the reason [uninstall]
  /// gives.
  void verify(List<(String, ScopePhase, ScopeErrorRoute, Object)> routes) {
    uninstall();

    if (routes.isEmpty) {
      fail('No route was announced, so there is nothing to verify.');
    }

    final problems = <String>[];
    for (final (label, phase, route, error) in routes) {
      final reports = _count(SeenIn.flutterError, error);
      final zone = _count(SeenIn.zone, error);
      // Exhaustive on purpose: a route added later has to be given its rule
      // here before any test of it can pass.
      final (wantReports, wantZone) = switch (route) {
        ScopeErrorRoute.observer ||
        ScopeErrorRoute.caller ||
        ScopeErrorRoute.cancellation => (0, 0),
        ScopeErrorRoute.flutterError => (1, 0),
        ScopeErrorRoute.zone => (0, 1),
      };
      if (reports != wantReports || zone != wantZone) {
        problems.add(
          '$label ${phase.name} announced ${route.name} for "$error", but '
          'FlutterError saw it $reports time(s) (want $wantReports) and the '
          'zone $zone time(s) (want $wantZone)',
        );
      }
    }

    if (problems.isNotEmpty) {
      fail(problems.join('\n'));
    }
  }

  int _count(SeenIn channel, Object announced) => _seen
      .where((entry) => entry.$1 == channel && _same(announced, entry.$2))
      .length;

  static bool _same(Object announced, Object seen) =>
      identical(announced, seen) ||
      identical(_carried(announced), _carried(seen));

  static Object _carried(Object error) =>
      error is ScopeDependencyException ? error.error : error;
}
