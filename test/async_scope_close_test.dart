import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

import 'utils/settle.dart';

void main() {
  for (final family in _Family.values) {
    group('${family.name}.close()', () {
      for (final offstage in [false, true]) {
        testWidgets('unmounts the consumer before releasing its value '
            '(offstage=$offstage)', (tester) async {
          final h = _Harness(family);
          await tester.pumpWidget(
            _app(Offstage(offstage: offstage, child: h.scope())),
          );
          await tester.pumpAndSettle();
          expect(find.byType(_Consumer, skipOffstage: false), findsOneWidget);

          final done = _Outcome(h.context.close());
          await tester.idle();
          expect(h.events, isEmpty, reason: 'release must wait for the frame');
          await settle(tester, until: () => done.settled);

          expect(done.settled, isTrue);
          expect(done.failure, isNull);
          expect(h.events, ['child.dispose', 'resource.dispose']);
          expect(h.key.currentContext, isNotNull);
          await _remove(tester);
          expect(h.releases, 1);
        });
      }

      for (final phase in [_Phase.ready, _Phase.initializing, _Phase.error]) {
        testWidgets('completes from ${phase.name}', (tester) async {
          final h = _Harness(family, phase: phase);
          await tester.pumpWidget(_app(h.scope()));
          await tester.pumpAndSettle();
          expect(h.context.hasError, phase == _Phase.error);
          expect(h.context.isInitialized, phase == _Phase.ready);

          final done = _Outcome(h.context.close());
          await tester.pump();
          if (phase == _Phase.initializing) h.initGate.complete();
          await settle(tester, until: () => done.settled);

          expect(done.settled, isTrue);
          expect(done.failure, isNull);
          expect(find.text('closing'), findsOneWidget);
          await _remove(tester);
        });
      }

      testWidgets('closes while waiting for a held scopeKey', (tester) async {
        final owner = _Harness(family, scopeKey: 'shared');
        final waiting = _Harness(family, scopeKey: 'shared');
        await tester.pumpWidget(
          _app(Column(children: [owner.scope(), waiting.scope()])),
        );
        await tester.pumpAndSettle();
        expect(waiting.context.state, isA<AsyncScopeWaiting>());
        expect(waiting.initializations, 0);

        final done = _Outcome(waiting.context.close());
        await settle(tester, until: () => done.settled);

        expect(done.settled, isTrue);
        expect(done.failure, isNull);
        expect(waiting.initializations, 0);
        expect(owner.context.isInitialized, isTrue);
        await _remove(tester);
      });

      for (final showClosing in [false, true]) {
        testWidgets('replaces the subtree on the first closing frame '
            '(showClosing=$showClosing)', (tester) async {
          final h = _Harness(family, showClosing: showClosing)
            ..disposeGate = Completer<void>();
          await tester.pumpWidget(_app(h.scope()));
          await tester.pumpAndSettle();

          final done = _Outcome(h.context.close());
          await tester.pump();

          expect(find.byType(_Consumer), findsNothing);
          expect(
            find.text('closing'),
            showClosing ? findsOneWidget : findsNothing,
          );
          expect(
            done.settled,
            isFalse,
            reason: 'the resource is still releasing',
          );
          h.disposeGate!.complete();
          await settle(tester, until: () => done.settled);
          expect(done.settled, isTrue);
          await _remove(tester);
        });
      }

      testWidgets('closing replaces a pending initialization notification', (
        tester,
      ) async {
        final h = _Harness(family);
        await tester.pumpWidget(_app(h.scope()));
        // Readiness is applied at the end of a frame. Stop there, before the
        // notify-only rebuild it queued has had a chance to run.
        await settle(tester, until: () => h.context.isInitialized);
        expect(h.context.isInitialized, isTrue);
        final done = _Outcome(h.context.close());
        await tester.pump();

        expect(find.text('closing'), findsOneWidget);
        expect(find.byType(_Consumer), findsNothing);
        await settle(tester, until: () => done.settled);
        expect(done.settled, isTrue);
        await _remove(tester);
      });

      for (final showClosing in [false, true]) {
        testWidgets('class-based closing hook (showClosing=$showClosing)', (
          tester,
        ) async {
          final h = _Harness(family, showClosing: showClosing);
          final Widget scope = switch (family) {
            _Family.asyncScope => _ClassScope(h),
            _Family.dataScope => _ClassDataScope(h),
            _Family.controllerScope => _ClassControllerScope(h),
          };
          await tester.pumpWidget(_app(scope));
          await tester.pumpAndSettle();
          final done = _Outcome(h.context.close());
          await tester.pump();
          expect(
            find.text('class closing'),
            showClosing ? findsOneWidget : findsNothing,
          );
          await settle(tester, until: () => done.settled);
          expect(done.settled, isTrue);
          expect(done.failure, isNull);
          expect(h.releases, 1);
          await _remove(tester);
        });
      }

      testWidgets('closing remounts the same widget type and key', (
        tester,
      ) async {
        final h = _Harness(family);
        h
          ..body = _ReusedBranch(h, key: const ValueKey('branch'))
          ..closingBody = _ReusedBranch(
            h,
            key: const ValueKey('branch'),
            closing: true,
          );
        await tester.pumpWidget(_app(h.scope()));
        await tester.pumpAndSettle();
        final done = _Outcome(h.context.close());
        await settle(tester, until: () => done.settled);

        expect(done.settled, isTrue);
        expect(done.failure, isNull);
        expect(h.events, ['child.dispose', 'resource.dispose']);
        expect(find.text('closing'), findsOneWidget);
        await _remove(tester);
      });

      if (family != _Family.controllerScope) {
        testWidgets('closes after a synchronous mount failure', (tester) async {
          final error = StateError('mount failed');
          final h = _Harness(family)..mountError = error;
          await tester.pumpWidget(_app(h.scope()));
          expect(tester.takeException(), same(error));
          final done = _Outcome(h.context.close());
          await settle(tester, until: () => done.settled);
          final repeatedFailure = tester.takeException();

          expect(done.settled, isTrue);
          expect(done.failure, isNull);
          expect(repeatedFailure, isNull);
          expect(find.text('closing'), findsOneWidget);
          expect(h.initializations, 0);
          expect(h.releases, 0);
          await _remove(tester);
        });
      }

      testWidgets('finishes if the app pauses before the closing frame', (
        tester,
      ) async {
        final h = _Harness(family);
        await tester.pumpWidget(_app(h.scope()));
        await tester.pumpAndSettle();
        final done = _Outcome(h.context.close());
        // The first check for disabled frames has already run while resumed.
        await tester.idle();
        try {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          for (var i = 0; i < 20 && !done.settled; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)),
            );
            await tester.idle();
          }
          expect(done.settled, isTrue);
          expect(done.failure, isNull);
          expect(h.events, ['child.dispose', 'resource.dispose']);
        } finally {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await _remove(tester);
        }
      });

      testWidgets('releases scopeKey while the closed scope stays mounted', (
        tester,
      ) async {
        final first = _Harness(family, scopeKey: 'shared');
        final second = _Harness(family, scopeKey: 'shared');
        await tester.pumpWidget(
          _app(Column(children: [first.scope(), second.scope()])),
        );
        await tester.pumpAndSettle();
        expect(second.initializations, 0);

        final done = _Outcome(first.context.close());
        await settle(
          tester,
          until: () => done.settled && second.context.isInitialized,
        );

        expect(done.settled, isTrue);
        expect(first.key.currentContext, isNotNull);
        expect(second.context.isInitialized, isTrue);
        expect(first.releases, 1);
        await _remove(tester);
      });

      testWidgets('awaits a child scope before releasing the parent', (
        tester,
      ) async {
        final events = <String>[];
        final parent = _Harness(family, events: events, label: 'parent');
        final child = _Harness(family, events: events, label: 'nested')
          ..disposeGate = Completer<void>();
        parent.body = child.scope();
        await tester.pumpWidget(_app(parent.scope()));
        await tester.pumpAndSettle();
        expect((parent.context as AsyncScopeParent).childrenCount, 1);

        final done = _Outcome(parent.context.close());
        await settle(tester, until: () => child.releases == 1);
        expect(child.releases, 1);
        expect(parent.releases, 0);
        expect(done.settled, isFalse);
        child.disposeGate!.complete();
        await settle(tester, until: () => done.settled);

        expect(done.settled, isTrue);
        expect(done.failure, isNull);
        expect(events, ['child.dispose', 'nested.dispose', 'parent.dispose']);
        expect(tester.takeException(), isNull);
        await _remove(tester);
      });

      testWidgets(
        'concurrent and repeated calls share one successful release',
        (tester) async {
          final h = _Harness(family)..disposeGate = Completer<void>();
          await tester.pumpWidget(_app(h.scope()));
          await tester.pumpAndSettle();
          final context = h.context;
          final first = _Outcome(context.close());
          final second = _Outcome(context.close());
          await settle(tester, until: () => h.releases == 1);
          expect(first.settled, isFalse);
          expect(second.settled, isFalse);
          h.disposeGate!.complete();
          await settle(tester, until: () => first.settled && second.settled);
          final third = _Outcome(context.close());
          await tester.idle();

          expect(first.settled && second.settled && third.settled, isTrue);
          expect([
            first.failure,
            second.failure,
            third.failure,
          ], everyElement(isNull));
          expect(h.releases, 1);
          await _remove(tester);
          final removed = _Outcome(context.close());
          await tester.idle();
          expect(removed.settled, isTrue);
          expect(h.releases, 1);
        },
      );

      testWidgets('every caller receives the same failure and stack', (
        tester,
      ) async {
        final h = _Harness(family)
          ..disposeGate = Completer<void>()
          ..disposalError = StateError('release failed');
        await tester.pumpWidget(_app(h.scope()));
        await tester.pumpAndSettle();
        final context = h.context;
        final reports = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        late _Outcome first;
        late _Outcome second;
        late _Outcome third;
        try {
          FlutterError.onError = reports.add;
          first = _Outcome(context.close());
          second = _Outcome(context.close());
          // Unmount before the closing build: the memo already has a caller.
          await tester.pumpWidget(_app(const SizedBox.shrink()));
          h.disposeGate!.complete();
          await settle(tester, until: () => first.settled && second.settled);
          third = _Outcome(context.close());
          await tester.idle();
        } finally {
          FlutterError.onError = previous;
        }

        expect(first.settled && second.settled && third.settled, isTrue);
        expect(first.failure, same(h.disposalError));
        expect(second.failure, same(first.failure));
        expect(third.failure, same(first.failure));
        expect(first.stack, same(h.disposalStack));
        expect(second.stack, same(first.stack));
        expect(third.stack, same(first.stack));
        expect(reports, isEmpty);
        expect(h.releases, 1);
        await _remove(tester);
      });

      for (final beforeFrame in [true, false]) {
        testWidgets('unmount during close completes once '
            '(beforeFrame=$beforeFrame)', (tester) async {
          final h = _Harness(family)..disposeGate = Completer<void>();
          await tester.pumpWidget(_app(h.scope()));
          await tester.pumpAndSettle();
          final context = h.context;
          final done = _Outcome(context.close());
          if (!beforeFrame) await tester.pump();
          await tester.pumpWidget(_app(const SizedBox.shrink()));
          h.disposeGate!.complete();
          await settle(tester, until: () => done.settled);

          expect(done.settled, isTrue);
          expect(done.failure, isNull);
          expect(h.events, ['child.dispose', 'resource.dispose']);
          expect(h.releases, 1);
          expect((context as AsyncScopeParent).childrenCount, 0);
        });
      }

      for (final retry in [true, false]) {
        testWidgets('a close refused during build allows later teardown '
            '(retry=$retry)', (tester) async {
          final closeNow = ValueNotifier(false);
          addTearDown(closeNow.dispose);
          final h = _Harness(family);
          _Outcome? refusal;
          h.body = ListenableBuilder(
            listenable: closeNow,
            builder: (context, child) {
              if (closeNow.value) refusal = _Outcome(h.context.close());
              return const SizedBox.shrink();
            },
          );
          await tester.pumpWidget(_app(h.scope()));
          await tester.pumpAndSettle();
          closeNow.value = true;
          await tester.pump();
          expect(refusal?.settled, isTrue);
          expect(refusal?.failure, isFlutterError);
          expect(h.releases, 0);

          if (retry) {
            final done = _Outcome(h.context.close());
            await settle(tester, until: () => done.settled);
            expect(done.settled, isTrue);
            expect(done.failure, isNull);
          }
          await _remove(tester);
          expect(h.releases, 1);
        });
      }

      testWidgets('a close refused during build keeps the ready branch', (
        tester,
      ) async {
        final closeNow = ValueNotifier(false);
        addTearDown(closeNow.dispose);
        final h = _Harness(family);
        _Outcome? refusal;
        h.body = ListenableBuilder(
          listenable: closeNow,
          builder: (context, child) {
            if (closeNow.value) refusal = _Outcome(h.context.close());
            return const Text('ready');
          },
        );
        await tester.pumpWidget(_app(h.scope()));
        await tester.pumpAndSettle();
        closeNow.value = true;
        await tester.pump();
        expect(refusal?.failure, isFlutterError);

        // Nothing is being released, so nothing may look closed: the next
        // rebuild of the scope still shows what it showed before the call.
        closeNow.value = false;
        await tester.pumpWidget(_app(h.scope()));
        await tester.pump();

        expect(find.text('ready'), findsOneWidget);
        expect(find.text('closing'), findsNothing);
        expect(h.releases, 0);
        await _remove(tester);
        expect(h.releases, 1);
      });

      testWidgets('closes with frames disabled without a pump', (tester) async {
        final h = _Harness(family);
        await tester.pumpWidget(_app(h.scope()));
        await tester.pumpAndSettle();
        final binding = tester.binding;
        late _Outcome done;
        try {
          binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
          expect(binding.framesEnabled, isFalse);
          done = _Outcome(h.context.close());
          // pump would supply the frame whose absence this test exercises.
          for (var i = 0; i < 20 && !done.settled; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)),
            );
            await tester.idle();
          }
          expect(done.settled, isTrue);
          expect(done.failure, isNull);
          expect(h.events, ['child.dispose', 'resource.dispose']);
          expect(find.text('closing'), findsOneWidget);
        } finally {
          binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
          await _remove(tester);
        }
      });

      testWidgets(
        'a closed GlobalKey scope does not register with a new parent',
        (tester) async {
          final h = _Harness(family);
          final left = _Harness(family)..body = h.scope();
          final right = _Harness(family)..body = const SizedBox.shrink();
          await tester.pumpWidget(
            _app(Column(children: [left.scope(), right.scope()])),
          );
          await tester.pumpAndSettle();
          final context = h.context;
          final done = _Outcome(context.close());
          await settle(tester, until: () => done.settled);
          expect(done.settled, isTrue);
          expect((left.context as AsyncScopeParent).childrenCount, 0);

          left.body = const SizedBox.shrink();
          right.body = h.scope();
          await tester.pumpWidget(
            _app(Column(children: [left.scope(), right.scope()])),
          );
          await tester.pumpAndSettle();

          expect(h.context, same(context));
          expect((right.context as AsyncScopeParent).childrenCount, 0);
          expect(h.initializations, 1);
          expect(h.releases, 1);
          await _remove(tester);
        },
      );
    });
  }
}

enum _Family { asyncScope, dataScope, controllerScope }

enum _Phase { ready, initializing, error }

class _Outcome {
  bool settled = false;
  Object? failure;
  StackTrace? stack;

  _Outcome(Future<void> work) {
    work.then<void>(
      (_) => settled = true,
      onError: (Object error, StackTrace trace) {
        failure = error;
        stack = trace;
        settled = true;
      },
    );
  }
}

class _Harness {
  final _Family family;
  final _Phase phase;
  final Object? scopeKey;
  final bool showClosing;
  final String label;
  final List<String> events;
  final key = GlobalKey();
  final initGate = Completer<void>();
  late final resource = _Resource(this);
  final disposalStack = StackTrace.current;
  Completer<void>? disposeGate;
  Object? disposalError;
  StateError? mountError;
  int initializations = 0;
  int releases = 0;
  Widget? body;
  Widget? closingBody;

  _Harness(
    this.family, {
    this.phase = _Phase.ready,
    this.scopeKey,
    this.showClosing = true,
    this.label = 'resource',
    List<String>? events,
  }) : events = events ?? [];

  AsyncScopeContext<ScopeInheritedWidget> get context =>
      key.currentContext! as AsyncScopeContext<ScopeInheritedWidget>;

  Future<void> initialize([ScopeInitContext? ctx]) async {
    initializations++;
    if (phase == _Phase.error) throw StateError('initialization failed');
    if (phase == _Phase.initializing) {
      ctx?.progress('initializing');
      if (ctx == null) {
        await initGate.future;
      } else {
        await ctx.abandonable(() => initGate.future);
      }
    }
  }

  Future<void> release() async {
    releases++;
    events.add('$label.dispose');
    resource.released = true;
    if (disposeGate case final gate?) await gate.future;
    if (disposalError case final error?) {
      Error.throwWithStackTrace(error, disposalStack);
    }
  }

  Widget scope() {
    Widget ready(BuildContext context) => body ?? _Consumer(this);
    Widget closing(BuildContext context) =>
        closingBody ?? const Text('closing');
    void onMount(BuildContext context) {
      if (mountError case final error?) throw error;
    }

    return switch (family) {
      _Family.asyncScope => AsyncScope(
        key: key,
        scopeKey: scopeKey,
        onMount: onMount,
        initScope: (context, ctx) => initialize(ctx),
        disposeScope: release,
        progressBuilder: (context, progress) => const Text('initializing'),
        errorBuilder: (context, error, stack, progress) => const Text('error'),
        builder: ready,
        closingBuilder: showClosing ? closing : null,
      ),
      _Family.dataScope => AsyncDataScope<_Resource>(
        key: key,
        scopeKey: scopeKey,
        onMount: onMount,
        initData: (context, ctx) async {
          await initialize(ctx);
          return resource;
        },
        disposeData: (data) => data.dispose(),
        progressBuilder: (context, progress) => const Text('initializing'),
        errorBuilder: (context, error, stack, progress) => const Text('error'),
        builder: (context, data) => ready(context),
        closingBuilder: showClosing ? closing : null,
      ),
      _Family.controllerScope => AsyncControllerScope<_Resource>(
        key: key,
        scopeKey: scopeKey,
        createController: (context) => resource,
        progressBuilder: (context) => const Text('initializing'),
        errorBuilder: (context, error, stack) => const Text('error'),
        builder: (context, controller) => ready(context),
        closingBuilder: showClosing ? closing : null,
      ),
    };
  }
}

class _Resource extends ScopeController {
  final _Harness harness;
  bool released = false;

  _Resource(this.harness);

  @override
  Future<void> init() => harness.initialize();

  @override
  Future<void> dispose() => harness.release();
}

class _Consumer extends StatefulWidget {
  final _Harness harness;

  const _Consumer(this.harness);

  @override
  State<_Consumer> createState() => _ConsumerState();
}

class _ConsumerState extends State<_Consumer> {
  late _Resource resource;

  @override
  Widget build(BuildContext context) {
    final h = widget.harness;
    resource = switch (h.family) {
      _Family.asyncScope =>
        AsyncScope.of(context, listen: true).isInitialized
            ? h.resource
            : throw StateError('not ready'),
      _Family.dataScope => AsyncDataScope.of<_Resource>(
        context,
        listen: true,
      ).data,
      _Family.controllerScope => AsyncControllerScope.of<_Resource>(
        context,
        listen: true,
      ).controller,
    };
    return const SizedBox(width: 20, height: 20);
  }

  @override
  void dispose() {
    expect(
      resource.released,
      isFalse,
      reason: 'the consumer can still use its value during dispose',
    );
    widget.harness.events.add('child.dispose');
    super.dispose();
  }
}

Widget _app(Widget child) => AsyncScopeCoordinator(
  child: MaterialApp(home: Center(child: child)),
);

Future<void> _remove(WidgetTester tester) async {
  await tester.pumpWidget(_app(const SizedBox.shrink()));
  await settle(tester, until: () => false, rounds: 3);
}

final class _ClassScope extends AsyncScopeBase<_ClassScope> {
  final _Harness harness;

  _ClassScope(this.harness) : super(key: harness.key);

  @override
  Future<void> initScope(BuildContext context, ScopeInitContext ctx) =>
      harness.initialize(ctx);

  @override
  Future<void> disposeScope() => harness.release();

  @override
  Widget buildOnReady(BuildContext context) => const SizedBox.shrink();

  @override
  Widget buildOnProgress(BuildContext context, Object? progress) =>
      const SizedBox.shrink();

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) => const SizedBox.shrink();

  @override
  Widget? buildOnClosing(BuildContext context) =>
      harness.showClosing ? const Text('class closing') : null;
}

final class _ClassDataScope
    extends AsyncDataScopeBase<_ClassDataScope, _Resource> {
  final _Harness harness;

  _ClassDataScope(this.harness) : super(key: harness.key);

  @override
  Future<_Resource> initData(BuildContext context, ScopeInitContext ctx) async {
    await harness.initialize(ctx);
    return harness.resource;
  }

  @override
  Future<void> disposeData(_Resource data) => data.dispose();

  @override
  Widget buildOnReady(BuildContext context, _Resource data) =>
      const SizedBox.shrink();

  @override
  Widget buildOnProgress(BuildContext context, Object? progress) =>
      const SizedBox.shrink();

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) => const SizedBox.shrink();

  @override
  Widget? buildOnClosing(BuildContext context) =>
      harness.showClosing ? const Text('class closing') : null;
}

final class _ClassControllerScope
    extends AsyncControllerScopeBase<_ClassControllerScope, _Resource> {
  final _Harness harness;

  _ClassControllerScope(this.harness) : super(key: harness.key);

  @override
  _Resource createController(BuildContext context) => harness.resource;

  @override
  Widget buildOnReady(BuildContext context, _Resource controller) =>
      const SizedBox.shrink();

  @override
  Widget buildOnProgress(BuildContext context) => const SizedBox.shrink();

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) => const SizedBox.shrink();

  @override
  Widget? buildOnClosing(BuildContext context) =>
      harness.showClosing ? const Text('class closing') : null;
}

class _ReusedBranch extends StatefulWidget {
  final _Harness harness;
  final bool closing;

  const _ReusedBranch(this.harness, {super.key, this.closing = false});

  @override
  State<_ReusedBranch> createState() => _ReusedBranchState();
}

class _ReusedBranchState extends State<_ReusedBranch> {
  _Resource? _resource;

  @override
  void initState() {
    super.initState();
    if (!widget.closing) _resource = widget.harness.resource;
  }

  @override
  Widget build(BuildContext context) =>
      Text(widget.closing ? 'closing' : 'ready');

  @override
  void dispose() {
    if (_resource case final resource?) {
      expect(resource.released, isFalse);
      widget.harness.events.add('child.dispose');
    }
    super.dispose();
  }
}
