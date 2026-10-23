import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';
import 'package:scopo_demo/home/demos/deferred_closing/screen_scope.dart';
import 'package:scopo_demo/utils/console/console.dart';

final class _DisposalObserver extends ScopeObserver {
  final completedSteps = <String>[];
  final timeouts = <TimeoutException>[];

  @override
  void onDisposalProgress(ScopeObservable target, String path) {
    completedSteps.add(path);
  }

  @override
  void onTimeout(
    ScopeObservable target,
    String what,
    TimeoutException error,
    StackTrace stackTrace,
  ) {
    timeouts.add(error);
  }
}

Future<void> _advance(
  WidgetTester tester, {
  required bool Function() until,
}) async {
  // Disposal timeouts use Zone.root timers. Advancing only the fake clock
  // would let four simulated seconds finish before the real three-second
  // timeout, hiding the regression.
  for (var i = 0; i < 400 && !until(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  testWidgets('ScreenScope closes after all four releases without a timeout',
      (tester) async {
    ScopeConfig.reset();
    final previousObserver = ScopeConfig.observer;
    final observer = _DisposalObserver();
    ScopeConfig.observer = observer;
    console.clearAll();
    final frameworkErrors = <FlutterErrorDetails>[];
    final previousErrorHandler = FlutterError.onError;
    FlutterError.onError = frameworkErrors.add;
    var closeFinished = false;
    var completedAtClose = <String>[];
    Object? closeError;
    bool? disposalRequiredAtClose;

    try {
      await tester.pumpWidget(const MaterialApp(home: ScreenScope()));
      await _advance(
        tester,
        until: () => find.text('close').evaluate().isNotEmpty,
      );
      final state = ScreenScope.of(tester.element(find.text('close')));
      final dependencies = state.dependencies;
      unawaited(
        state.close().then<void>(
          (_) {
            completedAtClose = List.of(observer.completedSteps);
            disposalRequiredAtClose = dependencies.root.disposalRequired;
            closeFinished = true;
          },
          onError: (Object error, StackTrace stackTrace) {
            closeError = error;
            closeFinished = true;
          },
        ),
      );
      await _advance(tester, until: () => closeFinished);

      // Drain the remaining releases even when a timeout let close return early.
      await _advance(tester, until: () => observer.completedSteps.length == 4);
    } finally {
      try {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      } finally {
        FlutterError.onError = previousErrorHandler;
        ScopeConfig.observer = previousObserver;
        ScopeConfig.reset();
        console.clearAll();
      }
    }

    expect(closeFinished, isTrue);
    expect(closeError, isNull);
    expect(observer.completedSteps, ['4', '3', '2', '1']);
    expect(observer.timeouts, isEmpty);
    expect(frameworkErrors, isEmpty);
    expect(completedAtClose, ['4', '3', '2', '1']);
    expect(disposalRequiredAtClose, isFalse);
  });
}
