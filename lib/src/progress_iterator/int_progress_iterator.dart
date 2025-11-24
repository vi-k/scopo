final class IntProgressIterator {
  final int? count;
  var _current = 0;

  IntProgressIterator({this.count});

  int get currentStep => _current;

  int nextStep() {
    ++_current;

    assert(
      count == null || _current <= count!,
      'next step ($_current) > count ($count)',
    );

    return _current;
  }
}
