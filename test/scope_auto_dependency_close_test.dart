import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

import 'utils/settle.dart';

void main() {
  for (final parallel in [false, true]) {
    for (final count in [1, 2]) {
      testWidgets(
        '${parallel ? "concurrent" : "sequential"} close succeeds with '
        '$count failing disposers and reports every failed step',
        (tester) async {
          final deps = _Dependencies(parallel, count);
          final observer = _Errors();
          final previousObserver = ScopeConfig.observer;
          ScopeConfig.observer = observer;
          addTearDown(() => ScopeConfig.observer = previousObserver);
          late _TestState state;
          await tester.pumpWidget(
            _TestScope(
              initialize: (ctx) => deps.init(null, ctx),
              capture: (value) => state = value,
            ),
          );
          await tester.pumpAndSettle();

          final reports = <FlutterErrorDetails>[];
          final previous = FlutterError.onError;
          Object? closeError;
          var completed = false;
          FlutterError.onError = reports.add;
          try {
            unawaited(
              state.close().then(
                (_) => completed = true,
                onError: (Object error) {
                  closeError = error;
                  completed = true;
                },
              ),
            );
            await settle(tester, until: () => completed);
          } finally {
            FlutterError.onError = previous;
          }

          expect(completed, isTrue);
          expect(closeError, isNull);
          // One report per failed step, each where it failed, and not one
          // more for the failure that leaves the walk.
          expect(reports, hasLength(count));
          final named = [
            for (final report in reports)
              report.exception as ScopeDependencyException,
          ];
          for (final report in named) {
            expect(report.name, startsWith('root/'));
          }
          expect(
            named.map((report) => report.error),
            unorderedEquals(deps.failures),
          );
          final entries = deps.flattenDependenciesWithErrors().toList();
          expect(entries, hasLength(count));
          expect(
            entries.map(
              (info) => (info.dependency.state as ScopeDependencyDisposalFailed)
                  .error,
            ),
            unorderedEquals(deps.failures),
          );
          expect(observer.errors, containsAll(deps.failures));

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
      );
    }
  }

  testWidgets('close forwards a hand-written container disposal failure', (
    tester,
  ) async {
    final deps = _ManualDependencies();
    late _TestState state;
    await tester.pumpWidget(
      _TestScope(
        initialize: (_) async => deps,
        capture: (value) => state = value,
      ),
    );
    await tester.pumpAndSettle();

    var completed = false;
    final check = expectLater(
      state.close(),
      throwsA(same(deps.failure)),
    ).whenComplete(() => completed = true);
    await settle(tester, until: () => completed);
    expect(completed, isTrue);
    await check;

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}

final class _Dependencies extends ScopeAutoDependencies<_Dependencies, void> {
  final bool parallel;
  final List<StateError> failures;

  _Dependencies(this.parallel, int count)
    : failures = [
        for (var i = 0; i < count; i++) StateError('release $i failed'),
      ];

  @override
  ScopeDependency buildDependencies(void context) {
    final leaves = [
      for (var i = 0; i < failures.length; i++)
        dep('leaf$i', (handle) {
          handle.dispose = () async {
            await Future<void>.delayed(Duration.zero);
            throw failures[i];
          };
        }),
    ];

    return parallel ? concurrent('root', leaves) : sequential('root', leaves);
  }
}

final class _ManualDependencies implements ScopeDependencies {
  final failure = StateError('manual release failed');

  @override
  void onUnmount() {}

  @override
  Future<void> dispose() async => throw failure;
}

final class _Errors extends ScopeObserver {
  final errors = <Object>[];

  @override
  void onError(
    ScopeObservable target,
    ScopePhase phase,
    ScopeErrorRoute route,
    Object error,
    StackTrace? stackTrace,
  ) {
    if (phase == ScopePhase.disposal) {
      errors.add(error is ScopeDependencyException ? error.error : error);
    }
  }
}

final class _TestScope
    extends Scope<_TestScope, ScopeDependencies, _TestState> {
  final Future<ScopeDependencies> Function(ScopeInitContext) initialize;
  final void Function(_TestState) capture;

  const _TestScope({required this.initialize, required this.capture});

  @override
  Future<ScopeDependencies> initDependencies(
    BuildContext context,
    ScopeInitContext ctx,
  ) => initialize(ctx);

  @override
  Widget buildOnProgress(BuildContext context, Object? progress) =>
      const SizedBox(width: 50, height: 50);

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) => const SizedBox(width: 50, height: 50);

  @override
  _TestState createState() => _TestState();
}

final class _TestState
    extends ScopeState<_TestScope, ScopeDependencies, _TestState> {
  @override
  Widget build(BuildContext context) {
    params.capture(this);

    return const SizedBox(width: 50, height: 50);
  }
}
