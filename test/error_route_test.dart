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
// is known at the moment of the call. The teardown stages of `AsyncScope`,
// the disposal walk of a container and the observer of the initialization job
// did not know it, and are tested in their own groups below.
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

  // Every failed step of a container's own tree is reported where it fails,
  // the failure that goes on to leave the walk included -- and that one is
  // not reported a second time when it gets there. `verify` holds each route
  // to one report; the count of all reports is what shows that the one that
  // left the walk was not reported again under its new name.
  group('FlutterError, for every failed step of a container', () {
    /// Disposes of [dependencies] and returns what each step announced.
    Future<List<(ScopePhase, ScopeErrorRoute, String)>> disposeOf(
      _Steps dependencies,
    ) async {
      await runScopeInit((ctx) => dependencies.init(null, ctx));
      audit.install();

      await dependencies.dispose();

      audit.verify(observer.routes);
      return [
        for (final (_, phase, route, error) in observer.routes)
          (phase, route, '$error'),
      ];
    }

    test('two failed leaves of sequential: flutterError each', () async {
      final routes = await disposeOf(
        _Steps(
          (deps) => deps.sequential('', [
            _failingDep(deps, 'first'),
            _failingDep(deps, 'second'),
          ]),
        ),
      );

      // Reverse order: the teardown runs the construction backwards.
      expect(routes, [
        (
          ScopePhase.disposal,
          ScopeErrorRoute.flutterError,
          'second: Bad state: second cannot let go',
        ),
        (
          ScopePhase.disposal,
          ScopeErrorRoute.flutterError,
          'first: Bad state: first cannot let go',
        ),
      ]);
      expect(audit.seenIn(SeenIn.flutterError), hasLength(2));
    });

    test('two failed leaves of concurrent: flutterError each', () async {
      final routes = await disposeOf(
        _Steps(
          (deps) => deps.concurrent('', [
            _failingDep(deps, 'left'),
            _failingDep(deps, 'right'),
          ]),
        ),
      );

      expect(
        routes,
        unorderedEquals([
          (
            ScopePhase.disposal,
            ScopeErrorRoute.flutterError,
            'left: Bad state: left cannot let go',
          ),
          (
            ScopePhase.disposal,
            ScopeErrorRoute.flutterError,
            'right: Bad state: right cannot let go',
          ),
        ]),
      );
      expect(audit.seenIn(SeenIn.flutterError), hasLength(2));
    });

    test('a failed leaf in a nested group and one beside it: flutterError each',
        () async {
      final routes = await disposeOf(
        _Steps(
          (deps) => deps.sequential('', [
            _failingDep(deps, 'outer'),
            deps.sequential('inner', [_failingDep(deps, 'leaf')]),
          ]),
        ),
      );

      expect(routes, [
        (
          ScopePhase.disposal,
          ScopeErrorRoute.flutterError,
          'inner/leaf: Bad state: leaf cannot let go',
        ),
        (
          ScopePhase.disposal,
          ScopeErrorRoute.flutterError,
          'outer: Bad state: outer cannot let go',
        ),
      ]);
      expect(audit.seenIn(SeenIn.flutterError), hasLength(2));
    });

    // Pins what `doc/debug.md` says of a failed step: the report names it.
    test('the report of a failed step names the step', () async {
      await disposeOf(
        _Steps(
          (deps) => deps.sequential('', [
            deps.sequential('inner', [_failingDep(deps, 'leaf')]),
          ]),
        ),
      );

      final report = audit.seenIn(SeenIn.flutterError).single;
      expect(report, isA<ScopeDependencyException>());
      final named = report as ScopeDependencyException;
      expect(named.name, 'inner/leaf');
      expect('${named.error}', 'Bad state: leaf cannot let go');
    });

    test('a leaf whose release is cancelled: cancellation', () async {
      final routes = await disposeOf(
        _Steps(
          (deps) => deps.sequential('', [
            deps.dep('gone', (handle) {
              handle.dispose = () => throw const Cancelled();
            }),
          ]),
        ),
      );

      expect(routes.single.$1, ScopePhase.disposal);
      expect(routes.single.$2, ScopeErrorRoute.cancellation);
      expect(audit.seenIn(SeenIn.flutterError), isEmpty);
    });

    // A child of somebody else's making may throw a failure that is already
    // named, and may name it twice. The group above re-prefixes it on the
    // way out, a new object around the same inside, so the failure that
    // leaves the walk is not the one the step reported -- and twice named,
    // it reaches the end of the walk two layers deep. The audit unwraps one
    // layer and cannot see a second report under the new name; the count
    // of all reports is what does.
    ScopeDependencyException named(String name, Object error) =>
        ScopeDependencyException(name, error, StackTrace.current);

    for (final (how, failure) in [
      ('named once', named('deep', StateError('cannot let go'))),
      (
        'named twice',
        named('deep', named('deeper', StateError('cannot let go'))),
      ),
    ]) {
      test('a foreign child that throws a failure $how: one report', () async {
        final routes = await disposeOf(
          _Steps((deps) => deps.sequential('', [_ForeignRoot(failure)])),
        );

        expect(routes.single.$1, ScopePhase.disposal);
        expect(routes.single.$2, ScopeErrorRoute.flutterError);
        expect(audit.seenIn(SeenIn.flutterError), hasLength(1));
      });
    }

    test('a foreign child that throws a named cancellation: cancellation',
        () async {
      final routes = await disposeOf(
        _Steps(
          (deps) => deps.sequential('', [
            _ForeignRoot(named('deep', const Cancelled())),
          ]),
        ),
      );

      expect(routes.single.$1, ScopePhase.disposal);
      expect(routes.single.$2, ScopeErrorRoute.cancellation);
      expect(audit.seenIn(SeenIn.flutterError), isEmpty);
    });
  });

  // The tree of a container is public, and a walk over it can be driven by
  // hand through `root.dispose()`. The steps report the same way: whether the
  // first failure goes on to a caller is not known at the step, for the same
  // reason the walk does not know which failure will leave it. So that one
  // reaches two channels, and the route says `flutterError` -- described
  // rather than fixed: the package has reported it, and whoever drove the
  // walk has nothing left to report.
  group('FlutterError, for a container walk driven by hand', () {
    test('every failed step: flutterError, the first thrown to the driver too',
        () async {
      final dependencies = _Steps(
        (deps) => deps.sequential('', [
          _failingDep(deps, 'first'),
          _failingDep(deps, 'second'),
        ]),
      );
      await runScopeInit((ctx) => dependencies.init(null, ctx));
      audit.install();

      Object? caught;
      await dependencies.root.dispose((_) {}).then<void>(
            (_) {},
            onError: (Object error) => caught = error,
          );

      audit.verify(observer.routes);
      expect(
        [for (final (_, phase, route, _) in observer.routes) (phase, route)],
        [
          (ScopePhase.disposal, ScopeErrorRoute.flutterError),
          (ScopePhase.disposal, ScopeErrorRoute.flutterError),
        ],
      );
      expect(audit.seenIn(SeenIn.flutterError), hasLength(2));
      // The first failure of the walk, in walk order -- the teardown runs the
      // construction backwards, so that is `second`.
      expect(caught, isA<ScopeDependencyException>());
      final first = observer.routes.first.$4 as ScopeDependencyException;
      expect(
        (caught! as ScopeDependencyException).error,
        same(first.error),
      );
    });

    // The container joins the walk already running and is handed its
    // failure, which that walk's step has reported before the container's
    // disposal began. Forgetting the reported steps as a disposal starts
    // would report it a second time.
    test('a container that joins a walk driven by hand: one report', () async {
      final parked = Completer<void>();
      final dependencies = _Steps(
        (deps) => deps.sequential('', [
          deps.dep('parked', (handle) {
            handle.dispose = () => parked.future;
          }),
          _failingDep(deps, 'failing'),
        ]),
      );
      await runScopeInit((ctx) => dependencies.init(null, ctx));
      audit.install();

      unawaited(dependencies.root.dispose((_) {}).onError((_, __) {}));
      await pumpEventQueue();
      final disposal = dependencies.dispose();
      parked.complete();
      await disposal;

      audit.verify(observer.routes);
      expect(observer.routes.single.$3, ScopeErrorRoute.flutterError);
      expect(audit.seenIn(SeenIn.flutterError), hasLength(1));
    });

    // A reported step outlives the walk that reported it when no disposal of
    // the container comes after. The next tree must not inherit it: a failure
    // that never passes through a step, with the same error inside, would be
    // taken for one that had already been reported, and dropped.
    test('a step reported by hand does not hide a failure of the next tree',
        () async {
      const boom = _Boom();
      var built = 0;
      final dependencies = _Steps(
        (deps) => built++ == 0
            ? deps.sequential('', [
                deps.dep('leaf', (handle) {
                  handle.dispose = () => throw boom;
                }),
              ])
            : deps.sequential('', [const _RefusingForeign(boom)]),
      );
      await runScopeInit((ctx) => dependencies.init(null, ctx));
      audit.install();

      await dependencies.root.dispose((_) {}).onError((_, __) {});
      expect(audit.seenIn(SeenIn.flutterError), hasLength(1));

      await runScopeInit((ctx) => dependencies.init(null, ctx));
      expect(built, 2, reason: 'the second init() builds a new tree');
      await dependencies.dispose();
      audit.uninstall();

      expect(
        audit.seenIn(SeenIn.flutterError),
        hasLength(2),
        reason: 'the group of the new tree fails before it reaches any '
            'child, so no step reports it: the container is the only one '
            'that does',
      );
    });
  });

  // The kernel hands this observer errors of two roads. One asks for an
  // answer at once -- cleanup, callbacks, late work -- and says so with
  // `JobErrorAnswer.answered`; the other is the failure of a child, told with
  // `JobErrorAnswer.later`, whose answer, if any, comes once nobody has read
  // the outcome. For that one the route is
  // `observer`, and it stays final: an answer that comes later does not send
  // it to `FlutterError` after all while an observer is there to have heard
  // it. That is 1a of `2026-10-24[3]-observer-error-route-design.md`.
  group('the observer of the initialization job', () {
    /// The routes announced for [error], by identity.
    List<(String, ScopePhase, ScopeErrorRoute, Object)> routesOf(
      Object error,
    ) =>
        [
          for (final entry in observer.routes)
            if (identical(entry.$4, error)) entry,
        ];

    testWidgets('a ctx.onDispose that throws: flutterError', (tester) async {
      final failure = StateError('cleanup failed');
      audit.install();

      await tester.pumpWidget(
        _app(
          _asyncScope(
            initScope: (context, ctx) async =>
                ctx.onDispose(() => throw failure),
          ),
        ),
      );
      await tester.pumpAndSettle();

      audit.verify(observer.routes);
      expect(routesOf(failure).single.$2, ScopePhase.initialization);
      expect(routesOf(failure).single.$3, ScopeErrorRoute.flutterError);

      await takeDown(tester, 'AsyncScope');
    });

    testWidgets(
        'a ParallelWaitError from the cleanup stack: a route for each error '
        'inside', (tester) async {
      final first = StateError('first release failed');
      final second = StateError('second release failed');
      const cancelled = Cancelled('a release gave up');
      audit.install();

      await tester.pumpWidget(
        _app(
          _asyncScope(
            initScope: (context, ctx) async => ctx.onDispose(
              () => [
                Future<void>.error(first),
                Future<void>.error(second),
                Future<void>.error(cancelled),
              ].wait,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      audit.verify(observer.routes);
      expect(routesOf(first).single.$3, ScopeErrorRoute.flutterError);
      expect(routesOf(second).single.$3, ScopeErrorRoute.flutterError);
      expect(routesOf(cancelled).single.$3, ScopeErrorRoute.cancellation);
      expect(
        observer.routes,
        hasLength(3),
        reason: 'the envelope itself is not an error of its own',
      );

      await takeDown(tester, 'AsyncScope');
    });

    testWidgets('a Cancelled thrown by a callback: cancellation',
        (tester) async {
      audit.install();

      await tester.pumpWidget(
        _app(
          _asyncScope(
            initScope: (context, ctx) async =>
                ctx.onDispose(() => throw const Cancelled('from a disposer')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      audit.verify(observer.routes);
      expect(observer.routes.single.$4, isA<Cancelled>());
      expect(observer.routes.single.$3, ScopeErrorRoute.cancellation);

      await takeDown(tester, 'AsyncScope');
    });

    testWidgets('a child failure the body caught: observer', (tester) async {
      const failure = _Boom();
      audit.install();

      await tester.pumpWidget(
        _app(
          _asyncScope(
            initScope: (context, ctx) async {
              try {
                await ctx.run(Job.deferred<void>((_) async => throw failure));
              } on _Boom {
                // Handled: the scope goes on without it.
              }
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      audit.verify(observer.routes);
      expect(routesOf(failure).single.$2, ScopePhase.initialization);
      expect(routesOf(failure).single.$3, ScopeErrorRoute.observer);
      expect(audit.seenIn(SeenIn.flutterError), isEmpty);

      await takeDown(tester, 'AsyncScope');
    });

    testWidgets(
        'a child failure nobody read, with an observer: observer, and '
        'nothing in FlutterError', (tester) async {
      final failure = StateError('child failed, and nobody looked');
      audit.install();

      await tester.pumpWidget(
        _app(
          _asyncScope(
            initScope: (context, ctx) async =>
                ctx.start(Job.deferred<void>((_) async => throw failure)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      audit.verify(observer.routes);
      expect(routesOf(failure).single.$2, ScopePhase.initialization);
      expect(routesOf(failure).single.$3, ScopeErrorRoute.observer);
      expect(
        audit.seenIn(SeenIn.flutterError),
        isEmpty,
        reason: 'the observer was told the route is final, and a crash '
            'reporter that forwards `observer` has it already',
      );

      await takeDown(tester, 'AsyncScope');
    });

    // `JobErrorAnswer.never`: the kernel will not ask about it, and it is no
    // cancellation, so the observer is the only one to hear it.
    testWidgets('a child whose failure is ignored: observer', (tester) async {
      final failure = StateError('child failed, and nobody minds');
      audit.install();

      await tester.pumpWidget(
        _app(
          _asyncScope(
            initScope: (context, ctx) async {
              final child = Job.deferred<void>((_) async {
                await Future<void>.value();
                throw failure;
              });
              ctx.start(child);
              child.ignoreFailure();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      audit.verify(observer.routes);
      expect(routesOf(failure).single.$3, ScopeErrorRoute.observer);
      expect(audit.seenIn(SeenIn.flutterError), isEmpty);

      await takeDown(tester, 'AsyncScope');
    });

    testWidgets(
        'a child failure nobody read, without an observer: one report in '
        'FlutterError', (tester) async {
      ScopeConfig.observer = null;
      final failure = StateError('child failed, and nobody looked');
      audit.install();

      await tester.pumpWidget(
        _app(
          _asyncScope(
            initScope: (context, ctx) async =>
                ctx.start(Job.deferred<void>((_) async => throw failure)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      audit.uninstall();

      expect(
        audit.seenIn(SeenIn.flutterError),
        [same(failure)],
        reason: 'with nobody to have heard it, the red line is all there is',
      );

      await tester.pumpWidget(_app(const SizedBox.shrink()));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'a body failure whose outcome a cancellation took over: '
        'flutterError', (tester) async {
      final failure = StateError('body failed');
      final cleanup = Completer<void>();
      audit.install();

      await tester.pumpWidget(
        _app(
          _asyncScope(
            initScope: (context, ctx) async {
              ctx.onDispose(() => cleanup.future);
              throw failure;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        observer.routes,
        isEmpty,
        reason: 'the outcome is still due to carry the failure to the screen',
      );

      await tester.pumpWidget(_app(const SizedBox.shrink()));
      cleanup.complete();
      await settle(
        tester,
        until: () => observer.events.contains('disposed AsyncScope'),
      );

      audit.verify(observer.routes);
      expect(
        routesOf(failure).single.$2,
        ScopePhase.initializationCancellation,
      );
      expect(routesOf(failure).single.$3, ScopeErrorRoute.flutterError);
    });

    // Pins leftover (d) of the routes list in `doc/debug.md`.
    testWidgets(
        'a child failure nobody read, with an empty composite observer: '
        'nothing in FlutterError', (tester) async {
      ScopeConfig.observer = const ScopeCompositeObserver([]);
      final failure = StateError('child failed, and nobody looked');
      var thrown = false;
      audit.install();

      await tester.pumpWidget(
        _app(
          _asyncScope(
            initScope: (context, ctx) async => ctx.start(
              Job.deferred<void>((_) async {
                thrown = true;
                throw failure;
              }),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(const SizedBox.shrink()));
      await tester.pumpAndSettle();
      audit.uninstall();

      expect(thrown, isTrue);
      expect(
        audit.seenIn(SeenIn.flutterError),
        isEmpty,
        reason: 'an observer is set, so the route said `observer` -- to an '
            'observer that hands it to nobody',
      );
    });

    // Pins leftover (b) of the routes list in `doc/debug.md`.
    testWidgets(
        'a body failure the filter names, covered by a cancellation: no '
        'onError at all', (tester) async {
      Job.isCancellationError = (error) => error is _Boom;
      addTearDown(() => Job.isCancellationError = null);
      final cleanup = Completer<void>();
      audit.install();

      await audit.runGuarded(() async {
        await tester.pumpWidget(
          _app(
            _asyncScope(
              initScope: (context, ctx) async {
                ctx.onDispose(() => cleanup.future);
                throw const _Boom();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pumpWidget(_app(const SizedBox.shrink()));
        cleanup.complete();
        await settle(
          tester,
          until: () => observer.events.contains('disposed AsyncScope'),
        );
      });
      // Nothing more is due once the teardown is over: give it a fair chance
      // all the same, and look again.
      await settle(tester, until: () => false, rounds: 5);
      audit.uninstall();

      expect(observer.events, contains('disposed AsyncScope'));
      expect(observer.events, contains('cancelled AsyncScope'));
      expect(observer.routes, isEmpty);
      expect(audit.seenIn(SeenIn.flutterError), isEmpty);
      expect(audit.seenIn(SeenIn.zone), isEmpty);
    });

    // Pins leftover (a) of the routes list in `doc/debug.md`: with the late
    // `ignoreFailure()` the route says `flutterError` and no report comes.
    for (final ignored in [false, true]) {
      final how = ignored
          ? 'ignored late: no report after all'
          : 'not ignored: one report';

      testWidgets('the body of a cancelled child fails, $how', (tester) async {
        final failure = StateError('child failed after its cancellation');
        final cleanup = Completer<void>();
        late DeferredJob<void> child;
        await tester.pumpWidget(
          _app(
            _asyncScope(
              initScope: (context, ctx) async {
                child = Job.deferred<void>((inner) async {
                  final stop = Completer<void>();
                  inner
                    ..onCancel(stop.complete)
                    ..onDispose(() => cleanup.future);
                  await stop.future;
                  throw failure;
                });
                ctx.start(child);
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        audit.install();

        await tester.pumpWidget(_app(const SizedBox.shrink()));
        await settle(tester, until: () => routesOf(failure).isNotEmpty);
        expect(child.isFinished, isFalse);
        if (ignored) child.ignoreFailure();
        cleanup.complete();
        await settle(
          tester,
          until: () => observer.events.contains('disposed AsyncScope'),
        );
        await settle(tester, until: () => false, rounds: 5);
        audit.uninstall();

        expect(child.isFinished, isTrue);
        expect(routesOf(failure).single.$3, ScopeErrorRoute.flutterError);
        if (ignored) {
          expect(audit.seenIn(SeenIn.flutterError), isEmpty);
        } else {
          audit.verify(observer.routes);
        }
      });
    }

    testWidgets('a late disposeScope of AsyncScope (ctx.onDiscard)',
        (tester) async {
      final gate = Completer<void>();
      final failure = StateError('the late release failed');
      await tester.pumpWidget(
        _app(
          _asyncScope(
            initScope: (context, ctx) => gate.future,
            disposeScope: () => throw failure,
          ),
        ),
      );
      await tester.pump();
      audit.install();

      await takeDown(tester, 'AsyncScope');
      gate.complete();
      await settle(tester, until: () => observer.routes.isNotEmpty);

      audit.verify(observer.routes);
      expect(routesOf(failure).single.$3, ScopeErrorRoute.flutterError);
    });

    testWidgets('a late releaseLateData of AsyncDataScope', (tester) async {
      final gate = Completer<void>();
      final failure = StateError('the late data release failed');
      await tester.pumpWidget(
        _app(
          AsyncDataScope<String>(
            initData: (context, ctx) async {
              await gate.future;
              return 'data';
            },
            disposeData: (data) => throw failure,
            progressBuilder: (context, progress) => const SizedBox.shrink(),
            errorBuilder: (context, error, stackTrace, progress) =>
                const SizedBox.shrink(),
            builder: (context, data) => const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();
      audit.install();

      await tester.pumpWidget(_app(const SizedBox.shrink()));
      await settle(
        tester,
        until: () => observer.events.any(
          (event) => event.startsWith('disposed AsyncDataScope'),
        ),
      );
      gate.complete();
      await settle(tester, until: () => observer.routes.isNotEmpty);

      audit.verify(observer.routes);
      expect(routesOf(failure).single.$3, ScopeErrorRoute.flutterError);
    });

    testWidgets('a ctx.onCancel callback that throws: flutterError',
        (tester) async {
      final failure = StateError('the cancellation callback failed');
      await tester.pumpWidget(
        _app(
          _asyncScope(
            initScope: (context, ctx) async {
              ctx.onCancel(() => throw failure);
              await ctx.abandonable(() => Completer<void>().future);
            },
          ),
        ),
      );
      await tester.pump();
      audit.install();

      await takeDown(tester, 'AsyncScope');

      audit.verify(observer.routes);
      expect(
        routesOf(failure).single.$2,
        ScopePhase.initializationCancellation,
      );
      expect(routesOf(failure).single.$3, ScopeErrorRoute.flutterError);
    });

    testWidgets('a whenFinished callback that throws: flutterError',
        (tester) async {
      final failure = StateError('the finish callback failed');
      audit.install();

      await tester.pumpWidget(
        _app(
          _asyncScope(
            initScope: (context, ctx) async =>
                ctx.job.whenFinished((_) => throw failure),
          ),
        ),
      );
      await tester.pumpAndSettle();

      audit.verify(observer.routes);
      expect(routesOf(failure).single.$3, ScopeErrorRoute.flutterError);

      await takeDown(tester, 'AsyncScope');
    });

    testWidgets('a late failure of ctx.abandonable: flutterError',
        (tester) async {
      final gate = Completer<void>();
      final failure = StateError('the abandoned action failed');
      await tester.pumpWidget(
        _app(
          _asyncScope(
            initScope: (context, ctx) => ctx.abandonable(() async {
              await gate.future;
              throw failure;
            }),
          ),
        ),
      );
      await tester.pump();
      audit.install();

      await takeDown(tester, 'AsyncScope');
      gate.complete();
      await settle(tester, until: () => observer.routes.isNotEmpty);

      audit.verify(observer.routes);
      expect(routesOf(failure).single.$2, ScopePhase.abandonedWait);
      expect(routesOf(failure).single.$3, ScopeErrorRoute.flutterError);
    });

    testWidgets('a failure of ctx.unattended work: flutterError',
        (tester) async {
      final gate = Completer<void>();
      final failure = StateError('the unattended work failed');
      await tester.pumpWidget(
        _app(
          _asyncScope(
            initScope: (context, ctx) async => ctx.unattended(() async {
              await gate.future;
              throw failure;
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();
      audit.install();

      gate.complete();
      await settle(tester, until: () => observer.routes.isNotEmpty);

      audit.verify(observer.routes);
      expect(routesOf(failure).single.$2, ScopePhase.abandonedWait);
      expect(routesOf(failure).single.$3, ScopeErrorRoute.flutterError);

      await takeDown(tester, 'AsyncScope');
    });

    // `Job.isCancellationError` is the app's own word on what a cancellation
    // is, and the kernel asks it before `onError` once the job has accepted
    // one. Each case runs with the filter and without it, so the route is
    // seen to follow the filter rather than the place.
    for (final filtered in [true, false]) {
      final expected = filtered
          ? ScopeErrorRoute.cancellation
          : ScopeErrorRoute.flutterError;
      final how = filtered ? 'with the filter' : 'without the filter';

      testWidgets(
          'a ctx.onDispose of a cancelled job that throws, $how: '
          '${expected.name}', (tester) async {
        if (filtered) {
          Job.isCancellationError = (error) => error is _Boom;
          addTearDown(() => Job.isCancellationError = null);
        }
        await tester.pumpWidget(
          _app(
            _asyncScope(
              initScope: (context, ctx) async {
                ctx.onDispose(() => throw const _Boom());
                await ctx.abandonable(() => Completer<void>().future);
              },
            ),
          ),
        );
        await tester.pump();
        audit.install();

        await takeDown(tester, 'AsyncScope');

        audit.verify(observer.routes);
        expect(
          routesOf(const _Boom()).single.$2,
          ScopePhase.initializationCancellation,
        );
        expect(routesOf(const _Boom()).single.$3, expected);
      });

      testWidgets(
          'a body that fails after its cancellation, $how: ${expected.name}',
          (tester) async {
        if (filtered) {
          Job.isCancellationError = (error) => error is _Boom;
          addTearDown(() => Job.isCancellationError = null);
        }
        await tester.pumpWidget(
          _app(
            _asyncScope(
              initScope: (context, ctx) async {
                final stop = Completer<void>();
                ctx.onCancel(stop.complete);
                await ctx.join(() async {
                  await stop.future;
                  throw const _Boom();
                });
              },
            ),
          ),
        );
        await tester.pump();
        audit.install();

        await takeDown(tester, 'AsyncScope');

        audit.verify(observer.routes);
        expect(
          routesOf(const _Boom()).single.$2,
          ScopePhase.initializationCancellation,
        );
        expect(routesOf(const _Boom()).single.$3, expected);
      });
    }
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

/// A container whose tree each test builds for itself.
final class _Steps extends ScopeAutoDependencies<_Steps, void> {
  final ScopeDependency Function(_Steps deps) build;

  _Steps(this.build);

  @override
  ScopeDependency buildDependencies(void context) => build(this);
}

/// A dependency of [deps] called [name] whose release throws.
ScopeDependency _failingDep(_Steps deps, String name) =>
    deps.dep(name, (handle) {
      handle.dispose = () => throw StateError('$name cannot let go');
    });

/// A failure that is the same object every time it is thrown.
final class _Boom implements Exception {
  const _Boom();
}

/// A dependency of somebody else's making that cannot say whether it needs
/// disposing of: asking it throws [failure], which fails the group above it
/// before that group reaches any child.
final class _RefusingForeign implements ScopeDependency {
  final Exception failure;

  const _RefusingForeign(this.failure);

  @override
  String get name => 'refusing';

  @override
  int get count => 1;

  @override
  ScopeDependencyState get state => const ScopeDependencyInitialized();

  @override
  bool get disposalRequired => throw failure;

  @override
  Future<void> init(ScopeInitContext ctx, void Function(String path) onStep) {
    onStep(name);
    return Future<void>.value();
  }

  @override
  void onUnmount() {}

  @override
  Future<void> dispose(void Function(String path) onStep) async {}

  @override
  String get wrappedName => '"$name"';

  @override
  String stateToString() => '$state';
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
