/// A helper class to track initialization progress as an `int` value.
///
/// ```dart
/// static Stream<ScopeInitState<int, MyFeatureDeps>> init() async* {
///   final progressIterator = IntProgressIterator(count: 3);
///
///   // Step 1
///   yield ScopeProgress(progressIterator.nextStep()); // 1
///
///   // Step 2
///   yield ScopeProgress(progressIterator.nextStep()); // 2
///
///   // Step 3
///   yield ScopeProgress(progressIterator.nextStep()); // 3
///
///   ...
/// }
/// ```
final class IntProgressIterator {
  /// The total number of steps.
  final int? count;

  /// The current step.
  var _currentStep = 0;

  IntProgressIterator({this.count});

  /// The current step.
  int get currentStep => _currentStep;

  /// Returns the next step as an `int`.
  int nextStep() {
    ++_currentStep;

    assert(
      count == null || _currentStep <= count!,
      'next step ($_currentStep) > count ($count)',
    );

    return _currentStep;
  }
}
