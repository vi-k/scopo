final class DoubleProgressIterator {
  final int count;
  var _current = 0;

  DoubleProgressIterator({required this.count});

  int get currentStep => _current;

  double nextProgress() {
    ++_current;

    assert(
      _current <= count,
      'next step ($_current) > count ($count)',
    );

    return _current / count;
  }
}
