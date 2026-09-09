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
  testWidgets('a body that cancels itself does not stay on the loading branch',
      (tester) async {
    final observer = _Errors();
    ScopeConfig.observer = observer;
    Object? shownError;
    await tester.pumpWidget(
      _wrap(
        AsyncScope(
          // The kernel offers this to a body that decides to give up on its
          // own, and `scopo` re-exports the name it throws. What the scope
          // does with the outcome is the scope's own business, and doing
          // nothing leaves the loading branch on screen for good.
          initScope: (context, ctx) async =>
              throw const Cancelled('no session'),
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

    expect(find.text('loading'), findsNothing);
    expect(
      shownError,
      isA<Cancelled>()
          .having((e) => e.reason, 'reason', CancelReason.handler)
          .having((e) => e.description, 'description', 'no session'),
    );
    expect(observer.phases, [ScopePhase.initialization]);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'a body failure covered by a later cancellation is still reported',
      (tester) async {
    final observer = _Errors();
    ScopeConfig.observer = observer;
    final cleanup = Completer<void>();
    final failure = StateError('body failed');
    var cleanupStarted = false;

    await tester.pumpWidget(
      _wrap(
        AsyncScope(
          initScope: (context, ctx) async {
            ctx.onDispose(() async {
              cleanupStarted = true;
              await cleanup.future;
            });
            throw failure;
          },
          disposeScope: () {},
          progressBuilder: (context, progress) => const Text('loading'),
          errorBuilder: (context, error, stackTrace, progress) =>
              const Text('failed'),
          builder: (context) => const Text('ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Nothing yet, and that is the arrangement: the failure is carried by the
    // outcome, not by the observer hook the kernel calls on the way.
    expect(cleanupStarted, isTrue);
    expect(observer.errors, isEmpty);

    // The tree goes away while the cleanup is still parked, so the outcome
    // that arrives is a cancellation and the failure is covered by it.
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    cleanup.complete();
    await tester.pumpAndSettle();

    expect(observer.errors, [failure]);
    expect(observer.phases, [ScopePhase.initializationCancellation]);
    expect(
      tester.takeException(),
      same(failure),
      reason: 'the crash reporter of an application hears it too',
    );
  });

  // The same cover, one job further down. A failure that came out of a child
  // job has already been announced by the time it reaches the body of the
  // parent, and the flag that says "the report of this one was left to the
  // outcome" then meant something it does not: that nobody had spoken yet.
  testWidgets(
      'a child job failure covered by a cancellation is reported once, not twice',
      (tester) async {
    final observer = _Errors();
    ScopeConfig.observer = observer;
    // Held only while the work runs and given back before every `expect`:
    // a `TestFailure` raised while the handler is ours goes into this list
    // instead of to the runner, and the suite then hangs rather than saying
    // what broke. See the fix of L2 in
    // `docs/records/2026-09-09[5]-post-wave-review.md`.
    final reported = <Object>[];
    final previous = FlutterError.onError;
    void collect() =>
        FlutterError.onError = (details) => reported.add(details.exception);
    void giveBack() => FlutterError.onError = previous;
    addTearDown(giveBack);

    final cleanup = Completer<void>();
    final failure = StateError('child failed');
    var cleanupStarted = false;

    collect();

    await tester.pumpWidget(
      _wrap(
        AsyncScope(
          initScope: (context, ctx) async {
            ctx.onDispose(() async {
              cleanupStarted = true;
              await cleanup.future;
            });
            final child = Job.deferred<void>((_) async => throw failure);
            ctx.run(child);
            await child.value;
          },
          disposeScope: () {},
          progressBuilder: (context, progress) => const Text('loading'),
          errorBuilder: (context, error, stackTrace, progress) =>
              const Text('failed'),
          builder: (context) => const Text('ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    giveBack();

    // The child is not a `ScopeInitJob`, so the adapter has nothing to leave
    // the report to and makes it at once. One, and it belongs.
    expect(cleanupStarted, isTrue);
    expect(observer.errors.where((e) => identical(e, failure)), hasLength(1));
    expect(reported.where((e) => identical(e, failure)), hasLength(1));

    // Now the cover: the tree goes while the cleanup is parked, so the outcome
    // of the parent becomes a cancellation. The failure it carried has been
    // spoken about already, and saying it again is what the wave of
    // 2026-09-07 existed to stop.
    collect();
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    cleanup.complete();
    await tester.pumpAndSettle();
    giveBack();

    expect(
      observer.errors.where((e) => identical(e, failure)),
      hasLength(1),
      reason: 'one cause, one line in the observer',
    );
    expect(
      reported.where((e) => identical(e, failure)),
      hasLength(1),
      reason: 'and one in the crash reporter of an application',
    );
    expect(
      observer.phases,
      [ScopePhase.initialization],
      reason: 'the phase of the report that was actually made, and no second '
          'one calling the same failure a cancellation',
    );
  });

  // The same cover, on a job the element does not own. The safety net was the
  // element's, and an element has one job: a child that failed and was then
  // covered by the cancellation had its failure suppressed by the adapter and
  // read by nobody.
  testWidgets('a covered child ScopeInitJob failure is still reported',
      (tester) async {
    final observer = _Errors();
    ScopeConfig.observer = observer;
    final cleanup = Completer<void>();
    final failure = StateError('child body failed');
    var cleanupStarted = false;

    await tester.pumpWidget(
      _wrap(
        AsyncScope(
          initScope: (context, ctx) async {
            final child = ScopeInitJob<void>((inner) async {
              inner.onDispose(() async {
                cleanupStarted = true;
                await cleanup.future;
              });
              throw failure;
            });
            ctx.run(child);
            await child.value;
          },
          disposeScope: () {},
          progressBuilder: (context, progress) => const Text('loading'),
          errorBuilder: (context, error, stackTrace, progress) =>
              const Text('failed'),
          builder: (context) => const Text('ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(cleanupStarted, isTrue);
    expect(observer.errors, isEmpty);

    // The tree goes while the child's cleanup is parked, so the child ends
    // Cancelled and the failure it was carrying has nobody left.
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    cleanup.complete();
    await tester.pumpAndSettle();

    expect(
      observer.errors.where((error) => identical(error, failure)),
      hasLength(1),
      reason: 'the reason a screen never became ready is not something to '
          'lose because the job that had it was one level down',
    );
    for (var i = 0; i < 4; i++) {
      if (tester.takeException() == null) break;
    }
  });

  testWidgets('a Cancelled from a disposer is heard but not reported',
      (tester) async {
    final observer = _Errors();
    ScopeConfig.observer = observer;

    await tester.pumpWidget(
      _wrap(
        AsyncScope(
          initScope: (context, ctx) async {
            ctx.onDispose(() => throw const Cancelled('from a disposer'));
          },
          disposeScope: () {},
          progressBuilder: (context, progress) => const Text('loading'),
          errorBuilder: (context, error, stackTrace, progress) =>
              const Text('failed'),
          builder: (context) => const Text('ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pumpAndSettle();

    // The kernel says it twice and without exceptions: a cancellation is a
    // decision somebody made, not a failure, and none of them reaches the
    // zone. An observer is the one place it is heard.
    expect(observer.errors, hasLength(1));
    expect(observer.errors.single, isA<Cancelled>());
    expect(
      tester.takeException(),
      isNull,
      reason: 'a consumer widget test must not fail on a cancellation the '
          'kernel promised to keep out of the zone',
    );
  });

  testWidgets(
      'a failure of work nobody waits for is not called an '
      'initialization', (tester) async {
    final observer = _Errors();
    ScopeConfig.observer = observer;
    final failure = StateError('the abandoned action failed');
    final release = Completer<void>();

    await tester.pumpWidget(
      _wrap(
        AsyncScope(
          initScope: (context, ctx) async {
            // Handed over rather than awaited: the body returns, the scope
            // becomes ready, and the failure lands long after.
            ctx.unattended(() async {
              await release.future;
              throw failure;
            });
          },
          disposeScope: () {},
          progressBuilder: (context, progress) => const Text('loading'),
          errorBuilder: (context, error, stackTrace, progress) =>
              const Text('failed'),
          builder: (context) => const Text('ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ready'), findsOneWidget);

    release.complete();
    await tester.pumpAndSettle();

    expect(observer.errors, [failure]);
    expect(
      observer.phases,
      [ScopePhase.abandonedWait],
      reason: 'the initialization is long over; calling this one an '
          'initialization failure points at the wrong half of the life',
    );
    expect(tester.takeException(), same(failure));
  });
  // The same rule, the other road. A `Cancelled` from `ctx.onDispose` stops at
  // the observer; one from `dep.dispose` used to go on to `FlutterError` --
  // wrapped in a `ScopeDependencyException`, which is why nobody noticed it
  // was still a cancellation. A consumer who moved the same teardown from one
  // hook to the other got back the red line and the failing widget test.
  testWidgets(
      'a Cancelled from a dependency disposer is heard but not reported',
      (tester) async {
    final observer = _Errors();
    ScopeConfig.observer = observer;
    final dependencies = _CancellingDisposer();

    await tester.pumpWidget(
      _wrap(
        AsyncScope(
          initScope: (context, ctx) async {
            await dependencies.init(null, ctx);
          },
          // The container is the caller's here, so its teardown is the
          // caller's to start -- and it is the container's own report that
          // this test is about.
          disposeScope: dependencies.dispose,
          progressBuilder: (context, progress) => const Text('loading'),
          errorBuilder: (context, error, stackTrace, progress) =>
              const Text('failed'),
          builder: (context) => const Text('ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ready'), findsOneWidget);

    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await settle(tester, until: () => dependencies.disposed);
    await tester.pumpAndSettle();

    expect(dependencies.disposed, isTrue);
    expect(
      tester.takeException(),
      isNull,
      reason: 'a cancellation is a decision somebody made, and the kernel '
          'keeps those out of the zone -- this road has to keep them out too',
    );
  });

  testWidgets('a dependency that fails after the cancellation is reported',
      (tester) async {
    final observer = _Errors();
    ScopeConfig.observer = observer;
    final failure = StateError('the dependency failed after the mark');
    final gate = Completer<void>();
    final dependencies = _LateFailingDependencies(gate, failure);

    await tester.pumpWidget(
      _wrap(
        AsyncScope(
          initScope: (context, ctx) async {
            await dependencies.init(null, ctx);
          },
          disposeScope: () {},
          progressBuilder: (context, progress) => const Text('loading'),
          errorBuilder: (context, error, stackTrace, progress) =>
              const Text('failed'),
          builder: (context) => const Text('ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(dependencies.started, isTrue);

    // The scope goes away while the dependency is still waiting, and what
    // that wait ends with is a failure of its own -- not the cancellation.
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    gate.complete();
    await tester.pumpAndSettle();

    expect(
      observer.errors,
      hasLength(1),
      reason: 'the state of the tree keeps it, but the tree is going away: '
          'the crash reporting of an application has to hear it too -- once',
    );
    final reported = observer.errors.single;
    expect(reported, isA<ScopeDependencyException>());
    expect(
      (reported as ScopeDependencyException).error,
      same(failure),
      reason: 'and what it carries is the failure itself, not a copy',
    );
    expect(
      reported.name,
      'outer/resource',
      reason: 'named the way every other channel of this package names a '
          'dependency: by the path the tree spells, not by the leaf its own '
          'name',
    );
    expect(tester.takeException(), same(reported));
  });
  testWidgets('both arms of a group that fail at once are reported',
      (tester) async {
    final observer = _Errors();
    ScopeConfig.observer = observer;
    final dependencies = _TwoFailingArms();

    await tester.pumpWidget(
      _wrap(
        AsyncScope(
          initScope: (context, ctx) async {
            await dependencies.init(null, ctx);
          },
          disposeScope: () {},
          progressBuilder: (context, progress) => const Text('loading'),
          errorBuilder: (context, error, stackTrace, progress) =>
              const Text('failed'),
          builder: (context) => const Text('ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The group carries the first failure upwards and cancels the arm beside
    // it -- and that arm was already failing on its own. Its failure used to
    // live in the state of the tree and nowhere else, so an application saw
    // one of two dependencies that had gone down.
    expect(
      observer.errors.map((error) => '$error').toList(),
      containsAll(<Matcher>[
        contains('alpha failed'),
        contains('beta failed'),
      ]),
    );
    expect(
      observer.errors,
      hasLength(2),
      reason: 'two arms, two lines: `containsAll` above says both arrived and '
          'nothing about a third saying one of them twice',
    );

    for (var i = 0; i < 4; i++) {
      if (tester.takeException() == null) break;
    }
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pumpAndSettle();
  });
  // The shape beside the one above, and the one the fix of L4 did not reach.
  // There both arms resumed from their own zero delay, so the second was
  // already marked cancelled when it threw and went out through the
  // post-cancel channel. Here they resume from one `Completer`, in the same
  // microtask band, and the second throws before any mark reaches it: the
  // group keeps the first failure and used to drop the second on the floor.
  testWidgets('both arms that fail before the mark are reported too',
      (tester) async {
    final observer = _Errors();
    ScopeConfig.observer = observer;
    final dependencies = _TwoGatedArms();

    await tester.pumpWidget(
      _wrap(
        AsyncScope(
          initScope: (context, ctx) async {
            await dependencies.init(null, ctx);
          },
          disposeScope: () {},
          progressBuilder: (context, progress) => const Text('loading'),
          errorBuilder: (context, error, stackTrace, progress) =>
              const Text('failed'),
          builder: (context) => const Text('ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(dependencies.started, ['left', 'right']);

    dependencies.gate.complete();
    await tester.pumpAndSettle();

    expect(
      dependencies.threw,
      ['left', 'right'],
      reason: 'both arms really did fail, and neither was cancelled first',
    );
    expect(
      observer.errors.map((error) => '$error').toList(),
      containsAll(<Matcher>[
        contains('left failed'),
        contains('right failed'),
      ]),
      reason: 'an application with ordinary crash reporting has two '
          'dependencies down, and used to hear about one',
    );
    expect(
      observer.errors,
      hasLength(2),
      reason: 'two failures, two lines -- and not a third',
    );

    for (var i = 0; i < 4; i++) {
      if (tester.takeException() == null) break;
    }
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pumpAndSettle();
  });

  testWidgets('an error the kernel raises about the job names the scope',
      (tester) async {
    late ScopeInitContext kept;

    await tester.pumpWidget(
      _wrap(
        AsyncScope(
          // Keeping the context is what a consumer does by accident, and
          // asking it something afterwards is how they meet the kernel's own
          // errors. `Job()` named nothing at all in them.
          initScope: (context, ctx) async => kept = ctx,
          disposeScope: () {},
          progressBuilder: (context, progress) => const Text('loading'),
          errorBuilder: (context, error, stackTrace, progress) =>
              const Text('failed'),
          builder: (context) => const Text('ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      () => kept.onDispose(() {}),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('AsyncScope'),
        ),
      ),
    );

    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pumpAndSettle();
  });

  // The same message, one level down, where the key came from the arm's own
  // name -- and an arm of `concurrent('', [...])` has none. An empty key is
  // not the absence of one: the kernel prints `Job()` for it, which is what
  // the key was added to stop.
  testWidgets('a kernel error about an unnamed arm still says which arm',
      (tester) async {
    final dependencies = _AnonymousArms();

    await tester.pumpWidget(
      _wrap(
        AsyncScope(
          initScope: (context, ctx) async {
            await dependencies.init(null, ctx);
          },
          disposeScope: () {},
          progressBuilder: (context, progress) => const Text('loading'),
          errorBuilder: (context, error, stackTrace, progress) =>
              const Text('failed'),
          builder: (context) => const Text('ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(dependencies.kept, isNotNull);

    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    await tester.pumpAndSettle();

    expect(
      () => dependencies.kept!.onDispose(() {}),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('[1]'),
        ),
      ),
      reason: 'the arm has no name of its own, so the message says where it '
          'stood -- anything but `Job()`',
    );
  });
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

final class _LateFailingDependencies
    extends ScopeAutoDependencies<_LateFailingDependencies, void> {
  final Completer<void> gate;
  final StateError failure;
  bool started = false;

  _LateFailingDependencies(this.gate, this.failure);

  // Nested, so that the name in a report has somewhere to be wrong: the leaf
  // asked for its own name says `resource`, and the tree says
  // `outer/resource`.
  @override
  ScopeDependency buildDependencies(void context) => sequential('outer', [
        dep('resource', (_) async {
          started = true;
          await gate.future;
          throw failure;
        }),
      ]);
}

/// A group whose two arms fail in the same turn of the microtask queue.
final class _TwoFailingArms
    extends ScopeAutoDependencies<_TwoFailingArms, void> {
  @override
  ScopeDependency buildDependencies(void context) => concurrent('', [
        dep('alpha', (_) async {
          await Future<void>.delayed(Duration.zero);
          throw StateError('alpha failed');
        }),
        dep('beta', (_) async {
          await Future<void>.delayed(Duration.zero);
          throw StateError('beta failed');
        }),
      ]);
}

/// Two arms that resume from one gate, so both throw before either is marked.
final class _TwoGatedArms extends ScopeAutoDependencies<_TwoGatedArms, void> {
  final gate = Completer<void>();
  final started = <String>[];
  final threw = <String>[];

  @override
  ScopeDependency buildDependencies(void context) => concurrent('', [
        for (final name in const ['left', 'right'])
          dep(name, (_) async {
            started.add(name);
            await gate.future;
            threw.add(name);
            throw StateError('$name failed');
          }),
      ]);
}

/// A dependency whose disposer gives up with a `Cancelled` of its own.
final class _CancellingDisposer
    extends ScopeAutoDependencies<_CancellingDisposer, void> {
  bool disposed = false;

  @override
  ScopeDependency buildDependencies(void context) => dep('resource', (dep) {
        dep.dispose = () {
          disposed = true;
          throw const Cancelled('nothing left to close');
        };
      });
}

/// A group whose arms have no names, holding a dependency that keeps its
/// context -- the ordinary way a consumer meets an error of the kernel's.
final class _AnonymousArms extends ScopeAutoDependencies<_AnonymousArms, void> {
  ScopeInitContext? kept;

  @override
  ScopeDependency buildDependencies(void context) => concurrent('', [
        dep('named', (_) {}),
        _ContextKeeper((ctx) => kept = ctx),
      ]);
}

/// A dependency of somebody else's making that hangs on to its context.
final class _ContextKeeper implements ScopeDependency {
  final void Function(ScopeInitContext ctx) _keep;

  _ContextKeeper(this._keep);

  @override
  final String name = '';

  @override
  final int count = 1;

  @override
  ScopeDependencyState get state => _state;
  ScopeDependencyState _state = const ScopeDependencyInitial();

  @override
  bool get disposalRequired => false;

  @override
  Future<void> init(ScopeInitContext ctx, void Function(String path) onStep) {
    _keep(ctx);
    _state = const ScopeDependencyInitialized();
    return Future<void>.value();
  }

  @override
  void onUnmount() {}

  @override
  Future<void> dispose(void Function(String path) onStep) =>
      Future<void>.value();

  @override
  String get wrappedName => '""';

  @override
  String stateToString() => '$state';
}
