import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

/// What an [AsyncScopeState] renders as.
///
/// A state is read in a log and nowhere else, so its rendering is the whole of
/// what it promises. This file used to count parentheses instead — a property
/// `toString() => ''` has too, which left the promise held by nothing — and
/// the shape that counting was groping at is the one both [AsyncScopeProgress]
/// and [AsyncScopeError] have: a tail that appears only when there is
/// something to put in it.
void main() {
  group('AsyncScopeState.toString', () {
    test('a scope that has not started names itself', () {
      expect('${AsyncScopeWaiting()}', 'AsyncScopeWaiting');
    });

    test('a step with nothing to report names itself', () {
      expect('${AsyncScopeProgress()}', 'AsyncScopeProgress');
    });

    test('a step carries whatever the initialization reported', () {
      expect('${AsyncScopeProgress('loading')}', 'AsyncScopeProgress(loading)');
    });

    test('a finished initialization names itself', () {
      expect('${AsyncScopeReady()}', 'AsyncScopeReady');
    });
  });

  group('AsyncScopeError.toString', () {
    test('names the state, the failure and the stack trace', () {
      final state = AsyncScopeError(
        Exception('boom'),
        StackTrace.fromString('trace'),
      );

      expect('$state', 'AsyncScopeError(Exception: boom, trace)');
    });

    test('adds the last progress reported before the failure', () {
      final state = AsyncScopeError(
        Exception('boom'),
        StackTrace.fromString('trace'),
        progress: 'loading',
      );

      expect(
        '$state',
        'AsyncScopeError(Exception: boom, trace, progress: loading)',
      );
    });
  });
}
