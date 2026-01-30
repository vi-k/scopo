part of '../../../scope.dart';

/// {@category Scope}
abstract base class ScopeDependencyBase {
  _ScopeDependencyState _state = const _ScopeDependencyStateInitial();

  String get name;
  FutureOr<void> init();
  FutureOr<void> dispose();

  String get state => _state.description;

  bool get hasError => switch (_state) {
        _ScopeDependencyFailedStates() => true,
        _ScopeDependencySuccessStates() => false,
      };

  Object get error => switch (_state) {
        _ScopeDependencyFailedStates(:final error) => error,
        _ScopeDependencySuccessStates() => throw StateError('No error'),
      };

  StackTrace get stackTrace => switch (_state) {
        _ScopeDependencyFailedStates(:final stackTrace) => stackTrace,
        _ScopeDependencySuccessStates() => throw StateError('No error'),
      };

  FutureOr<void> _callInit() {
    assert(_state is _ScopeDependencyStateInitial);
    try {
      final result = init();
      if (result is Future<void>) {
        return result.then(
          (_) {
            _state = const _ScopeDependencyStateInitialized();
          },
          onError: (Object error, StackTrace stackTrace) {
            _state =
                _ScopeDependencyStateInitializationFailed(error, stackTrace);
            Error.throwWithStackTrace(error, stackTrace);
          },
        );
      } else {
        _state = const _ScopeDependencyStateInitialized();
      }
    } on Object catch (error, stackTrace) {
      _state = _ScopeDependencyStateInitializationFailed(error, stackTrace);
      rethrow;
    }
  }

  FutureOr<void> _callDispose() {
    if (_state is! _ScopeDependencyStateInitialized) {
      return null;
    }

    try {
      final result = dispose();
      if (result is Future<void>) {
        return result.then(
          (_) {
            _state = const _ScopeDependencyStateDisposed();
          },
          onError: (Object error, StackTrace stackTrace) {
            _state = _ScopeDependencyStateDisposalFailed(error, stackTrace);
            Error.throwWithStackTrace(error, stackTrace);
          },
        );
      } else {
        _state = const _ScopeDependencyStateDisposed();
      }
    } on Object catch (error, stackTrace) {
      _state = _ScopeDependencyStateDisposalFailed(error, stackTrace);
      rethrow;
    }
  }

  @override
  String toString() => '`$name` $state';
}
