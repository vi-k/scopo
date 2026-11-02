import 'package:scopo/scopo.dart';
import 'package:test/test.dart';

void main() {
  group('the error API of ScopeDependencyStatus', () {
    final trace = StackTrace.current;

    test('a state that holds no error answers empty', () {
      const states = <ScopeDependencyStatus>[
        ScopeDependencyInitial(),
        ScopeDependencyInitialized(),
        ScopeDependencyDisposed(),
        ScopeDependencyNoDisposalRequired(),
      ];
      for (final state in states) {
        expect(state.errors(), isEmpty, reason: '$state');
        expect(state.errorCount, 0, reason: '$state');
        expect(state.hasErrors, isFalse, reason: '$state');
        expect(() => state.error, throwsStateError, reason: '$state');
        expect(() => state.stackTrace, throwsStateError, reason: '$state');
      }
    });

    test('an empty cancellation answers the same', () {
      final state = ScopeDependencyCancelled();
      expect(state.errors(), isEmpty);
      expect(state.errorCount, 0);
      expect(state.hasErrors, isFalse);
      expect(() => state.error, throwsStateError);
    });

    test('a failure answers with what it holds, oldest first', () {
      final ScopeDependencyStatus state = ScopeDependencyInitFailed(
        'first',
        trace,
      ).addError('second', trace);
      expect(state.errors().map((e) => e.error), ['first', 'second']);
      expect(state.errorCount, 2);
      expect(state.hasErrors, isTrue);
      expect(state.error, 'first');
      expect(state.stackTrace, same(trace));
    });

    test('errors() hands out a copy', () {
      final state = ScopeDependencyDisposalFailed('boom', trace);
      state.errors().clear();
      expect(state.errorCount, 1);
    });
  });
}
