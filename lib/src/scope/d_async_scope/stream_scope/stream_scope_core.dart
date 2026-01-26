part of '../../scope.dart';

abstract base class StreamScopeCore<
    W extends StreamScopeCore<W, E, T>,
    E extends StreamScopeElementBase<W, E, T>,
    T extends Object?> extends ScopeModelCore<W, E, AsyncScopeModel<T>> {
  const StreamScopeCore({
    super.key,
    super.tag,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  static E? maybeOf<W extends StreamScopeCore<W, E, T>,
          E extends StreamScopeElementBase<W, E, T>, T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<W, E>(
        context,
        listen: listen,
      );

  static E of<W extends StreamScopeCore<W, E, T>,
          E extends StreamScopeElementBase<W, E, T>, T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<W, E>(
        context,
        listen: listen,
      );

  static V select<
          W extends StreamScopeCore<W, E, T>,
          E extends StreamScopeElementBase<W, E, T>,
          T extends Object?,
          V extends Object?>(
    BuildContext context,
    V Function(E element) selector,
  ) =>
      ScopeContext.select<W, E, V>(
        context,
        selector,
      );
}

abstract base class StreamScopeElementBase<W extends StreamScopeCore<W, E, T>,
        E extends StreamScopeElementBase<W, E, T>, T extends Object?>
    extends ScopeNotifierElementBase<W, E, AsyncScopeModel<T>>
    with ParentScopeMixin, AsyncScopeElementMixin<W, T>
    implements AsyncScopeContext<W, T> {
  final _AsyncScopeNotifier<T> _model = _AsyncScopeNotifier<T>();

  // ignore: cancel_subscriptions
  StreamSubscription<void>? _subscription;

  StreamScopeElementBase(super.widget);

  //
  // Overriding block
  //

  @override
  Object? get scopeKey;

  Duration? get pauseAfterInitialization;

  Stream<ScopeInitState<Object, T>> asyncInit();

  @override
  Future<void> asyncDispose(W widget, T data);

  @override
  Widget buildOnState(AsyncScopeState<T> state);

  //
  // End of overriding block
  //

  @override
  AsyncScopeModel<T> get model => _model;

  @override
  Future<void> _performAsyncDispose(W widget) async {
    if (_subscription case final subscription?) {
      await subscription.cancel();
      if (!_initCompleter.isCompleted) {
        _d('init', 'cancelled');
        _initCompleter.complete();
      }
    }
    await super._performAsyncDispose(widget).whenComplete(_model.dispose);
  }

  @override
  Future<void> _innerInit() async {
    _model.update(const AsyncScopeProgress());
    _subscription = asyncInit().asyncMap((state) async {
      _d(
        'init',
        () => switch (state) {
          ScopeProgress(:final progress) => '$progress',
          ScopeReady(:final data) => 'ready: $data',
        },
      );

      switch (_model.state) {
        case AsyncScopeWaiting<T>():
        case AsyncScopeProgress<T>():
          break;

        case AsyncScopeReady<T>():
          throw StateError('$W already initialized');

        case AsyncScopeError<T>():
          throw StateError('$W initialization failed');
      }

      switch (state) {
        case ScopeProgress<Object, T>():
          _model.update(state.toScopeInitializerState());

        case ScopeReady<Object, T>():
          if (pauseAfterInitialization case final pauseAfterInitialization?) {
            await Future<void>.delayed(pauseAfterInitialization);
            _model.update(state.toScopeInitializerState());
          } else {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              _model.update(state.toScopeInitializerState());
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

        final progress = switch (_model.state) {
          AsyncScopeProgress<T>(:final progress) => progress,
          _ => null,
        };
        _model.update(
          AsyncScopeError(
            error,
            stackTrace,
            progress: progress,
          ),
        );

        _initCompleter.complete();
      },
      cancelOnError: true,
    );

    return _initCompleter.future;
  }
}
