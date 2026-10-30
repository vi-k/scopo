part of '../../../scope.dart';

/// Where a [ScopeDependency] is in its lifecycle.
///
/// The seven final classes below are the states. A `switch` over them is
/// exhaustive; the questions asked most often — succeeded, failed, cancelled —
/// have getters on [ScopeDependencyExtension].
///
/// {@category Scope}
sealed class ScopeDependencyState {
  const ScopeDependencyState();

  /// The state as it appears in a tree dump.
  String get description;

  /// The first error this state holds.
  ///
  /// Throws a [StateError] when it holds none — see [hasErrors].
  Object get error => _throwNoErrors();

  /// The stack trace of [error].
  ///
  /// Throws a [StateError] when this state holds no error — see [hasErrors].
  StackTrace get stackTrace => _throwNoErrors();

  /// How many errors this state holds.
  ///
  /// Zero for a state that holds none. Only [ScopeDependencyInitFailed],
  /// [ScopeDependencyDisposalFailed] and [ScopeDependencyCancelled] hold any,
  /// and a cancellation may hold none.
  int get errorCount => 0;

  /// Whether this state holds an error.
  bool get hasErrors => false;

  /// Returns a copy of the errors this state holds, oldest first.
  List<AsyncError> errors() => <AsyncError>[];

  @override
  String toString() => description;

  /// Thrown when errors are asked of a state that holds none.
  static Never _throwNoErrors() => throw StateError('No errors');
}

sealed class _ScopeDependencyAnySuccess extends ScopeDependencyState {
  const _ScopeDependencyAnySuccess();
}

sealed class _ScopeDependencyWithErrors extends ScopeDependencyState {
  final List<AsyncError> _errors;

  _ScopeDependencyWithErrors(Object error, StackTrace stackTrace)
    : _errors = _singleList(AsyncError(error, stackTrace));

  const _ScopeDependencyWithErrors._(this._errors);

  @override
  Object get error =>
      _errors.firstOrNull?.error ?? ScopeDependencyState._throwNoErrors();

  @override
  StackTrace get stackTrace =>
      _errors.firstOrNull?.stackTrace ?? ScopeDependencyState._throwNoErrors();

  @override
  int get errorCount => _errors.length;

  @override
  bool get hasErrors => _errors.isNotEmpty;

  @override
  List<AsyncError> errors() => List.of(_errors);

  _ScopeDependencyWithErrors addError(Object error, StackTrace stackTrace);

  @override
  String toString({bool? showCount, bool showErrors = true}) {
    final count = errorCount;
    showCount ??= count > 1;
    return '$description'
        '${showCount ? ' ($count ${count == 1 ? 'error' : 'errors'})' : ''}'
        '${showErrors && hasErrors ? ': ${!showCount && count == 1 //
                          ? error : errors()}' : ''}';
  }
}

sealed class _ScopeDependencyAnyFailed extends _ScopeDependencyWithErrors {
  _ScopeDependencyAnyFailed(super.error, super.stackTrace);

  const _ScopeDependencyAnyFailed._(super._errors) : super._();
}

sealed class _ScopeDependencyAnyCancelled extends _ScopeDependencyWithErrors {
  _ScopeDependencyAnyCancelled([Object? error, StackTrace? stackTrace])
    : super._(
        error == null
            ? _emptyList<AsyncError>()
            : _singleList(AsyncError(error, stackTrace)),
      );

  const _ScopeDependencyAnyCancelled._(super._errors) : super._();
}

/// {@category Scope}
final class ScopeDependencyInitial extends _ScopeDependencyAnySuccess {
  /// Creates the state of a dependency not started yet.
  const ScopeDependencyInitial();

  @override
  String get description => 'not initialized';
}

/// {@category Scope}
final class ScopeDependencyInitFailed extends _ScopeDependencyAnyFailed {
  /// Creates the state of a dependency whose initialization failed.
  ScopeDependencyInitFailed(super.error, super.stackTrace);

  ScopeDependencyInitFailed._(super._errors) : super._();

  @override
  String get description => 'failed';

  @override
  ScopeDependencyInitFailed addError(Object error, StackTrace stackTrace) =>
      ScopeDependencyInitFailed._(
        _errors.withAdded(AsyncError(error, stackTrace)),
      );
}

/// {@category Scope}
final class ScopeDependencyCancelled extends _ScopeDependencyAnyCancelled {
  /// Creates the state of a dependency whose initialization was cancelled.
  ScopeDependencyCancelled([super.error, super.stackTrace]);

  const ScopeDependencyCancelled._(super._errors) : super._();

  @override
  String get description => errorCount == 0
      ? 'cancelled'
      : 'cancelled with ${errorCount == 1 ? 'error' : 'errors'}';

  @override
  ScopeDependencyCancelled addError(Object error, StackTrace stackTrace) =>
      ScopeDependencyCancelled._(
        _errors.withAdded(AsyncError(error, stackTrace)),
      );
}

/// {@category Scope}
final class ScopeDependencyInitialized extends _ScopeDependencyAnySuccess {
  /// Creates the state of an initialized dependency.
  const ScopeDependencyInitialized();

  @override
  String get description => 'initialized';
}

/// {@category Scope}
final class ScopeDependencyDisposalFailed extends _ScopeDependencyAnyFailed {
  /// Creates the state of a dependency whose disposal failed.
  ScopeDependencyDisposalFailed(super.error, super.stackTrace);

  ScopeDependencyDisposalFailed._(super._errors) : super._();

  @override
  String get description => 'disposal failed';

  @override
  ScopeDependencyDisposalFailed addError(Object error, StackTrace stackTrace) =>
      ScopeDependencyDisposalFailed._(
        _errors.withAdded(AsyncError(error, stackTrace)),
      );
}

/// The state of a dependency whose teardown ran and let go of what it held.
///
/// A group carries it once the walk has been through every child of it. A
/// teardown that raised what a disposer threw ends in
/// [ScopeDependencyDisposalFailed] instead — the walk reached its end there
/// too, and the state is what says the difference.
///
/// {@category Scope}
final class ScopeDependencyDisposed extends _ScopeDependencyAnySuccess {
  /// Creates the state of a disposed dependency.
  const ScopeDependencyDisposed();

  @override
  String get description => 'disposed';
}

/// {@category Scope}
final class ScopeDependencyNoDisposalRequired extends ScopeDependencyDisposed {
  /// Creates the state of a dependency that had nothing to release.
  const ScopeDependencyNoDisposalRequired();

  @override
  String get description => 'no disposal required';
}

/// Returns an empty immutable list.
///
/// This function exists to:
/// 1) prevent the list from being modified,
/// 2) make such lists internally identical.
List<T> _emptyList<T>() =>
    List<T>.generate(0, (i) => throw UnimplementedError(), growable: false);

/// Returns an immutable list of a single element.
///
/// This function exists to:
/// 1) prevent the list from being modified,
/// 2) make such lists internally identical.
List<T> _singleList<T>(T element) =>
    List<T>.generate(1, (i) => element, growable: false);

/// Returns an immutable list holding this list and one more element.
///
/// This function exists to:
/// 1) prevent the list from being modified,
/// 2) make such lists internally identical.
extension<T> on List<T> {
  List<T> withAdded(T element) => List.generate(
    length + 1,
    (i) => i < length ? this[i] : element,
    growable: false,
  );
}
