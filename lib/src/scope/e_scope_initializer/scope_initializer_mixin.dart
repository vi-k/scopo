part of '../scope.dart';

base mixin ScopeInitializerElementMixin<W extends ScopeInheritedWidget,
        T extends Object?>
    on ScopeModelInheritedElement<W, ScopeInitializerModel<T>> {
  static final _exclusiveCoordinators = <Key, LifecycleCoordinator<Object>>{};
  static final _disposeCoordinators = <Key, LifecycleCoordinator<Object>>{};

  final _initCompleter = Completer<void>();
  LifecycleCoordinator<Object>? _exclusiveCoordinator;
  LifecycleCoordinator<Object>? _disposeCoordinator;

  bool get autoSelfDependence => true;

  LifecycleCoordinator<Object>? get exclusiveCoordinator => null;
  Key? get exclusiveCoordinatorKey => null;

  LifecycleCoordinator<Object>? get disposeCoordinator => null;
  Key? get disposeCoordinatorKey => null;

  bool get isInitialized => model.state is ScopeInitializerReady<T>;

  T get value => switch (model.state) {
        ScopeInitializerWaitingForPrevious() ||
        ScopeInitializerProgress() =>
          throw StateError('Not initialized'),
        ScopeInitializerReady(:final value) => value,
        ScopeInitializerError(:final error, :final stackTrace) =>
          Error.throwWithStackTrace(error, stackTrace),
      };

  T? get valueOrNull => switch (model.state) {
        ScopeInitializerWaitingForPrevious() ||
        ScopeInitializerProgress() ||
        ScopeInitializerError() =>
          null,
        ScopeInitializerReady(:final value) => value,
      };

  bool get hasError => model.state is ScopeInitializerError<T>;

  Object get error => switch (model.state) {
        ScopeInitializerWaitingForPrevious() ||
        ScopeInitializerProgress() ||
        ScopeInitializerReady() =>
          throw StateError('No error'),
        ScopeInitializerError(:final error) => error,
      };

  StackTrace get stackTrace => switch (model.state) {
        ScopeInitializerWaitingForPrevious() ||
        ScopeInitializerProgress() ||
        ScopeInitializerReady() =>
          throw StateError('No error'),
        ScopeInitializerError(:final stackTrace) => stackTrace,
      };

  @override
  void init() {
    super.init();

    if (exclusiveCoordinatorKey case final exclusiveCoordinatorKey?) {
      // Создаём внутренний координатор, используя переданный ключ.
      _exclusiveCoordinator =
          _exclusiveCoordinators[exclusiveCoordinatorKey] ??=
              LifecycleCoordinator<Object>();
    } else if (exclusiveCoordinator case final exclusiveCoordinator?) {
      // Используем пользовательский координатор.
      _exclusiveCoordinator = exclusiveCoordinator;
    }

    if (disposeCoordinatorKey case final disposeCoordinatorKey?) {
      // Создаём внутренний координатор, используя переданный ключ.
      _disposeCoordinator = _disposeCoordinators[disposeCoordinatorKey] ??=
          LifecycleCoordinator<Object>();
    } else if (disposeCoordinator case final disposeCoordinator?) {
      // Используем пользовательский координатор.
      _disposeCoordinator = disposeCoordinator;
    }

    // ignore: discarded_futures
    _runInitAsync();
  }

  @override
  void dispose() {
    // ignore: discarded_futures
    _runDisposeAsync(widget);
    super.dispose();
  }

  @mustCallSuper
  Future<void> _runInitAsync() async {
    assert(model.state is ScopeInitializerWaitingForPrevious);

    if (_exclusiveCoordinator case final exclusiveCoordinator?) {
      await exclusiveCoordinator.acquire(this);
    }
  }

  Future<void> _runDisposeAsync(W widget) async {
    if (!_initCompleter.isCompleted) {
      await _initCompleter.future;
    }

    try {
      if (model.state case ScopeInitializerReady<T>(:final value)) {
        if (_disposeCoordinator case final disposeCoordinator?) {
          await disposeCoordinator.acquire(this);
        }

        final f = disposeAsync(widget, value);
        if (f is Future<void>) {
          await f;
        }
      }
    } finally {
      if (_disposeCoordinator case final disposeCoordinator?) {
        disposeCoordinator.release(this);

        // Если это был внутренний координатор и очередь на его захват пуста,
        // удаляем его из списка.
        if (disposeCoordinatorKey case final disposeCoordinatorKey?
            when disposeCoordinator.isEmpty) {
          _disposeCoordinators.remove(disposeCoordinatorKey);
        }
      }

      if (_exclusiveCoordinator case final exclusiveCoordinator?) {
        exclusiveCoordinator.release(this);

        // Если это был внутренний координатор и очередь на его захват пуста,
        // удаляем его из списка.
        if (exclusiveCoordinatorKey case final exclusiveCoordinatorKey?
            when exclusiveCoordinator.isEmpty) {
          _exclusiveCoordinators.remove(exclusiveCoordinatorKey);
        }
      }
    }
  }

  FutureOr<void> disposeAsync(W widget, T value);

  @override
  Widget buildChild() => buildOnState(model.state);

  Widget buildOnState(ScopeInitializerState<T> state);
}
