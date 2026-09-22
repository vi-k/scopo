import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

import 'utils/observer.dart';
import 'utils/settle.dart';

/// The limit every scope here is given for the cancellation it cannot win.
///
/// Short enough for the teardown to give up while the test is still pumping,
/// and long enough not to expire before the element is even off the tree.
const _limit = Duration(milliseconds: 50);

void main() {
  late RecordingObserver observer;
  late List<FlutterErrorDetails> reported;
  late void Function(FlutterErrorDetails details)? previousOnError;

  setUp(() {
    observer = RecordingObserver();
    ScopeConfig.observer = observer;
    reported = <FlutterErrorDetails>[];
  });

  tearDown(() {
    ScopeConfig.observer = null;
  });

  /// Collects what the package reports instead of letting it end the test.
  ///
  /// Every test here provokes an expiry, and an expiry goes out through
  /// `FlutterError.reportError`. Installed from inside the test body rather
  /// than from `setUp`: `testWidgets` puts its own handler in when the body
  /// starts, and one installed before that is replaced by it.
  void collect() {
    previousOnError = FlutterError.onError;
    FlutterError.onError = reported.add;
    addTearDown(() => FlutterError.onError = previousOnError);
  }

  /// Puts the handler back, before the expectations run.
  ///
  /// While it is in place a failing `expect` is collected rather than raised,
  /// which leaves the run hanging instead of red.
  void stopCollecting() => FlutterError.onError = previousOnError;

  /// Runs the tree down to the end of the teardown it gave up on.
  ///
  /// Returns once the scope has announced that it is disposed of -- the last
  /// thing the teardown does, and the point after which everything the body
  /// still holds is on its own.
  Future<void> abandon(WidgetTester tester, Widget scope) async {
    await tester.pumpWidget(
      Directionality(textDirection: TextDirection.ltr, child: scope),
    );
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await settle(
      tester,
      until: () => observer.events.any((event) => event.startsWith('disposed')),
    );
  }

  group('a body that comes back after the teardown gave up', () {
    // The half of the promise that needs no widget at all: a container is an
    // object the body built, and releasing it is calling two of its methods.
    testWidgets('Scope releases the container it built', (tester) async {
      collect();

      final gate = Completer<void>();
      final released = <String>[];

      await abandon(tester, _Full(gate: gate, released: released));

      expect(released, isEmpty, reason: 'the body is still on the gate');

      gate.complete();
      await settle(tester, until: () => released.length == 2);

      stopCollecting();
      expect(
        released,
        ['unmount', 'dispose'],
        reason: 'the container arrived late and was still let go of, in order',
      );
      expect(
        reported.map((details) => details.exception),
        [isA<TimeoutException>()],
        reason: 'the expiry, and nothing else',
      );
    });

    // The widget is the only way to a release for this family, and the
    // teardown used to have given it back by now.
    testWidgets('AsyncScope calls disposeScope', (tester) async {
      collect();

      final gate = Completer<void>();
      final released = <String>[];

      await abandon(tester, _Async(gate: gate, released: released));

      expect(released, isEmpty, reason: 'the body is still on the gate');

      gate.complete();
      await settle(tester, until: () => released.isNotEmpty);

      stopCollecting();
      expect(released, ['dispose']);
      expect(
        reported.map((details) => details.exception),
        [isA<TimeoutException>()],
      );
    });

    testWidgets('AsyncDataScope hands the value to disposeData',
        (tester) async {
      collect();

      final gate = Completer<void>();
      final released = <String>[];
      final database = _Database('main');

      await abandon(
        tester,
        _Data(gate: gate, released: released, database: database),
      );

      expect(released, isEmpty, reason: 'the body is still on the gate');

      gate.complete();
      await settle(tester, until: () => released.isNotEmpty);

      stopCollecting();
      expect(
        released,
        ['main'],
        reason: 'the value the body built too late, and no other',
      );
      expect(database.disposed, isTrue);
    });

    // The control: this family already released on every path, with a release
    // of its own written for exactly this. It must go on doing it.
    testWidgets('AsyncControllerScope releases the controller', (tester) async {
      collect();

      final gate = Completer<void>();
      final released = <String>[];

      await abandon(tester, _Controlled(gate: gate, released: released));

      gate.complete();
      await settle(tester, until: () => released.isNotEmpty);

      stopCollecting();
      expect(released, ['controller']);
    });

    // A late release has no caller to be raised at: the teardown is over and
    // the outcome of the body goes nowhere. Both roads out, then -- the
    // observer and `FlutterError` -- and the expiry is still reported once,
    // because an expiry and a release that failed are two different events.
    testWidgets('a release that fails is reported and does not stop the rest',
        (tester) async {
      collect();

      final gate = Completer<void>();
      final released = <String>[];

      await abandon(
        tester,
        _Full(gate: gate, released: released, failOnUnmount: true),
      );

      gate.complete();
      await settle(tester, until: () => released.isNotEmpty);

      stopCollecting();
      expect(
        released,
        ['dispose'],
        reason: 'the failure of one half did not take the other with it',
      );
      expect(
        reported.map((details) => details.exception),
        [
          isA<TimeoutException>(),
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'unmount failed',
          ),
        ],
        reason: 'the expiry once, and the failed release after it',
      );
      expect(
        observer.events.last,
        'error _Full initializationCancellation Bad state: unmount failed',
        reason: 'and the observer heard it too, as the neighbours arrange',
      );
    });

    // The same question of the family whose release is not caught at all: the
    // kernel names what the cleanup threw, and the scope passes it on.
    testWidgets('a disposeScope that fails late is reported the same way',
        (tester) async {
      collect();

      final gate = Completer<void>();
      final released = <String>[];

      await abandon(
        tester,
        _Async(gate: gate, released: released, failOnDispose: true),
      );

      gate.complete();
      await settle(tester, until: () => released.isNotEmpty);

      stopCollecting();
      expect(
        reported.map((details) => details.exception),
        [
          isA<TimeoutException>(),
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'late dispose failed',
          ),
        ],
      );
      expect(
        observer.events.last,
        'error _Async initializationCancellation Bad state: late dispose '
        'failed',
      );
    });

    // What the whole of stage two rests on, asked directly: the element keeps
    // the widget while the job it gave up on is still running, and gives it
    // back when the job ends.
    testWidgets('the widget is held until the job ends, and no longer',
        (tester) async {
      collect();

      final gate = Completer<void>();
      final released = <String>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _Async(gate: gate, released: released),
        ),
      );
      await tester.pump();

      final element = tester.element<Element>(find.byType(_Async))
          as AsyncScopeContext<_Async>;

      await tester.pumpWidget(const SizedBox.shrink());
      await settle(
        tester,
        until: () =>
            observer.events.any((event) => event.startsWith('disposed')),
      );

      // Early, and not at the end as elsewhere: the two expectations below
      // are about the widget, and a raise from the first one while the
      // handler is in place hangs the runner instead of reddening it. The
      // expiry is already reported by now, and nothing else is expected.
      stopCollecting();

      expect(
        element.widget,
        isA<_Async>(),
        reason: 'the abandoned body still has a release to reach',
      );

      gate.complete();
      await settle(tester, until: () => released.isNotEmpty);

      expect(
        () => element.widget,
        throwsA(isA<TypeError>()),
        reason: 'the job is over, so the widget belongs to the framework again',
      );
    });

    // Nothing to release, and that is the answer rather than a gap: the state
    // of a lite scope is created by the ready branch, which an abandoned
    // initialization never reaches.
    testWidgets('LiteScope has nothing of its own to release', (tester) async {
      collect();

      final gate = Completer<void>();
      final released = <String>[];

      await abandon(tester, _Lite(gate: gate, released: released));

      gate.complete();
      await settle(tester, until: () => released.isNotEmpty);

      stopCollecting();
      expect(released, isEmpty);
      expect(
        reported.map((details) => details.exception),
        [isA<TimeoutException>()],
        reason: 'the expiry, and no failure behind it',
      );
    });
  });
}

/// A full scope whose container is built after the teardown has finished.
final class _Full extends Scope<_Full, _Deps, _FullState> {
  final Completer<void> gate;
  final List<String> released;
  final bool failOnUnmount;

  const _Full({
    required this.gate,
    required this.released,
    this.failOnUnmount = false,
  }) : super(initCancellationTimeout: _limit);

  @override
  Future<_Deps> initDependencies(BuildContext context, ScopeInitContext ctx) =>
      gate.future.then(
        (_) => _Deps(released: released, failOnUnmount: failOnUnmount),
      );

  @override
  Widget buildOnProgress(BuildContext context, Object? progress) =>
      const SizedBox.shrink();

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) =>
      const SizedBox.shrink();

  @override
  _FullState createState() => _FullState();
}

final class _FullState extends ScopeState<_Full, _Deps, _FullState> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

final class _Deps implements ScopeDependencies {
  final List<String> released;
  final bool failOnUnmount;

  _Deps({required this.released, required this.failOnUnmount});

  @override
  void onUnmount() {
    if (failOnUnmount) {
      throw StateError('unmount failed');
    }

    released.add('unmount');
  }

  @override
  FutureOr<void> dispose() {
    released.add('dispose');
  }
}

/// An asynchronous scope whose body returns after the teardown has finished.
final class _Async extends AsyncScopeBase<_Async> {
  final Completer<void> gate;
  final List<String> released;
  final bool failOnDispose;

  const _Async({
    required this.gate,
    required this.released,
    this.failOnDispose = false,
  }) : super(initCancellationTimeout: _limit);

  @override
  Future<void> initScope(BuildContext context, ScopeInitContext ctx) =>
      gate.future;

  @override
  FutureOr<void> disposeScope() {
    released.add('dispose');
    if (failOnDispose) {
      throw StateError('late dispose failed');
    }
  }

  @override
  Widget buildOnProgress(BuildContext context, Object? progress) =>
      const SizedBox.shrink();

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) =>
      const SizedBox.shrink();

  @override
  Widget buildOnReady(BuildContext context) => const SizedBox.shrink();
}

/// Something worth not losing.
final class _Database {
  final String name;
  bool disposed = false;

  _Database(this.name);
}

/// A value-producing scope whose value arrives after the teardown has ended.
final class _Data extends AsyncDataScopeBase<_Data, _Database> {
  final Completer<void> gate;
  final List<String> released;
  final _Database database;

  const _Data({
    required this.gate,
    required this.released,
    required this.database,
  }) : super(initCancellationTimeout: _limit);

  @override
  Future<_Database> initData(BuildContext context, ScopeInitContext ctx) =>
      gate.future.then((_) => database);

  @override
  FutureOr<void> disposeData(_Database data) {
    data.disposed = true;
    released.add(data.name);
  }

  @override
  Widget buildOnProgress(BuildContext context, Object? progress) =>
      const SizedBox.shrink();

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) =>
      const SizedBox.shrink();

  @override
  Widget buildOnReady(BuildContext context, _Database data) =>
      const SizedBox.shrink();
}

/// A controller built after the teardown has finished.
final class _Controller extends ScopeController {
  final Completer<void> gate;
  final List<String> released;

  _Controller({required this.gate, required this.released});

  @override
  Future<void> init() => gate.future;

  @override
  FutureOr<void> dispose() {
    released.add('controller');
  }
}

final class _Controlled
    extends AsyncControllerScopeBase<_Controlled, _Controller> {
  final Completer<void> gate;
  final List<String> released;

  const _Controlled({required this.gate, required this.released})
      : super(initCancellationTimeout: _limit);

  @override
  _Controller createController(BuildContext context) =>
      _Controller(gate: gate, released: released);

  @override
  Widget buildOnProgress(BuildContext context) => const SizedBox.shrink();

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) =>
      const SizedBox.shrink();

  @override
  Widget buildOnReady(BuildContext context, _Controller controller) =>
      const SizedBox.shrink();
}

/// A lite scope abandoned before it ever had a state.
final class _Lite extends LiteScope<_Lite, _LiteState> {
  final Completer<void> gate;
  final List<String> released;

  const _Lite({required this.gate, required this.released})
      : super(initCancellationTimeout: _limit);

  @override
  Future<void> initScope(ScopeInitContext ctx) => gate.future;

  @override
  Widget? buildOnWaiting(BuildContext context) => const SizedBox.shrink();

  @override
  _LiteState createState() => _LiteState();
}

final class _LiteState extends LiteScopeState<_Lite, _LiteState> {
  @override
  FutureOr<void> disposeStateAsync() {
    params.released.add('state');
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
