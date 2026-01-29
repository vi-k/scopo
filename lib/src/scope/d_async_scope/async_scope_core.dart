part of '../scope.dart';

abstract base class AsyncScopeCore<W extends AsyncScopeCore<W, E>,
        E extends AsyncScopeElementBase<W, E>>
    extends ScopeModelCore<W, E, AsyncScopeModel> {
  const AsyncScopeCore({
    super.key,
    super.tag,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  static E? maybeOf<W extends AsyncScopeCore<W, E>,
          E extends AsyncScopeElementBase<W, E>>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<W, E>(
        context,
        listen: listen,
      );

  static E
      of<W extends AsyncScopeCore<W, E>, E extends AsyncScopeElementBase<W, E>>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.of<W, E>(
            context,
            listen: listen,
          );

  static V select<W extends AsyncScopeCore<W, E>,
          E extends AsyncScopeElementBase<W, E>, V extends Object?>(
    BuildContext context,
    V Function(E element) selector,
  ) =>
      ScopeContext.select<W, E, V>(
        context,
        selector,
      );
}

abstract base class AsyncScopeElementBase<W extends AsyncScopeCore<W, E>,
        E extends AsyncScopeElementBase<W, E>>
    extends ScopeNotifierElementBase<W, E, AsyncScopeModel>
    with AsyncScopeParent
    implements AsyncScopeContext<W> {
  //
  // Overriding block
  //

  Object? get scopeKey => null;

  Duration? get pauseAfterInitialization => null;

  Stream<AsyncScopeInitState> initAsync() => Stream.value(AsyncScopeReady());

  FutureOr<void> disposeAsync() {}

  Widget buildOnState(AsyncScopeState state);

  //
  // End of overriding block
  //

  @override
  AsyncScopeModel get model => _model.asUnmodifiable();
  final _AsyncScopeNotifier _model = _AsyncScopeNotifier();

  /// Обеспечиваем доступ к виджету во время асинхронной утилизации.
  @override
  W get widget => _widget ?? super.widget;
  W? _widget;

  // ignore: cancel_subscriptions
  StreamSubscription<void>? _subscription;

  /// Disposal may begin before the end of asynchronous initialization.
  /// Therefore, we use [_initCompleter] for synchronization.
  final _initCompleter = Completer<void>();

  AsyncScopeCoordinatorEntry? _asyncScopeEntry;

  AsyncScopeParentEntry? _asyncScopeParentEntry;

  @override
  bool get autoSelfDependence => true;

  @override
  AsyncScopeState get state => model.state;

  @override
  bool get isInitialized => model.state is AsyncScopeReady;

  @override
  bool get hasError => switch (model.state) {
        AsyncScopeWaiting() ||
        AsyncScopeProgress() ||
        AsyncScopeReady() =>
          false,
        AsyncScopeError() => true,
      };

  @override
  Object get error => switch (model.state) {
        AsyncScopeWaiting() ||
        AsyncScopeProgress() ||
        AsyncScopeReady() =>
          throw StateError('No error'),
        AsyncScopeError(:final error) => error,
      };

  @override
  StackTrace get stackTrace => switch (model.state) {
        AsyncScopeWaiting() ||
        AsyncScopeProgress() ||
        AsyncScopeReady() =>
          throw StateError('No error'),
        AsyncScopeError(:final stackTrace) => stackTrace,
      };

  AsyncScopeElementBase(super.widget);

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _performAsyncInit(); // ignore: discarded_futures
  }

  @override
  void dispose() {
    _widget = widget;
    _performAsyncDispose(); // ignore: discarded_futures
    super.dispose();
  }

  @override
  void activate() {
    super.activate();
    // При перемещении виджета в дереве с помощью GlobalKey,
    // регистрируемся заново.
    _registerWithParent();
  }

  void _registerWithParent() {
    if (_asyncScopeParentEntry case final AsyncScopeParentEntry entry) {
      entry.unregister();
      _asyncScopeParentEntry = null;
    }

    AsyncScopeParent? parent;
    visitAncestorElements((e) {
      if (e case final AsyncScopeParent e) {
        parent = e;
        return false;
      }
      return true;
    });

    _asyncScopeParentEntry = (parent ?? asyncScopeRoot).registerChild();
  }

  Future<void> _performAsyncInit() async {
    assert(model.state is AsyncScopeWaiting);

    _i('init');

    // Register with parent scope.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _registerWithParent();
    });

    // Wait for access.
    if (scopeKey case final scopeKey?) {
      _asyncScopeEntry = AsyncScopeCoordinatorEntry();
      _d('init', 'wait for access by key [$scopeKey]');
      await AsyncScopeCoordinator.enter(
        this,
        scopeKey,
        entry: _asyncScopeEntry,
      );
      _d('init', 'access by key [$scopeKey] obtained');

      if (!mounted) {
        _d('init', 'cancelled');
        _initCompleter.complete();
        return;
      }
    }

    _subscription = initAsync().asyncMap((state) async {
      _d(
        'init',
        () => switch (state) {
          AsyncScopeProgress(:final progress) => '$progress',
          AsyncScopeReady() => 'ready',
        },
      );

      switch (_model.state) {
        case AsyncScopeWaiting():
        case AsyncScopeProgress():
          break;
        case AsyncScopeReady():
          throw StateError('$W already initialized');
        case AsyncScopeError():
          throw StateError('$W initialization failed');
      }

      switch (state) {
        case AsyncScopeProgress():
          _model.update(state);
        case AsyncScopeReady():
          if (pauseAfterInitialization case final pauseAfterInitialization?) {
            await Future<void>.delayed(pauseAfterInitialization);
            _model.update(state);
          } else {
            // Делаем так, чтобы последний прогресс успел отобразиться.
            SchedulerBinding.instance
              ..scheduleFrame()
              ..addPostFrameCallback((_) {
                _model.update(state);
              });
          }
          _d('init', 'done');
          _initCompleter.complete();
      }
    }).listen(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        _e(
          'init',
          'failed',
          error: error,
          stackTrace: stackTrace,
        );

        _model.update(
          AsyncScopeError(
            error,
            stackTrace,
            progress: switch (_model.state) {
              AsyncScopeProgress(:final progress) => progress,
              _ => null,
            },
          ),
        );

        _initCompleter.complete();
      },
      cancelOnError: true,
    );

    return _initCompleter.future;
  }

  Future<void> _performAsyncDispose() async {
    _i('dispose');

    // Прерываем инициализацию, если она не завершена.
    if (_subscription case final subscription?) {
      await subscription.cancel();
      if (!_initCompleter.isCompleted) {
        _d('init', 'cancelled');
        _initCompleter.complete();
      }
    }

    if (!_initCompleter.isCompleted) {
      _d('dispose', 'wait initialization');
      await _initCompleter.future;
    }

    if (hasChildren) {
      _d('dispose', () => 'wait children (count: $childrenCount)');
      await waitForChildren();
    }

    try {
      if (model.state case AsyncScopeReady()) {
        _d('dispose', 'dispose');
        final result = disposeAsync();
        if (result is Future<void>) {
          await result;
        }
      } else {
        _d('dispose', 'do not dispose of');
      }

      _d('dispose', 'done');
    } finally {
      _asyncScopeParentEntry?.unregister();

      if (_asyncScopeEntry case final asyncScopeEntry?) {
        _d('dispose', 'exit from $AsyncScopeCoordinator');
        asyncScopeEntry.exit();
        _asyncScopeEntry = null;
      }

      _model.dispose();

      _widget = null;
    }
  }

  @override
  Widget buildChild() => buildOnState(model.state);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AsyncScopeState>('state', model.state));
    if (scopeKey case final scopeKey?) {
      properties.add(DiagnosticsProperty<Object?>('scopeKey', scopeKey));
    }
    if (pauseAfterInitialization case final pauseAfterInitialization?) {
      properties.add(
        DiagnosticsProperty<Duration>(
          'pauseAfterInitialization',
          pauseAfterInitialization,
        ),
      );
    }
  }
}
