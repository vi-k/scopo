/// A helper class to track initialization progress as a `double` value between
/// 0.0 and 1.0.
///
/// ```dart
/// static Stream<ScopeInitState<double, MyFeatureDeps>> init() async* {
///   final progressIterator = DoubleProgressIterator(count: 3);
///
///   // step 1
///   yield ScopeProgress(progressIterator.nextProgress()); // 0.33
///
///   // step 2
///   yield ScopeProgress(progressIterator.nextProgress()); // 0.66
///
///   // step 3
///   yield ScopeProgress(progressIterator.nextProgress()); // 1.0
///
///   ...
/// }
/// ```
final class DoubleProgressIterator {
  /// The total number of steps.
  final int count;

  /// The current step.
  var _currentStep = 0;

  DoubleProgressIterator({required this.count});

  /// The current step.
  int get currentStep => _currentStep;

  /// Returns the next progress value as a `double` between 0.0 and 1.0.
  double nextProgress() {
    ++_currentStep;

    assert(
      _currentStep <= count,
      'next step ($_currentStep) > count ($count)',
    );

    return _currentStep / count;
  }
}
