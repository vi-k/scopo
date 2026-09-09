import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

import 'utils/settle.dart';

void main() {
  tearDown(ScopeConfig.reset);

  testWidgets('a concurrent branch failure reaches the scope error state',
      (tester) async {
    final failure = StateError('branch failed');
    final dependencies = _ConcurrentDependencies(failure);
    Object? shownError;
    await tester.pumpWidget(
      _wrap(
        AsyncScope(
          initScope: (context, ctx) async {
            await dependencies.init(null, ctx);
          },
          disposeScope: () {},
          progressBuilder: (context, progress) => const Text('loading'),
          errorBuilder: (context, error, stackTrace, progress) {
            shownError = error;
            return const Text('failed');
          },
          builder: (context) => const Text('ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(dependencies.started, ['first', 'second']);
    expect(shownError, isNull);
    expect(find.text('loading'), findsOneWidget);

    dependencies.gate.complete();
    await tester.pumpAndSettle();
    final element = tester.element(find.byType(AsyncScope))
        as AsyncScopeContext<AsyncScope>;
    final reported = tester.takeException();
    expect(element.state, isA<AsyncScopeError>());
    expect(reported, isNull);
    expect(shownError, isA<ScopeDependencyException>());
    expect('$shownError', contains('$failure'));
    expect(find.text('failed'), findsOneWidget);
    expect(find.text('ready'), findsNothing);
    expect(dependencies.released, ['first']);
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pumpAndSettle();
  });

  testWidgets('a body failure is reported to the scope observer exactly once',
      (tester) async {
    final observer = _Errors();
    ScopeConfig.observer = observer;
    final gate = Completer<void>();
    final failure = StateError('body failed');
    Object? shownError;
    await tester.pumpWidget(
      _wrap(
        AsyncScope(
          initScope: (context, ctx) async {
            await gate.future;
            throw failure;
          },
          disposeScope: () {},
          progressBuilder: (context, progress) => const Text('loading'),
          errorBuilder: (context, error, stackTrace, progress) {
            shownError = error;
            return const Text('failed');
          },
          builder: (context) => const Text('ready'),
        ),
      ),
    );
    expect(observer.errors, isEmpty);
    gate.complete();
    await tester.pumpAndSettle();
    expect(observer.errors, [failure]);
    expect(observer.phases, [ScopePhase.initialization]);
    expect(shownError, same(failure));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pumpAndSettle();
  });

  testWidgets('an unattended failure is reported while the body is running',
      (tester) async {
    final observer = _Errors();
    ScopeConfig.observer = observer;
    final gate = Completer<void>();
    final background = Completer<void>();
    final failure = StateError('background failed');
    await tester.pumpWidget(
      _wrap(
        AsyncScope(
          initScope: (context, ctx) async {
            ctx.unattended(() async {
              await background.future;
              throw failure;
            });
            await gate.future;
          },
          disposeScope: () {},
          progressBuilder: (context, progress) => const Text('loading'),
          errorBuilder: (context, error, stackTrace, progress) =>
              Text('$error'),
          builder: (context) => const Text('ready'),
        ),
      ),
    );
    expect(observer.errors, isEmpty);
    background.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), same(failure));
    expect(observer.errors, [failure]);
    expect(observer.phases, [ScopePhase.initialization]);
    expect(find.text('loading'), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('ready'), findsOneWidget);
    expect(observer.errors, [failure]);
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pumpAndSettle();
  });

  testWidgets('a cancellation callback failure is reported and teardown ends',
      (tester) async {
    final observer = _Errors();
    ScopeConfig.observer = observer;
    final gate = Completer<void>();
    final failure = StateError('stop failed');
    var unwound = false;
    await tester.pumpWidget(
      _wrap(
        AsyncScope(
          initScope: (context, ctx) async {
            ctx.onCancel(() => throw failure);
            try {
              await ctx.wait(() => gate.future);
            } finally {
              unwound = true;
            }
          },
          disposeScope: () {},
          progressBuilder: (context, progress) => const Text('loading'),
          errorBuilder: (context, error, stackTrace, progress) =>
              Text('$error'),
          builder: (context) => const Text('ready'),
        ),
      ),
    );
    expect(observer.errors, isEmpty);
    expect(unwound, isFalse);
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), same(failure));
    expect(observer.errors, [failure]);
    expect(observer.phases, [ScopePhase.initializationCancellation]);
    expect(unwound, isTrue);
    gate.complete();
    await tester.pumpAndSettle();
    expect(observer.errors, [failure]);
  });

  for (final cancelDuringCleanup in [false, true]) {
    testWidgets(
        cancelDuringCleanup
            ? 'cancellation during cleanup releases data once without retaining it'
            : 'data built after cancellation is released once without being retained',
        (tester) async {
      final value = Object();
      final bodyGate = Completer<void>();
      final cleanupGate = Completer<void>();
      var cleanupStarted = false;
      final released = <Object>[];
      final ready = <Object>[];
      await tester.pumpWidget(
        _wrap(
          AsyncDataScope<Object>(
            initData: (context, ctx) async {
              if (cancelDuringCleanup) {
                ctx.onDispose(() async {
                  cleanupStarted = true;
                  await cleanupGate.future;
                });
              }
              await bodyGate.future;
              return value;
            },
            disposeData: released.add,
            progressBuilder: (context, progress) => const Text('loading'),
            errorBuilder: (context, error, stackTrace, progress) =>
                Text('$error'),
            builder: (context, data) {
              ready.add(data);
              return const Text('ready');
            },
          ),
        ),
      );
      final element = tester.element(find.byType(AsyncDataScope<Object>))
          as AsyncDataScopeContext<AsyncDataScope<Object>, Object>;
      expect(element.hasData, isFalse);
      expect(released, isEmpty);
      if (cancelDuringCleanup) {
        bodyGate.complete();
        await tester.pumpAndSettle();
        expect(cleanupStarted, isTrue);
        expect(element.hasData, isFalse);
        expect(element.dataOrNull, isNull);
      }
      await tester.pumpWidget(_wrap(const SizedBox.shrink()));
      if (!bodyGate.isCompleted) bodyGate.complete();
      cleanupGate.complete();
      await settle(tester, until: () => released.isNotEmpty);
      await tester.pumpAndSettle();
      expect(released, [value]);
      expect(element.hasData, isFalse);
      expect(element.dataOrNull, isNull);
      expect(() => element.data, throwsStateError);
      expect(ready, isEmpty);
    });
  }
}

Widget _wrap(Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    );

final class _ConcurrentDependencies
    extends ScopeAutoDependencies<_ConcurrentDependencies, void> {
  final Object failure;
  final gate = Completer<void>();
  final started = <String>[];
  final released = <String>[];

  _ConcurrentDependencies(this.failure);

  @override
  ScopeDependency buildDependencies(void context) => concurrent('', [
        dep('first', (dep) async {
          started.add('first');
          dep.dispose = () => released.add('first');
        }),
        dep('second', (dep) async {
          started.add('second');
          await gate.future;
          Error.throwWithStackTrace(failure, StackTrace.current);
        }),
      ]);
}

final class _Errors extends ScopeObserver {
  final errors = <Object>[];
  final phases = <ScopePhase>[];

  @override
  void onError(
    ScopeObservable target,
    ScopePhase phase,
    Object error,
    StackTrace? stackTrace,
  ) {
    errors.add(error);
    phases.add(phase);
  }
}
