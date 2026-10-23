import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

/// The main import leaves `listen` and `select` on a `Listenable` free.
///
/// Another package is free to put a `listen` and a `select` of its own on the
/// framework's `Listenable` and `ValueListenable`, and `flutter_solo` does. A
/// file that imports both packages used to get `scopo`'s along with the
/// scopes: `listen` was ambiguous, and `select` was worse -- the extension on
/// `L extends Listenable` takes the whole type of the receiver and so is more
/// specific than one on `ValueListenable<S>`, and a call written for the other
/// package was quietly taken by `scopo` and failed to compile with errors about
/// the wrong signature. The two extensions below stand for that package. While
/// `package:scopo/scopo.dart` exports its own, this file does not compile.
void main() {
  test('listen of another package is the only one in sight', () {
    final counter = _Counter();
    addTearDown(counter.dispose);
    var calls = 0;

    final remove = counter.listen(() => calls++);
    counter.increment();
    remove();
    counter.increment();

    expect(calls, 1);
  });

  test('select of another package is the only one in sight', () {
    final counter = _Counter();
    addTearDown(counter.dispose);

    expect(counter.select((state) => state.isEven), isTrue);
    counter.increment();
    expect(counter.select((state) => state.isEven), isFalse);
  });

  test('ListenableSelector stays in the main import', () {
    expect(ListenableSelector, isNotNull);
  });
}

final class _Counter extends ChangeNotifier implements ValueListenable<int> {
  int _value = 0;

  @override
  int get value => _value;

  void increment() {
    _value++;
    notifyListeners();
  }
}

extension _OtherListen on Listenable {
  void Function() listen(void Function() callback) {
    addListener(callback);

    return () => removeListener(callback);
  }
}

extension _OtherSelect<S> on ValueListenable<S> {
  V select<V>(V Function(S state) selector) => selector(value);
}
