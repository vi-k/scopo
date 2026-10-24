import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

import 'utils/error_route_audit.dart';
import 'utils/observer.dart';
import 'utils/run_scope_init.dart';
import 'utils/settle.dart';

/// A limit short enough for a test to wait out.
const _short = Duration(milliseconds: 50);

// Every test here reads the route the package announced and checks it against
// where the error really went: `RouteAudit.verify` fails the test when an
// error said to go to `FlutterError` was not reported there exactly once, or
// one said to go nowhere else turned up anyway. One test per place the route
// is known at the moment of the call. The teardown stages of `AsyncScope` did
// not know it, and are tested in their own group below; the two other places
// where it is not known -- the disposal walk of a container and the observer
// of the initialization job -- are rebuilt, and tested, by the tasks of
// `2026-10-24[4]-observer-error-route-plan.md` that follow.
void main() {
  late RecordingObserver observer;
  late RouteAudit audit;

  setUp(() {
    observer = RecordingObserver();
    ScopeConfig.observer = observer;
    audit = RouteAudit();
  });

  tearDown(() {
    ScopeConfig.observer = null;
    ScopeConfig.reset();
  });

  /// Takes the tree down and waits for [label] to finish its teardown.
  Future<void> takeDown(WidgetTester tester, String label) async {
    await tester.pumpWidget(_app(const SizedBox.shrink()));
    await settle(
      tester,
      until: () => observer.events.contains('disposed $label'),
    );
  }

  test('ScopeCompositeObserver hands each observer the same route', () {
    final first = RecordingObserver();
    final second = RecordingObserver();
    final composite = ScopeCompositeObserver([first, second]);
    final error = StateError('failed');

    for (final route in ScopeErrorRoute.values) {
      composite.onError(
        const _Target(),
        ScopePhase.disposal,
        route,
        error,
        null,
      );
    }

    final expected = [
      for (final route in ScopeErrorRoute.values)
        ('target', ScopePhase.disposal, route, error),
    ];
    expect(first.routes, expected);
    expect(second.routes, expected);
  });

  group('the build error boundary', () {
    testWidgets('a scope whose build throws: flutterError', (tester) async {
      audit.install();

      await tester.pumpWidget(
        _app(
          _asyncScope(builder: (context) => throw StateError('build failed')),
        ),
      );
      await tester.pumpAndSettle();

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.build);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);

      await takeDown(tester, 'AsyncScope');
    });

    testWidgets('a lite scope state whose build throws: flutterError',
        (tester) async {
      audit.install();

      await tester.pumpWidget(_app(const _Lite(failBuild: true)));
      await tester.pumpAndSettle();

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.build);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);

      await takeDown(tester, '_Lite');
    });

    testWidgets('a synchronous init() that throws: flutterError',
        (tester) async {
      audit.install();

      await tester.pumpWidget(
        _app(
          ScopeModel<_Model>(
            create: (context) => throw StateError('create failed'),
            dispose: (model) {},
            builder: (context) => const SizedBox.shrink(),
          ),
        ),
      );

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.initialization);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);

      await tester.pumpWidget(_app(const SizedBox.shrink()));
    });
  });

  group('the zone', () {
    for (final isAsync in [false, true]) {
      final how = isAsync ? 'asynchronously' : 'synchronously';

      testWidgets('an initStateAsync that throws $how: zone', (tester) async {
        audit.install();

        await audit.runGuarded(() async {
          await tester.pumpWidget(
            _app(_Lite(failInitState: true, asyncInitState: isAsync)),
          );
          await tester.pumpAndSettle();
        });

        audit.verify(observer.routes);
        expect(observer.routes.single.$2, ScopePhase.initialization);
        expect(observer.routes.single.$3, ScopeErrorRoute.zone);

        await takeDown(tester, '_Lite');
      });
    }

    // Reached right after the awaited `initStateAsync`, inside the discarded
    // future the initialization runs on.
    testWidgets('an onInitialized that throws after an awaited init: zone',
        (tester) async {
      audit.install();

      await audit.runGuarded(() async {
        await tester.pumpWidget(
          _app(const _Lite(failOnInitialized: true, asyncInitState: true)),
        );
        await tester.pumpAndSettle();
      });

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.initialization);
      expect(observer.routes.single.$3, ScopeErrorRoute.zone);

      await takeDown(tester, '_Lite');
    });

    // A synchronous `initStateAsync` runs inside the build that created the
    // state, so `onInitialized` waits for the frame to end -- and a
    // post-frame callback that throws is reported by the scheduler, not
    // raised into the zone.
    testWidgets('an onInitialized that throws after the frame: flutterError',
        (tester) async {
      audit.install();

      await audit.runGuarded(() async {
        await tester.pumpWidget(_app(const _Lite(failOnInitialized: true)));
        await tester.pumpAndSettle();
      });

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.initialization);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);

      await takeDown(tester, '_Lite');
    });

    testWidgets('an AsyncScope that fails before its job starts: zone',
        (tester) async {
      audit.install();

      // A `scopeKey` with no coordinator above it: the lookup throws before
      // the job exists.
      await audit.runGuarded(() async {
        await tester.pumpWidget(_app(_asyncScope(scopeKey: 'key')));
        await tester.pumpAndSettle();
      });

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.initialization);
      expect(observer.routes.single.$3, ScopeErrorRoute.zone);

      await takeDown(tester, 'AsyncScope');
    });
  });

  group('nobody else', () {
    testWidgets('an initScope that throws: observer', (tester) async {
      audit.install();

      await tester.pumpWidget(
        _app(
          _asyncScope(
            initScope: (context, ctx) async =>
                throw StateError('initScope failed'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.initialization);
      expect(observer.routes.single.$3, ScopeErrorRoute.observer);

      await takeDown(tester, 'AsyncScope');
    });

    testWidgets('an initDependencies that throws: observer', (tester) async {
      audit.install();

      await tester.pumpWidget(_app(const _Full(failInit: true)));
      await tester.pumpAndSettle();

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.initialization);
      expect(observer.routes.single.$3, ScopeErrorRoute.observer);

      await takeDown(tester, '_Full');
    });
  });

  group('FlutterError, from the teardown of an element', () {
    testWidgets('an onUnmount that throws on the way off the tree',
        (tester) async {
      await tester.pumpWidget(_app(const _Lite(failUnmount: true)));
      await tester.pumpAndSettle();
      audit.install();

      await takeDown(tester, '_Lite');

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.unmount);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);
    });

    testWidgets('a dispose that throws on the way off the tree',
        (tester) async {
      await tester.pumpWidget(
        _app(
          ScopeModel<_Model>(
            create: (context) => _Model(),
            dispose: (model) => throw StateError('dispose failed'),
            builder: (context) => const SizedBox.shrink(),
          ),
        ),
      );
      audit.install();

      await tester.pumpWidget(_app(const SizedBox.shrink()));

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.disposal);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);
    });

    testWidgets('a label that cannot be read at the top of the teardown',
        (tester) async {
      final tag = _ThrowingTag();
      await tester.pumpWidget(_app(_asyncScope(tag: tag)));
      await tester.pumpAndSettle();
      audit.install();

      tag.throwing = true;
      await tester.pumpWidget(_app(const SizedBox.shrink()));
      await settle(tester, until: () => observer.routes.isNotEmpty);
      // Every hook of the recorder reads the label too, and each of those
      // throws on its own; the route of the preparation is what is asked.
      await tester.pumpAndSettle();

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.preparationForDisposal);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);
    });
  });

  group('FlutterError, for the second failure of a teardown', () {
    // The first leaves through the throw, the second through a report. Only
    // the second is asked about here: the first goes on to the stage of the
    // teardown that catches it, and the group on those stages asks about it.
    testWidgets('Scope.onUnmount', (tester) async {
      await tester.pumpWidget(
        _app(const _Full(failStateUnmount: true, failDepsUnmount: true)),
      );
      await tester.pumpAndSettle();
      audit.install();

      await takeDown(tester, '_Full');

      final second = observer.routes
          .where((entry) => '${entry.$4}'.contains('dependencies failed'))
          .toList();
      audit.verify(second);
      expect(second.single.$2, ScopePhase.unmount);
      expect(second.single.$3, ScopeErrorRoute.flutterError);
    });

    testWidgets('Scope.disposeScope', (tester) async {
      await tester.pumpWidget(
        _app(const _Full(failStateDispose: true, failDepsDispose: true)),
      );
      await tester.pumpAndSettle();
      audit.install();

      await takeDown(tester, '_Full');
      await settle(
        tester,
        until: () => audit.seenIn(SeenIn.flutterError).length > 1,
      );

      final second = observer.routes
          .where((entry) => '${entry.$4}'.contains('dependencies failed'))
          .toList();
      audit.verify(second);
      expect(second.single.$2, ScopePhase.disposal);
      expect(second.single.$3, ScopeErrorRoute.flutterError);
    });

    test('ScopeDependencyGroup.onUnmount', () async {
      final dependencies = _UnmountTwice();
      await runScopeInit((ctx) => dependencies.init(null, ctx));
      audit.install();

      expect(dependencies.onUnmount, throwsStateError);

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.unmount);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);
    });
  });

  group('the teardown stages of AsyncScope', () {
    // The tree took the scope away, so the first failure has nobody to be
    // handed to: it leaves through the throw into a future `dispose()`
    // reports, and the second through a report of its own. Both end up in
    // `FlutterError`.
    testWidgets('two failed stages on the way off the tree: flutterError',
        (tester) async {
      final childGate = Completer<void>();
      addTearDown(() {
        if (!childGate.isCompleted) childGate.complete();
      });
      final preparation = StateError('onWaitForChildrenTimeout failed');
      final disposal = StateError('disposeScope failed');

      // The child holds its teardown open, so the parent's wait for it runs
      // out and the hook that hears of it throws.
      await tester.pumpWidget(
        _app(
          _asyncScope(
            tag: 'parent',
            waitForChildrenTimeout: _short,
            onWaitForChildrenTimeout: () => throw preparation,
            disposeScope: () => throw disposal,
            builder: (context) => _asyncScope(
              tag: 'child',
              disposeScope: () => childGate.future,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      audit.install();

      await takeDown(tester, 'AsyncScope(parent)');
      await settle(
        tester,
        until: () => audit.seenIn(SeenIn.flutterError).contains(preparation),
      );
      expect(audit.seenIn(SeenIn.flutterError), contains(preparation));

      audit.verify(observer.routes);
      expect(
        [
          for (final (_, phase, route, error) in observer.routes)
            (phase, route, error),
        ],
        [
          (
            ScopePhase.preparationForDisposal,
            ScopeErrorRoute.flutterError,
            preparation,
          ),
          (ScopePhase.disposal, ScopeErrorRoute.flutterError, disposal),
        ],
      );

      childGate.complete();
      await settle(
        tester,
        until: () => observer.events.contains('disposed AsyncScope(child)'),
      );
    });

    // `close()` has a caller to hand the first failure to, and the second
    // can only be reported.
    testWidgets('two failed stages of close(): caller, then flutterError',
        (tester) async {
      final unmount = StateError('onUnmount failed');
      final disposal = StateError('disposeScope failed');
      late AsyncScopeContext<AsyncScope> scope;

      await tester.pumpWidget(
        _app(
          _asyncScope(
            onUnmount: () => throw unmount,
            disposeScope: () => throw disposal,
            builder: (context) {
              scope = AsyncScope.of(context, listen: false);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      audit.install();

      Object? caught;
      unawaited(
        scope.close().then<void>(
              (_) {},
              onError: (Object error) => caught = error,
            ),
      );
      await settle(tester, until: () => caught != null);
      expect(caught, isNotNull);

      audit.verify(observer.routes);
      expect(caught, same(unmount));
      expect(
        [
          for (final (_, phase, route, error) in observer.routes)
            (phase, route, error),
        ],
        [
          (ScopePhase.unmount, ScopeErrorRoute.caller, unmount),
          (ScopePhase.disposal, ScopeErrorRoute.flutterError, disposal),
        ],
      );

      await tester.pumpWidget(_app(const SizedBox.shrink()));
    });

    // Described rather than fixed: the teardown is the tree's, so its first
    // failure is reported, and the `close()` that joined it is handed the
    // same failure as well.
    testWidgets('close() joining a teardown the tree began: flutterError',
        (tester) async {
      final gate = Completer<void>();
      final disposal = StateError('disposeScope failed');
      late AsyncScopeContext<AsyncScope> scope;

      await tester.pumpWidget(
        _app(
          _asyncScope(
            disposeScope: () async {
              await gate.future;
              throw disposal;
            },
            builder: (context) {
              scope = AsyncScope.of(context, listen: false);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      audit.install();

      await tester.pumpWidget(_app(const SizedBox.shrink()));
      Object? caught;
      unawaited(
        scope.close().then<void>(
              (_) {},
              onError: (Object error) => caught = error,
            ),
      );
      gate.complete();
      await settle(
        tester,
        until: () =>
            caught != null &&
            audit.seenIn(SeenIn.flutterError).contains(disposal),
      );
      expect(caught, isNotNull);
      expect(audit.seenIn(SeenIn.flutterError), contains(disposal));

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.disposal);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);
      expect(caught, same(disposal));
    });

    // The other way round: `close()` began the teardown and the tree took the
    // element away afterwards. The teardown stays the caller's, so its first
    // failure goes to the `close()` future and nowhere else -- which is why
    // the route is read from what `dispose()` saw, and not from whether the
    // element is still mounted when the stage fails.
    for (final inDisposeScope in [false, true]) {
      final when = inDisposeScope
          ? 'while close() is inside disposeScope'
          : 'before the closing frame';

      testWidgets('the tree takes a closing scope away $when: caller',
          (tester) async {
        final gate = Completer<void>();
        var entered = false;
        final disposal = StateError('disposeScope failed');
        late AsyncScopeContext<AsyncScope> scope;

        await tester.pumpWidget(
          _app(
            _asyncScope(
              disposeScope: () async {
                entered = true;
                await gate.future;
                throw disposal;
              },
              builder: (context) {
                scope = AsyncScope.of(context, listen: false);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        audit.install();

        Object? caught;
        unawaited(
          scope.close().then<void>(
                (_) {},
                onError: (Object error) => caught = error,
              ),
        );
        if (inDisposeScope) {
          await settle(tester, until: () => entered);
          expect(entered, isTrue);
        }
        // The closing frame has not been drawn yet on the first variant: the
        // removal is what releases it.
        expect(entered, inDisposeScope);
        await tester.pumpWidget(_app(const SizedBox.shrink()));
        gate.complete();
        await settle(tester, until: () => caught != null);
        expect(caught, isNotNull);

        audit.verify(observer.routes);
        expect(observer.routes.single.$2, ScopePhase.disposal);
        expect(observer.routes.single.$3, ScopeErrorRoute.caller);
        expect(caught, same(disposal));
        expect(audit.seenIn(SeenIn.flutterError), isEmpty);
      });
    }
  });

  group('FlutterError, for a late release', () {
    testWidgets('Scope.releaseLateDependencies', (tester) async {
      final gate = Completer<void>();
      await tester.pumpWidget(_app(_Full(gate: gate, failDepsUnmount: true)));
      await tester.pump();
      audit.install();

      await takeDown(tester, '_Full');
      gate.complete();
      await settle(tester, until: () => observer.routes.isNotEmpty);

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.initializationCancellation);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);
    });

    testWidgets('the controller an initialization never handed over',
        (tester) async {
      audit.install();

      await tester.pumpWidget(_app(const _Controlled()));
      await tester.pumpAndSettle();

      audit.verify(observer.routes);
      final release = observer.routes
          .singleWhere((entry) => entry.$2 == ScopePhase.disposal);
      expect(release.$3, ScopeErrorRoute.flutterError);

      await takeDown(tester, '_Controlled');
    });

    testWidgets('an abandoned wait of AsyncScope', (tester) async {
      final hang = Completer<void>();
      await tester.pumpWidget(
        _app(
          _asyncScope(
            disposeScope: () => hang.future,
            disposeScopeTimeout: _short,
          ),
        ),
      );
      await tester.pumpAndSettle();
      audit.install();

      await takeDown(tester, 'AsyncScope');
      hang.completeError(StateError('the teardown fell over at last'));
      await settle(tester, until: () => observer.routes.isNotEmpty);

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.abandonedWait);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);
    });

    test('an abandoned wait of a container', () async {
      ScopeConfig.defaultDisposeScopeTimeout = _short;
      final dependencies = _SlowToDispose();
      audit.install();

      await expectLater(
        runScopeInit((ctx) => dependencies.init(null, ctx)),
        throwsA(anything),
      );
      dependencies.gate.complete();
      await pumpEventQueue();

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.abandonedWait);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);
    });
  });

  group('FlutterError, from a container or the cancellation', () {
    test('a container that fails to unmount after a failed initialization',
        () async {
      final dependencies = _UnmountAfterFailure();
      audit.install();

      await expectLater(
        runScopeInit((ctx) => dependencies.init(null, ctx)),
        throwsA(anything),
      );

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.unmount);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);
    });

    test('an arm of concurrent covered by the failure beside it', () async {
      final dependencies = _TwoGatedArms();
      audit.install();

      final init = runScopeInit((ctx) => dependencies.init(null, ctx));
      await pumpEventQueue();
      dependencies.gate.complete();
      await expectLater(init, throwsA(anything));
      await pumpEventQueue();

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.initialization);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);
    });

    test('a dependency that fails after the cancellation', () async {
      final dependencies = _TwoFailingArms();
      audit.install();

      await expectLater(
        runScopeInit((ctx) => dependencies.init(null, ctx)),
        throwsA(anything),
      );
      await pumpEventQueue();

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.initializationCancellation);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);
    });

    testWidgets('a cancellation of AsyncScope that fails', (tester) async {
      final hang = Completer<void>();
      await tester.pumpWidget(
        _app(
          _asyncScope(
            initScope: (context, ctx) => hang.future,
            initCancellationTimeout: _short,
            onInitCancellationTimeout: () =>
                throw StateError('onInitCancellationTimeout failed'),
          ),
        ),
      );
      await tester.pump();
      audit.install();

      await takeDown(tester, 'AsyncScope');

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.initializationCancellation);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);
    });

    test('a foreign root that fails to dispose: flutterError', () async {
      final failure = StateError('the root cannot let go');
      final dependencies = _ForeignRooted(failure);
      await runScopeInit((ctx) => dependencies.init(null, ctx));
      audit.install();

      await dependencies.dispose();

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.disposal);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);
    });

    test('a foreign root that is cancelled: cancellation', () async {
      final dependencies = _ForeignRooted(const Cancelled());
      await runScopeInit((ctx) => dependencies.init(null, ctx));
      audit.install();

      await dependencies.dispose();

      audit.verify(observer.routes);
      expect(observer.routes.single.$2, ScopePhase.disposal);
      expect(observer.routes.single.$3, ScopeErrorRoute.cancellation);
    });
  });
}

Widget _app(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

AsyncScope _asyncScope({
  Object? tag,
  Object? scopeKey,
  Future<void> Function(BuildContext context, ScopeInitContext ctx)? initScope,
  void Function()? onUnmount,
  FutureOr<void> Function()? disposeScope,
  Duration? disposeScopeTimeout,
  Duration? waitForChildrenTimeout,
  void Function()? onWaitForChildrenTimeout,
  Duration? initCancellationTimeout,
  void Function()? onInitCancellationTimeout,
  WidgetBuilder? builder,
}) =>
    AsyncScope(
      tag: tag,
      scopeKey: scopeKey,
      disposeScopeTimeout: disposeScopeTimeout,
      waitForChildrenTimeout: waitForChildrenTimeout,
      onWaitForChildrenTimeout: onWaitForChildrenTimeout,
      initCancellationTimeout: initCancellationTimeout,
      onInitCancellationTimeout: onInitCancellationTimeout,
      initScope: initScope ?? (context, ctx) async {},
      onUnmount: onUnmount,
      disposeScope: disposeScope ?? () {},
      progressBuilder: (context, progress) => const SizedBox.shrink(),
      errorBuilder: (context, error, stackTrace, progress) =>
          const SizedBox.shrink(),
      builder: builder ?? (context) => const SizedBox.shrink(),
    );

/// Something an observer can be told about, with nothing behind it.
final class _Target implements ScopeObservable {
  const _Target();

  @override
  String get debugLabel => 'target';
}

/// A model with nothing in it: what matters is its factory and its disposer.
final class _Model {}

/// An object of the application's that stops being able to name itself.
final class _ThrowingTag {
  bool throwing = false;

  @override
  String toString() {
    if (throwing) {
      throw StateError('a tag that cannot name itself');
    }
    return 'tag';
  }
}

/// A lite scope whose state fails wherever it is told to.
final class _Lite extends LiteScope<_Lite, _LiteState> {
  final bool failInitState;
  final bool asyncInitState;
  final bool failOnInitialized;
  final bool failUnmount;
  final bool failBuild;

  const _Lite({
    this.failInitState = false,
    this.asyncInitState = false,
    this.failOnInitialized = false,
    this.failUnmount = false,
    this.failBuild = false,
  });

  @override
  Widget? buildOnWaiting(BuildContext context) => const SizedBox.shrink();

  @override
  _LiteState createState() => _LiteState();
}

final class _LiteState extends LiteScopeState<_Lite, _LiteState> {
  @override
  FutureOr<void> initStateAsync() {
    if (params.asyncInitState) {
      return _initAsync();
    }
    _init();
  }

  Future<void> _initAsync() async {
    await Future<void>.value();
    _init();
  }

  void _init() {
    if (params.failInitState) {
      throw StateError('initStateAsync failed');
    }
  }

  @override
  void onInitialized() {
    if (params.failOnInitialized) {
      throw StateError('onInitialized failed');
    }
  }

  @override
  void onUnmount() {
    if (params.failUnmount) {
      throw StateError('onUnmount failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (params.failBuild) {
      throw StateError('build failed');
    }
    return const SizedBox.shrink();
  }
}

/// A full scope whose state and dependencies fail wherever they are told to.
final class _Full extends Scope<_Full, _Deps, _FullState> {
  /// Parks `initDependencies` on this, so the teardown gives up on it.
  final Completer<void>? gate;
  final bool failInit;
  final bool failStateUnmount;
  final bool failStateDispose;
  final bool failDepsUnmount;
  final bool failDepsDispose;

  const _Full({
    this.gate,
    this.failInit = false,
    this.failStateUnmount = false,
    this.failStateDispose = false,
    this.failDepsUnmount = false,
    this.failDepsDispose = false,
  }) : super(initCancellationTimeout: _short);

  @override
  Future<_Deps> initDependencies(
    BuildContext context,
    ScopeInitContext ctx,
  ) async {
    if (gate case final gate?) {
      await gate.future;
    }
    if (failInit) {
      throw StateError('initDependencies failed');
    }

    return _Deps(failUnmount: failDepsUnmount, failDispose: failDepsDispose);
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
  _FullState createState() => _FullState();
}

final class _Deps implements ScopeDependencies {
  final bool failUnmount;
  final bool failDispose;

  _Deps({required this.failUnmount, required this.failDispose});

  @override
  void onUnmount() {
    if (failUnmount) {
      throw StateError('the dependencies failed to unmount');
    }
  }

  @override
  FutureOr<void> dispose() {
    if (failDispose) {
      throw StateError('the dependencies failed to dispose');
    }
  }
}

final class _FullState extends ScopeState<_Full, _Deps, _FullState> {
  @override
  void onUnmount() {
    if (params.failStateUnmount) {
      throw StateError('the state failed to unmount');
    }
  }

  @override
  FutureOr<void> disposeStateAsync() {
    if (params.failStateDispose) {
      throw StateError('the state failed to dispose of itself');
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// A controller that fails to start and then fails to be released.
final class _FailingController extends ScopeController {
  @override
  Future<void> init() async => throw StateError('init failed');

  @override
  Future<void> dispose() async => throw StateError('dispose failed');
}

final class _Controlled
    extends AsyncControllerScopeBase<_Controlled, _FailingController> {
  const _Controlled();

  @override
  _FailingController createController(BuildContext context) =>
      _FailingController();

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
  Widget buildOnReady(BuildContext context, _FailingController controller) =>
      const SizedBox.shrink();
}

/// Two dependencies whose `unmount` both throw.
final class _UnmountTwice extends ScopeAutoDependencies<_UnmountTwice, void> {
  @override
  ScopeDependency buildDependencies(void context) => sequential('', [
        for (final name in const ['first', 'second'])
          dep(name, (handle) {
            handle.unmount = () => throw StateError('$name failed to unmount');
          }),
      ]);
}

/// A dependency that cannot unmount, behind one that fails to initialize.
final class _UnmountAfterFailure
    extends ScopeAutoDependencies<_UnmountAfterFailure, void> {
  @override
  ScopeDependency buildDependencies(void context) => sequential('', [
        dep('held', (handle) {
          handle.unmount = () => throw StateError('held failed to unmount');
        }),
        dep('broken', (handle) => throw StateError('broken failed')),
      ]);
}

/// A container whose initialization fails and whose disposal fails late.
///
/// The disposal outlives the limit the failed initialization waits for it,
/// and fails once nobody is waiting any more.
final class _SlowToDispose extends ScopeAutoDependencies<_SlowToDispose, void> {
  final gate = Completer<void>();

  @override
  ScopeDependency buildDependencies(void context) => sequential('', [
        dep('broken', (handle) => throw StateError('broken failed')),
      ]);

  @override
  Future<void> dispose() async {
    await super.dispose();
    await gate.future;
    throw StateError('the disposal fell over at last');
  }
}

/// Two arms that resume from one gate, so both throw before either is marked.
final class _TwoGatedArms extends ScopeAutoDependencies<_TwoGatedArms, void> {
  final gate = Completer<void>();

  @override
  ScopeDependency buildDependencies(void context) => concurrent('', [
        for (final name in const ['left', 'right'])
          dep(name, (_) async {
            await gate.future;
            throw StateError('$name failed');
          }),
      ]);
}

/// Two arms that resume from their own delay, so the second is already
/// cancelled when it throws.
final class _TwoFailingArms
    extends ScopeAutoDependencies<_TwoFailingArms, void> {
  @override
  ScopeDependency buildDependencies(void context) => concurrent('', [
        for (final name in const ['alpha', 'beta'])
          dep(name, (_) async {
            await Future<void>.delayed(Duration.zero);
            throw StateError('$name failed');
          }),
      ]);
}

/// A container whose root is of the caller's own making.
final class _ForeignRooted extends ScopeAutoDependencies<_ForeignRooted, void> {
  final Object failure;

  _ForeignRooted(this.failure);

  @override
  ScopeDependency buildDependencies(void context) => _ForeignRoot(failure);
}

/// A dependency of somebody else's making whose `dispose` throws [failure].
final class _ForeignRoot implements ScopeDependency {
  final Object failure;

  _ForeignRoot(this.failure);

  @override
  String get name => 'foreign';

  @override
  int get count => 1;

  @override
  ScopeDependencyState get state => _state;
  ScopeDependencyState _state = const ScopeDependencyInitial();

  @override
  bool get disposalRequired => _state is ScopeDependencyInitialized;

  @override
  Future<void> init(ScopeInitContext ctx, void Function(String path) onStep) {
    _state = const ScopeDependencyInitialized();
    onStep(name);
    return Future<void>.value();
  }

  @override
  void onUnmount() {}

  @override
  Future<void> dispose(void Function(String path) onStep) async {
    Error.throwWithStackTrace(failure, StackTrace.current);
  }

  @override
  String get wrappedName => '"$name"';

  @override
  String stateToString() => '$state';
}
