part of '../scope.dart';

abstract base class ScopeAsyncInitializerCore<
        W extends ScopeAsyncInitializerCore<W, E, T>,
        E extends ScopeAsyncInitializerElementBase<W, E, T>,
        T extends Object?>
    extends ScopeStateBuilderCore<W, E, ScopeInitializerState<T>> {
  const ScopeAsyncInitializerCore({
    super.key,
    super.tag,
  }) : super(initialState: const ScopeInitializerWaitingForPrevious());

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
    extends ScopeStateBuilderElementBase<W, E, ScopeInitializerState<T>>
    with ScopeInitializerElementMixin<W, T>
    implements ScopeInitializerContext<W, T> {
  ScopeAsyncInitializerElementBase(super.widget);

  @override
  bool get onlyOneInstance;

  @override
  Duration? get disposeTimeout;

  @override
  void Function()? get onDisposeTimeout;

  @override
  Future<void> _runInitAsync() async {
    await super._runInitAsync();

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
