import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

void main() {
  group('ProgressTracker', () {
    test('counts the steps it is asked for', () {
      final tracker = ProgressTracker(3);

      expect('${tracker.currentStep}', '0/3');
      expect(tracker.isCompleted, isFalse);

      expect('${tracker.nextStep()}', '1/3');
      expect('${tracker.nextStep()}', '2/3');
      expect(tracker.isCompleted, isFalse);

      expect('${tracker.nextStep()}', '3/3');
      expect(
        tracker.isCompleted,
        isTrue,
        reason: 'the last step is the one that completes it',
      );
      expect('${tracker.currentStep}', '3/3');
    });

    test('add moves several steps at once', () {
      final tracker = ProgressTracker(10);

      expect('${tracker.addSteps(4)}', '4/10');
      expect('${tracker.addSteps(6)}', '10/10');
      expect(tracker.isCompleted, isTrue);
    });

    test('a step past the total is a mistake in the caller', () {
      final tracker = ProgressTracker(1)..nextStep();

      expect(tracker.nextStep, throwsA(isA<AssertionError>()));
    });

    test('progress is the fraction of the work reported', () {
      final tracker = ProgressTracker(4);

      expect(tracker.currentStep.value, 0.0);
      expect(tracker.addSteps(1).value, 0.25);
      expect(tracker.addSteps(3).value, 1.0);
    });

    test('a task of no steps is complete rather than NaN', () {
      final tracker = ProgressTracker(0);

      expect(tracker.isCompleted, isTrue);
      expect(tracker.currentStep.value, 1.0);
    });

    test('a step backwards past the start is a mistake in the caller', () {
      final tracker = ProgressTracker(3);

      expect(() => tracker.addSteps(-1), throwsA(isA<AssertionError>()));
    });
  });

  group('Progress', () {
    test('carries the pair it was built from', () {
      const progress = Progress(2, 5);

      expect(progress.number, 2);
      expect(progress.total, 5);
      expect(progress.value, 0.4);
      expect('$progress', '2/5');
    });

    // A value type that arrives in `buildOnProgress` and inside
    // `AsyncScopeProgress`, both of which are compared: a selector holding one
    // and a `==` on the progress a scope reports both ask this question, and
    // identity would answer "changed" for two readings of the same step.
    test('two readings of the same step are the same value', () {
      expect(const Progress(2, 5), const Progress(2, 5));
      expect(const Progress(2, 5).hashCode, const Progress(2, 5).hashCode);
      expect(const Progress(2, 5), ProgressTracker(5).addSteps(2));
      expect(const Progress(2, 5), isNot(const Progress(3, 5)));
      expect(const Progress(2, 5), isNot(const Progress(2, 6)));
    });

    test('the fraction holds its promise where asserts are off', () {
      // The assert in `ProgressTracker.add` is the debug half of the
      // promise. A release build steps past the total without a word, and the
      // fraction still has to be something a progress indicator can take.
      expect(const Progress(4, 3).value, 1.0);
      expect(const Progress(0, 0).value, 1.0);
    });
  });
}
