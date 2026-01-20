part of '../scope.dart';

abstract base class ScopeAsyncInitializerCore<
    W extends ScopeAsyncInitializerCore<W, E, T>,
    E extends ScopeAsyncInitializerElementBase<W, E, T>,
    T extends Object?> extends ScopeModelCore<W, E, ScopeInitializerModel<T>> {
  const ScopeAsyncInitializerCore({
    super.key,
    super.tag,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  static E? maybeOf<
          W extends ScopeAsyncInitializerCore<W, E, T>,
          E extends ScopeAsyncInitializerElementBase<W, E, T>,
          T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<W, E>(
        context,
        listen: listen,
      );

  static E of<
          W extends ScopeAsyncInitializerCore<W, E, T>,
          E extends ScopeAsyncInitializerElementBase<W, E, T>,
          T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<W, E>(
        context,
        listen: listen,
      );

  static V select<
          W extends ScopeAsyncInitializerCore<W, E, T>,
          E extends ScopeAsyncInitializerElementBase<W, E, T>,
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

abstract base class ScopeAsyncInitializerElementBase<
        W extends ScopeAsyncInitializerCore<W, E, T>,
        E extends ScopeAsyncInitializerElementBase<W, E, T>,
        T extends Object?>
    extends ScopeNotifierElementBase<W, E, ScopeInitializerModel<T>>
    with ScopeInitializerElementMixin<W, T>
    implements ScopeInitializerContext<W, T> {
  final _ScopeInitializerNotifier<T> _notifier = _ScopeInitializerNotifier<T>();
  late final ScopeInitializerModel<T> _model = _notifier.asUnmodifiable();

  ScopeAsyncInitializerElementBase(super.widget);

  @override
  void dispose() {
    super.dispose();
    _notifier.dispose();
  }

  @override
  ScopeInitializerModel<T> get model => _model;

  @override
  LifecycleCoordinator<Object>? get exclusiveCoordinator;

  @override
  Key? get exclusiveCoordinatorKey;

  @override
  LifecycleCoordinator<Object>? get disposeCoordinator;

  @override
  Key? get disposeCoordinatorKey;

  @override
  Future<void> _runInitAsync() async {
    await super._runInitAsync();

    try {
      if (!mounted) return;

      _notifier.update(const ScopeInitializerProgress());
      final value = await initAsync();
      if (mounted) {
        _notifier.update(ScopeInitializerReady(value));
      }
    } on Object catch (error, stackTrace) {
      if (mounted) {
        _notifier.update(ScopeInitializerError(error, stackTrace));
      }
    } finally {
      _initCompleter.complete();
    }
  }

  Future<T> initAsync();

  @override
  FutureOr<void> disposeAsync(W widget, T value);

  @override
  Widget buildOnState(ScopeInitializerState<T> state);
}
