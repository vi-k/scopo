part of '../scope.dart';

sealed class _ScopeDependencyState {
  const _ScopeDependencyState();

  String get description;
}

final class _ScopeDependencyStateInitial extends _ScopeDependencyState {
  const _ScopeDependencyStateInitial();

  @override
  String get description => 'not initialized';
}

final class _ScopeDependencyStateInitializationFailed
    extends _ScopeDependencyState {
  final Object error;
  final StackTrace stackTrace;

  const _ScopeDependencyStateInitializationFailed(this.error, this.stackTrace);

  @override
  String get description => 'initialization failed';
}

final class _ScopeDependencyStateInitialized extends _ScopeDependencyState {
  const _ScopeDependencyStateInitialized();

  @override
  String get description => 'initialized';
}

final class _ScopeDependencyStateDisposed extends _ScopeDependencyState {
  const _ScopeDependencyStateDisposed();

  @override
  String get description => 'disposed';
}

final class _ScopeDependencyStateDisposalFailed extends _ScopeDependencyState {
  final Object error;
  final StackTrace stackTrace;

  const _ScopeDependencyStateDisposalFailed(this.error, this.stackTrace);

  @override
  String get description => 'disposal failed';
}

abstract base class ScopeDependencyBase {
  _ScopeDependencyState _state = const _ScopeDependencyStateInitial();

  bool get hasError => switch (_state) {
        _ScopeDependencyStateInitializationFailed() ||
        _ScopeDependencyStateDisposalFailed() =>
          true,
        _ScopeDependencyStateInitial() ||
        _ScopeDependencyStateInitialized() ||
        _ScopeDependencyStateDisposed() =>
          false,
      };

  Object get error => switch (_state) {
        _ScopeDependencyStateInitializationFailed(:final error) ||
        _ScopeDependencyStateDisposalFailed(:final error) =>
          error,
        _ScopeDependencyStateInitial() ||
        _ScopeDependencyStateInitialized() ||
        _ScopeDependencyStateDisposed() =>
          throw StateError('No error'),
      };

  StackTrace get stackTrace => switch (_state) {
        _ScopeDependencyStateInitializationFailed(:final stackTrace) ||
        _ScopeDependencyStateDisposalFailed(:final stackTrace) =>
          stackTrace,
        _ScopeDependencyStateInitial() ||
        _ScopeDependencyStateInitialized() ||
        _ScopeDependencyStateDisposed() =>
          throw StateError('No error'),
      };

  String get name;
  FutureOr<void> init();
  FutureOr<void> dispose();

  String get state => _state.description;

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

final class ScopeDependency extends ScopeDependencyBase {
  @override
  final String name;

  final FutureOr<void> Function() onInit;
  final FutureOr<void> Function()? onDispose;

  ScopeDependency(
    this.name,
    this.onInit, {
    this.onDispose,
  });

  @override
  FutureOr<void> init() => onInit();

  @override
  FutureOr<void> dispose() => onDispose?.call();
}

abstract base class ScopeDependenciesQueue<T extends ScopeDependencies>
    implements ScopeDependencies {
  List<List<ScopeDependencyBase>>? _queue;

  /// Set the queue of dependencies.
  // ignore: use_setters_to_change_properties
  void setQueue(List<List<ScopeDependencyBase>> queue) {
    _queue = queue;
  }

  List<List<ScopeDependencyBase>> buildQueue(BuildContext context);

  /// Initialize the scope dependencies.
  Stream<ScopeInitState<double, T>> init(BuildContext context) async* {
    var isInitialized = false;

    try {
      final queue = _queue ??= buildQueue(context);
      final progressIterator = DoubleProgressIterator(count: queue.length);

      d(T, 'init');

      for (final group in queue) {
        d(T, 'init group ${progressIterator.currentStep}');
        try {
          await group.map((e) => e._callInit()).whereType<Future<void>>().wait;
        } finally {
          // Print result.
          for (final dep in group) {
            if (dep._state
                case _ScopeDependencyStateInitializationFailed(
                  :final error,
                  :final stackTrace,
                )) {
              e(T, dep, error: error, stackTrace: stackTrace);
            } else {
              d(T, dep);
            }
          }
        }

        yield ScopeProgress(progressIterator.nextProgress());
      }

      yield ScopeReady(this as T);
      isInitialized = true;
    } finally {
      if (!isInitialized) {
        e(T, 'initialization failed');
        await dispose();
      }
    }
  }

  @override
  Future<void> dispose() async {
    final queue = _queue;
    if (queue == null) {
      return;
    }

    d(T, 'dispose (in reverse order)');

    for (var i = queue.length - 1; i >= 0; i--) {
      final group = queue[i];
      d(T, 'dispose group $i');

      try {
        await group.map((e) => e._callDispose()).whereType<Future<void>>().wait;
        // ignore: avoid_catching_errors
      } on Object {
        // noop
      }

      // Print result.
      for (final dep in group) {
        switch (dep._state) {
          case _ScopeDependencyStateDisposalFailed(
              :final error,
              :final stackTrace,
            ):
            e(T, dep, error: error, stackTrace: stackTrace);

          default:
            d(T, dep);
        }
      }
    }
  }
}
