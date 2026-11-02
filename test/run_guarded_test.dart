import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'utils/run_guarded.dart';

void main() {
  // `await runZonedGuarded(...)` is what the widget tests used to write, and a
  // body that threw sent its error to the guard and left the awaited future
  // open: the test hung until its timeout and never named the failure.
  test('a body that throws fails the awaited future', () async {
    final guarded = <Object>[];

    await expectLater(
      runGuarded(
        () async => throw StateError('body'),
        (error, stackTrace) => guarded.add(error),
      ),
      throwsStateError,
    );
    expect(guarded, isEmpty);
  });

  test('an error of a discarded future goes to the guard', () async {
    final guarded = <Object>[];

    await runGuarded(() async {
      unawaited(Future<void>.error(StateError('discarded')));
      await pumpEventQueue();
    }, (error, stackTrace) => guarded.add(error));

    expect(guarded.single, isStateError);
  });
}
