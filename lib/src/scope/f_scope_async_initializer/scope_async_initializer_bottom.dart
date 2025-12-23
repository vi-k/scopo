part of '../scope.dart';

abstract base class ScopeAsyncInitializerBottom<
        W extends ScopeAsyncInitializerBottom<W, E, T>,
        E extends ScopeAsyncInitializerElementBase<W, E, T>,
        T extends Object?>
    extends ScopeStateBuilderBottom<W, E, ScopeInitializerState<T>> {
  const ScopeAsyncInitializerBottom({
    super.key,
  }) : super(initialState: const ScopeInitializerWaitingForPrevious());

  static E? maybeOf<
          W extends ScopeAsyncInitializerBottom<W, E, T>,
          E extends ScopeAsyncInitializerElementBase<W, E, T>,
          T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeModelBottom.maybeOf<W, E, ScopeStateModel<ScopeInitializerState<T>>>(
        context,
        listen: listen,
      );

  static E of<
          W extends ScopeAsyncInitializerBottom<W, E, T>,
          E extends ScopeAsyncInitializerElementBase<W, E, T>,
          T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeModelBottom.of<W, E, ScopeStateModel<ScopeInitializerState<T>>>(
        context,
        listen: listen,
      );

  static V select<
          W extends ScopeAsyncInitializerBottom<W, E, T>,
          E extends ScopeAsyncInitializerElementBase<W, E, T>,
          T extends Object?,
          V extends Object?>(
    BuildContext context,
    V Function(E element) selector,
  ) =>
      ScopeModelBottom.select<W, E, ScopeStateModel<ScopeInitializerState<T>>,
          V>(
        context,
        selector,
      );
}

abstract base class ScopeAsyncInitializerElementBase<
        W extends ScopeAsyncInitializerBottom<W, E, T>,
        E extends ScopeAsyncInitializerElementBase<W, E, T>,
        T extends Object?>
    extends ScopeStateBuilderElementBase<W, E, ScopeInitializerState<T>>
    with ScopeInitializerElementMixin<W, T>
    implements ScopeInitializerContext<W, T> {
  ScopeAsyncInitializerElementBase(super.widget);

  @override
  Key? get disposeKey;

  @override
  Duration? get disposeTimeout;

  @override
  void Function()? get onDisposeTimeout;

  @override
  Future<void> runInitAsync() async {
    await super.runInitAsync();

    try {
      if (!mounted) return;

      notifier.update(const ScopeInitializerProgress());
      final value = await initAsync();
      if (mounted) {
        notifier.update(ScopeInitializerReady(value));
      }
    } on Object catch (error, stackTrace) {
      if (mounted) {
        notifier.update(ScopeInitializerError(error, stackTrace));
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
