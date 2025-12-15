part of '../scope_initializer.dart';

abstract base class ScopeStreamInitializerBottom<
        W extends ScopeStreamInitializerBottom<W, E, T>,
        E extends ScopeStreamInitializerElementBase<W, E, T>,
        T extends Object?>
    extends ScopeStateBuilderBottom<W, E, ScopeInitializerState<T>> {
  const ScopeStreamInitializerBottom({
    super.key,
  }) : super(initialState: const ScopeInitializerWaitingForPrevious());
}

abstract base class ScopeStreamInitializerElementBase<
        W extends ScopeStreamInitializerBottom<W, E, T>,
        E extends ScopeStreamInitializerElementBase<W, E, T>,
        T extends Object?>
    extends ScopeStateBuilderElementBase<W, E, ScopeInitializerState<T>>
    with ScopeAsyncDisposerElementMixin<W, T> {
  StreamSubscription<void>? _subscription;

  ScopeStreamInitializerElementBase(super.widget);

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

      _subscription = initAsync().listen(
        (state) {
          _notifier.update(state);
        },
        onError: (Object error, StackTrace stackTrace) {
          _notifier.update(ScopeInitializerError(error, stackTrace));
        },
        cancelOnError: true,
      );
    } finally {
      _initCompleter.complete();
    }
  }

  @override
  void dispose() {
    // ignore: discarded_futures
    _subscription?.cancel();
    super.dispose();
  }

  Stream<ScopeProcessState<T>> initAsync();

  @override
  FutureOr<void> disposeAsync(W widget, T value);

  @override
  Widget buildState(ScopeInitializerState<T> state);
}
