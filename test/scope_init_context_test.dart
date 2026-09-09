import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

import 'utils/settle.dart';

/// The initialization written as a plain `Future`: the progress and the
/// cancellation reach the body through a context instead of through the
/// mechanics of a generator.
void main() {
  group('ScopeInitContext', () {
    testWidgets('reports progress and finishes by returning', (tester) async {
      final gate = Completer<void>();

      await tester.pumpWidget(
        _Host(
          init: (context, ctx) async {
            ctx.progress('connecting');
            await gate.future;
          },
        ),
      );
      await tester.pump();

      expect(
        find.text('initializing: connecting'),
        findsOneWidget,
        reason: 'what `ctx.progress` reported is what is shown',
      );

      gate.complete();
      await tester.pumpAndSettle();

      expect(
        find.text('ready'),
        findsOneWidget,
        reason: 'the body returning is how the scope is told it is ready',
      );
    });

    // The point of the whole exercise. `yield` works in the body of the
    // generator and nowhere else, so reporting a step from a helper meant
    // making the helper a `Stream` too, and its caller, and so on up. A call
    // on the context can be made from anywhere.
    testWidgets('reports progress from a nested function', (tester) async {
      Future<void> openStorage(ScopeInitContext ctx) async {
        ctx.progress('opening storage');
        await Future<void>.delayed(Duration.zero);
      }

      await tester.pumpWidget(
        _Host(init: (context, ctx) => openStorage(ctx)),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('initializing: opening storage'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('ready'), findsOneWidget);
    });

    testWidgets(
      'a scope that leaves the tree cancels the body where it waits',
      (tester) async {
        final log = <String>[];
        final gate = Completer<void>();

        await tester.pumpWidget(
          _Host(
            init: (context, ctx) async {
              try {
                await ctx.wait(() => gate.future);
                log.add('past the wait');
              } finally {
                log.add('finally');
              }
            },
          ),
        );
        await tester.pump();

        expect(log, isEmpty, reason: 'the body is parked on the gate');

        await tester.pumpWidget(const SizedBox.shrink());
        await settle(tester, until: () => log.contains('finally'));

        expect(
          log,
          ['finally'],
          reason: 'the wait ends the moment the scope leaves the tree, and '
              'the body unwinds instead of running on',
        );
        expect(gate.isCompleted, isFalse, reason: 'nobody completed the gate');
      },
    );

    testWidgets('check throws once the scope has given up', (tester) async {
      final log = <String>[];
      final gate = Completer<void>();

      await tester.pumpWidget(
        _Host(
          init: (context, ctx) async {
            await gate.future;
            log.add('past the await');
            ctx.check();
            log.add('past the check');
          },
        ),
      );
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      gate.complete();
      await settle(tester, until: () => log.contains('past the await'));

      expect(
        log,
        ['past the await'],
        reason: 'a bare await does not notice the cancellation, and `check` '
            'right after it is what does',
      );
    });

    testWidgets(
      'a body that throws builds the error branch and keeps the last progress',
      (tester) async {
        await tester.pumpWidget(
          _Host(
            init: (context, ctx) async {
              ctx.progress('connecting');
              await Future<void>.delayed(Duration.zero);

              throw StateError('no connection');
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('error: Bad state: no connection (connecting)'),
          findsOneWidget,
          reason: 'the failure reaches the error branch with the progress it '
              'had reached',
        );
      },
    );

    testWidgets(
      'a scope cancelled after the body finished still releases it',
      (tester) async {
        final log = <String>[];
        final gate = Completer<void>();

        await tester.pumpWidget(
          _Host(
            init: (context, ctx) async {
              // A bare `await`: this body never asks whether it is still
              // wanted, so it runs to its end for a scope that is already
              // gone.
              await gate.future;
              log.add('acquired');
            },
            dispose: () => log.add('released'),
          ),
        );
        await tester.pump();

        await tester.pumpWidget(const SizedBox.shrink());
        gate.complete();
        await settle(tester, until: () => log.contains('released'));

        expect(
          log,
          ['acquired', 'released'],
          reason: 'what a body took after the cancellation is still given back',
        );
      },
    );
  });

  group('ScopeInitJob', () {
    test('starts only when asked, and cannot start twice', () async {
      final gate = Completer<int>();
      var calls = 0;
      final job = ScopeInitJob<int>(
        (ctx) {
          calls++;
          return gate.future;
        },
      );

      await Future<void>.delayed(Duration.zero);
      expect(calls, 0);
      expect(job.isRunning, isFalse);
      expect(job.isFinished, isFalse);
      expect(job.outcome, isNull);

      job.start();
      expect(calls, 1);
      expect(job.isRunning, isTrue);
      expect(job.start, throwsStateError);
      gate.complete(42);
      expect(await job.value, 42);
      expect(
        await job.done,
        isA<Done<int>>().having((o) => o.value, 'value', 42),
      );
      expect(job.start, throwsStateError);
      expect(calls, 1);
    });

    test('cancellation before start drops the body', () async {
      var calls = 0;
      final job = ScopeInitJob<int>((ctx) async => ++calls);

      await job.cancel();
      expect(
        await job.done,
        isA<Cancelled>()
            .having((o) => o.started, 'started', isFalse)
            .having((o) => o.reason, 'reason', CancelReason.manual),
      );
      expect(job.start, throwsStateError);
      expect(calls, 0);

      final started = ScopeInitJob<int>((ctx) async => ++calls)..start();
      expect(await started.value, 1);
      await started.cancel();
      expect(started.isCancelled, isFalse);
      expect(await started.done, isA<Done<int>>());
    });

    test('progress checks cancellation before calling the listener', () async {
      late ScopeInitContext context;
      final gate = Completer<void>();
      final steps = <Object>[];
      final job = ScopeInitJob<void>(
        (ctx) {
          context = ctx;
          return gate.future;
        },
        onProgress: steps.add,
      )..start();

      context.progress('opening');
      expect(steps, ['opening']);
      expect(context.job, same(job));
      final cancelled = job.cancel();
      expect(() => context.progress('too late'), throwsA(isA<Cancelled>()));
      expect(steps, ['opening']);
      gate.complete();
      await cancelled;
      expect(
        await job.done,
        isA<Cancelled>().having((o) => o.started, 'started', isTrue),
      );
    });

    test('wait ends on cancellation while its action finishes later', () async {
      final gate = Completer<int>();
      var actionFinished = false;
      final job = ScopeInitJob<int>(
        (ctx) => ctx.wait(() async {
          final value = await gate.future;
          actionFinished = true;
          return value;
        }),
      )..start();
      await job.cancel();
      expect(await job.done, isA<Cancelled>());
      expect(actionFinished, isFalse);
      gate.complete(42);
      await Future<void>.delayed(Duration.zero);
      expect(actionFinished, isTrue);
      expect(await job.done, isA<Cancelled>());

      final completed = ScopeInitJob<int>((ctx) => ctx.wait(() => 7))..start();
      expect(await completed.value, 7);
      expect(completed.isCancelled, isFalse);
    });

    test('wait does not start an action under cancellation', () async {
      late ScopeInitContext context;
      final gate = Completer<void>();
      var calls = 0;
      final job = ScopeInitJob<void>(
        (ctx) {
          context = ctx;
          return gate.future;
        },
      )..start();
      expect(await context.wait(() => ++calls), 1);
      final cancelled = job.cancel();
      await expectLater(context.wait(() => ++calls), throwsA(isA<Cancelled>()));
      expect(calls, 1);
      gate.complete();
      await cancelled;
    });

    test('onCancel registers once and its remover unregisters', () async {
      late ScopeInitContext context;
      final gate = Completer<void>();
      final calls = <String>[];
      final job = ScopeInitJob<void>(
        (ctx) {
          context = ctx;
          return gate.future;
        },
      )..start();
      context.onCancel(() => calls.add('kept'));
      final remove = context.onCancel(() => calls.add('removed'));
      remove();
      remove();
      expect(calls, isEmpty);
      final cancelled = job.cancel();
      unawaited(job.cancel());
      expect(calls, ['kept']);
      expect(
        () => context.onCancel(() => calls.add('late')),
        throwsA(isA<Cancelled>()),
      );
      gate.complete();
      await cancelled;
      expect(calls, ['kept']);

      final completed = ScopeInitJob<void>(
        (ctx) async {
          ctx.onCancel(() => calls.add('completed'));
        },
      )..start();
      await completed.done;
      await completed.cancel();
      expect(calls, ['kept']);
    });
  });

  group('a child job', () {
    test('is cancelled with its parent', () async {
      final gate = Completer<void>();
      final child = ScopeInitJob<void>((ctx) => ctx.wait(() => gate.future));
      final parent = ScopeInitJob<void>(
        (ctx) async {
          ctx.run(child);
          await child.done;
        },
      )..start();
      expect(child.isCancelled, isFalse);
      await parent.cancel();
      expect(child.isCancelled, isTrue);
      expect(
        await child.done,
        isA<Cancelled>().having((o) => o.reason, 'reason', CancelReason.parent),
      );
      gate.complete();
    });

    test('is cancelled on its own without touching the parent', () async {
      final gate = Completer<void>();
      final child = ScopeInitJob<void>((ctx) => ctx.wait(() => gate.future));
      final parent = ScopeInitJob<void>(
        (ctx) async {
          ctx.run(child);
          await child.done;
        },
      )..start();
      await child.cancel();
      expect(child.isCancelled, isTrue);
      expect(parent.isCancelled, isFalse);
      expect(await parent.done, isA<Done<void>>());
      gate.complete();
    });

    test('tells its own body, and the parent body separately', () async {
      final gate = Completer<void>();
      final told = <String>[];
      final child = ScopeInitJob<void>(
        (ctx) async {
          ctx.onCancel(() => told.add('child'));
          await ctx.wait(() => gate.future);
        },
      );
      final parent = ScopeInitJob<void>(
        (ctx) async {
          ctx
            ..onCancel(() => told.add('parent'))
            ..run(child);
          await ctx.wait(() => gate.future);
        },
      )..start();
      expect(told, isEmpty);
      await child.cancel();
      expect(told, ['child']);
      await parent.cancel();
      expect(told, ['child', 'parent']);
      gate.complete();
    });

    test('starting under a cancelled parent drops the child and throws',
        () async {
      late ScopeInitContext context;
      final gate = Completer<void>();
      var calls = 0;
      final parent = ScopeInitJob<void>(
        (ctx) {
          context = ctx;
          return gate.future;
        },
      )..start();
      final first = ScopeInitJob<void>(
        (ctx) async {
          calls++;
        },
      );
      context.run(first);
      await first.done;
      expect(calls, 1);
      final cancelled = parent.cancel();
      final child = ScopeInitJob<void>(
        (ctx) async {
          calls++;
        },
      );
      expect(() => context.run(child), throwsA(isA<Cancelled>()));
      expect(
        await child.done,
        isA<Cancelled>().having((o) => o.started, 'started', isFalse),
      );
      expect(calls, 1);
      gate.complete();
      await cancelled;
    });
  });
}

final class _Host extends StatelessWidget {
  final Future<void> Function(BuildContext context, ScopeInitContext ctx) init;
  final void Function()? dispose;

  const _Host({required this.init, this.dispose});

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: AsyncScope(
          initScope: init,
          disposeScope: () => dispose?.call(),
          progressBuilder: (context, progress) =>
              Text('initializing: $progress'),
          errorBuilder: (context, error, stackTrace, progress) =>
              Text('error: $error ($progress)'),
          builder: (context) => const Text('ready'),
        ),
      );
}
