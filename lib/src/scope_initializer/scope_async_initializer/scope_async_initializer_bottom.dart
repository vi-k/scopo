part of '../scope_initializer.dart';

abstract base class ScopeAsyncInitializerBottom<
        W extends ScopeAsyncInitializerBottom<W, E, T>,
        E extends ScopeAsyncInitializerElementBase<W, E, T>,
        T extends Object?>
    extends ScopeStateBuilderBottom<W, E, ScopeInitializerState<T>> {
  const ScopeAsyncInitializerBottom({
    super.key,
  }) : super(initialState: const ScopeInitializerWaitingForPrevious());
}

abstract base class ScopeAsyncInitializerElementBase<
        W extends ScopeAsyncInitializerBottom<W, E, T>,
        E extends ScopeAsyncInitializerElementBase<W, E, T>,
        T extends Object?>
    extends ScopeStateBuilderElementBase<W, E, ScopeInitializerState<T>>
    with ScopeAsyncDisposerElementMixin<W, T> {
  ScopeAsyncInitializerElementBase(super.widget);

  @override
  Key? get _disposeKey;

  @override
  Duration? get _disposeTimeout;

  @override
  void Function()? get _onDisposeTimeout;

  @override
  Future<void> runInitAsync() async {
    await super.runInitAsync();

    try {
      if (!mounted) return;

      _notifier.update(const ScopeProgressV2());
      final value = await initAsync();
      if (mounted) {
        _notifier.update(ScopeReadyV2(value));
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
  Widget buildState(ScopeInitializerState<T> state);
}
