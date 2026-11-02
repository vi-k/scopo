import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

/// The notifier a scope keeps its state in.
///
/// Nothing in the suite named it: it reaches it through the scopes that own
/// one, where only the paths those scopes happen to walk are tried. What a user
/// gets by building one directly — which is what it is exported for — went
/// untried, and so did the one decision it makes on its own: whether an update
/// is worth telling the listeners about.
void main() {
  group('ScopeStateNotifier', () {
    test('tells the listeners about every update by default', () {
      final notifier = ScopeStateNotifier<String>('a');
      addTearDown(notifier.dispose);
      var notifications = 0;

      notifier
        ..addListener(() => notifications++)
        ..update('b')
        ..update('b');

      expect(notifier.state, 'b');
      expect(
        notifications,
        2,
        reason:
            'the default `equals` answers false, so even a value equal to '
            'the current one counts as a change: a state that is not a value '
            'type is the common case, and silence would be the wrong default '
            'for it',
      );
    });

    // `shouldNotify` answers whether anybody has to hear about the change, not
    // whether it happened. Skipping the assignment along with the notification
    // -- which is what this used to do, and what this test used to hold down
    // -- left the model holding the *older* of two objects its own comparison
    // called the same. Invisible for a value type, and not for anything with
    // identity behind it.
    test('an update the listeners are not told about is still applied', () {
      final notifier = _Deduplicating('a');
      addTearDown(notifier.dispose);
      var notifications = 0;

      // Equal to 'a' and not the same object: a literal would be canonicalised
      // into the one already there, and then there is nothing to tell apart.
      final second = String.fromCharCodes('a'.codeUnits);
      expect(identical(second, 'a'), isFalse, reason: 'control');

      notifier
        ..addListener(() => notifications++)
        ..update(second);

      expect(
        notifications,
        0,
        reason: 'the comparison of the model says the two are the same',
      );
      expect(
        identical(notifier.state, second),
        isTrue,
        reason: 'and the state is the one last handed over all the same',
      );

      notifier.update('b');

      expect(notifications, 1);
      expect(notifier.state, 'b');
    });
  });
}

/// A notifier that treats equal values as no change, the way the documentation
/// says a value type should.
final class _Deduplicating extends ScopeStateNotifier<String> {
  _Deduplicating(super.initialState);

  @override
  bool shouldNotify(String previous, String current) => previous != current;
}
