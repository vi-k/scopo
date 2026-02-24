part of '../scope.dart';

/// {@category AsyncScope}
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
      ScopeContext.maybeOf<W, E>(context, listen: listen);

  static E
      of<W extends AsyncScopeCore<W, E>, E extends AsyncScopeElementBase<W, E>>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.of<W, E>(context, listen: listen);

  static V select<W extends AsyncScopeCore<W, E>,
          E extends AsyncScopeElementBase<W, E>, V extends Object?>(
    BuildContext context,
    V Function(E element) selector,
  ) =>
      ScopeContext.select<W, E, V>(context, selector);
}

/// {@category AsyncScope}
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

  Duration? get scopeKeyTimeout => null;

  void onScopeKeyTimeout() {}

  Duration? get waitForChildrenTimeout => null;

  void onWaitForChildrenTimeout() {}

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

  ScopeChildEntry? _asyncScopeParentEntry;

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
    if (_asyncScopeParentEntry case final ScopeChildEntry entry) {
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

    _asyncScopeParentEntry = (parent ?? asyncScopeRoot).registerChild(
      widget.toStringShort(showHashCode: true),
    );
  }

  Future<void> _performAsyncInit() async {
    assert(model.state is AsyncScopeWaiting);

    final initLog = _log.withAddedName('init');
    initLog.d('prepare');

    // Register with parent scope.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _registerWithParent();
    });

    // Wait for access.
    if (scopeKey case final scopeKey?) {
      final entry = AsyncScopeCoordinatorEntry(
        widget.toStringShort(showHashCode: true),
      );
      _asyncScopeEntry = entry;
      initLog.d(() => 'wait for access to [$scopeKey]');
      await AsyncScopeCoordinator.enter(
        this,
        scopeKey,
        entry,
        timeout: scopeKeyTimeout ?? ScopeConfig.defaultScopeKeysTimeout,
        onTimeout: onScopeKeyTimeout,
      );
      if (entry.isCancelled) {
        initLog.d(() => 'access to [$scopeKey] cancelled');
      } else {
        initLog.d(() => 'access to [$scopeKey] obtained');
      }

      if (entry.isCancelled || !mounted) {
        initLog.i('cancelled');
        _initCompleter.complete();
        return;
      }
    }

    initLog.i('initialize...');
    _subscription = initAsync().asyncMap((state) {
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
          initLog.i(() => '${state.progress}');
          _model.update(state);
        case AsyncScopeReady():
          if (pauseAfterInitialization case final pauseAfterInitialization?
              when ScopeConfig.pauseAfterInitializationEnabled) {
            Future<void>.delayed(pauseAfterInitialization, () {
              if (mounted) {
                _model.update(state);
              }
            });
          } else {
            // Делаем так, чтобы последний прогресс успел отобразиться.
            SchedulerBinding.instance
              ..scheduleFrame()
              ..addPostFrameCallback((_) {
                _model.update(state);
              });
          }
          initLog.i('initialized');
          _initCompleter.complete();
      }
    }).listen(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        initLog.e('failed', error: error, stackTrace: stackTrace);

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
      onDone: () {
        if (!_initCompleter.isCompleted) {
          initLog.i('not initialized');
          _initCompleter.complete();
        }
      },
      cancelOnError: true,
    );

    return _initCompleter.future;
  }

  Future<void> _performAsyncDispose() async {
    final disposeLog = _log.withAddedName('dispose');
    disposeLog.d('prepare');

    // Прерываем ожидание доступа, если ещё не завершено.
    if (_asyncScopeEntry case final entry? when entry.isWaiting) {
      disposeLog.d(() => 'cancel waiting for access to [$scopeKey]');
      entry.cancel();
    }

    // Прерываем инициализацию, если она не завершена.
    if (_subscription case final subscription?) {
      // TODO(nashol): сюда прилетят ошибки, возникшие уже после отмены
      await subscription.cancel();
      if (!_initCompleter.isCompleted) {
        _log.withAddedName('init').i('cancelled');
        _initCompleter.complete();
      }
    }

    if (!_initCompleter.isCompleted) {
      disposeLog.d('wait for initialization');
      await _initCompleter.future;
    }

    if (hasChildren) {
      disposeLog.d(() => 'wait for children (count: $childrenCount)');
      var future = waitForChildren();
      final timeout =
          waitForChildrenTimeout ?? ScopeConfig.defaultWaitForChildrenTimeout;
      if (timeout != null) {
        future = future.timeout(timeout);
      }

      try {
        await future;
      } on TimeoutException catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: TimeoutException(
              '${widget.toStringShort(showHashCode: true)}'
              " couldn't wait for the children to complete: $_children",
              timeout,
            ),
            stack: stackTrace,
            library: 'scopo',
          ),
        );
        onWaitForChildrenTimeout();
      } finally {
        _children.clear();
      }
    }

    try {
      if (model.state case AsyncScopeReady()) {
        disposeLog.i('dispose...');
        final result = disposeAsync();
        if (result is Future<void>) {
          await result;
        }
      } else {
        disposeLog.d('do not dispose of');
      }

      disposeLog.i('disposed');
    } on Object {
      disposeLog.e('failed', error: error, stackTrace: stackTrace);
      rethrow;
    } finally {
      _asyncScopeParentEntry?.unregister();

      if (_asyncScopeEntry case final asyncScopeEntry?) {
        disposeLog.d(() => 'exit from [$scopeKey]');
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
