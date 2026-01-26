part of '../../scope.dart';

abstract base class AsyncScopeCore<
    W extends AsyncScopeCore<W, E, T>,
    E extends AsyncScopeElementBase<W, E, T>,
    T extends Object?> extends ScopeModelCore<W, E, AsyncScopeModel<T>> {
  const AsyncScopeCore({
    super.key,
    super.tag,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  static E? maybeOf<W extends AsyncScopeCore<W, E, T>,
          E extends AsyncScopeElementBase<W, E, T>, T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<W, E>(
        context,
        listen: listen,
      );

  static E of<W extends AsyncScopeCore<W, E, T>,
          E extends AsyncScopeElementBase<W, E, T>, T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<W, E>(
        context,
        listen: listen,
      );

  static V select<
          W extends AsyncScopeCore<W, E, T>,
          E extends AsyncScopeElementBase<W, E, T>,
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

abstract base class AsyncScopeElementBase<W extends AsyncScopeCore<W, E, T>,
        E extends AsyncScopeElementBase<W, E, T>, T extends Object?>
    extends ScopeNotifierElementBase<W, E, AsyncScopeModel<T>>
    with ParentScopeMixin, AsyncScopeElementMixin<W, T>
    implements AsyncScopeContext<W, T> {
  final _AsyncScopeNotifier<T> _notifier = _AsyncScopeNotifier<T>();
  late final AsyncScopeModel<T> _model = _notifier.asUnmodifiable();

  AsyncScopeElementBase(super.widget);

  //
  // Overriding block
  //

  @override
  Object? get scopeKey;

  Future<T> asyncInit();

  @override
  Future<void> asyncDispose(W widget, T data);

  @override
  Widget buildOnState(AsyncScopeState<T> state);

  //
  // End of overriding block
  //

  @override
  Future<void> _performAsyncDispose(W widget) =>
      super._performAsyncDispose(widget).whenComplete(_notifier.dispose);

  @override
  AsyncScopeModel<T> get model => _model;

  @override
  Future<void> _innerInit() async {
    try {
      _notifier.update(const AsyncScopeProgress());
      final data = await asyncInit();
      _notifier.update(AsyncScopeReady(data));
    } on Object catch (error, stackTrace) {
      _e(
        'init',
        'failed',
        error: error,
        stackTrace: stackTrace,
      );

      _notifier.update(AsyncScopeError(error, stackTrace));
    } finally {
      _d('init', 'done');
      _initCompleter.complete();
    }
  }
}
