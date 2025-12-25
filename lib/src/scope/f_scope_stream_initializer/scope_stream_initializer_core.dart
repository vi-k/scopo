part of '../scope.dart';

abstract base class ScopeStreamInitializerCore<
        W extends ScopeStreamInitializerCore<W, E, T>,
        E extends ScopeStreamInitializerElementBase<W, E, T>,
        T extends Object?>
    extends ScopeStateBuilderCore<W, E, ScopeInitializerState<T>> {
  const ScopeStreamInitializerCore({
    super.key,
    super.tag,
  }) : super(initialState: const ScopeInitializerWaitingForPrevious());

  static E? maybeOf<
          W extends ScopeStreamInitializerCore<W, E, T>,
          E extends ScopeStreamInitializerElementBase<W, E, T>,
          T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<W, E>(
        context,
        listen: listen,
      );

  static E of<
          W extends ScopeStreamInitializerCore<W, E, T>,
          E extends ScopeStreamInitializerElementBase<W, E, T>,
          T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<W, E>(
        context,
        listen: listen,
      );

  static V select<
          W extends ScopeStreamInitializerCore<W, E, T>,
          E extends ScopeStreamInitializerElementBase<W, E, T>,
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

abstract base class ScopeStreamInitializerElementBase<
        W extends ScopeStreamInitializerCore<W, E, T>,
        E extends ScopeStreamInitializerElementBase<W, E, T>,
        T extends Object?>
    extends ScopeStateBuilderElementBase<W, E, ScopeInitializerState<T>>
    with ScopeInitializerElementMixin<W, T> {
  StreamSubscription<void>? _subscription;

  ScopeStreamInitializerElementBase(super.widget);

  @override
  bool get onlyOneInstance;

  Duration? get pauseAfterInitialization;

  @override
  Duration? get disposeTimeout;

  @override
  void Function()? get onDisposeTimeout;

  Stream<ScopeInitState<Object, T>> initAsync();

  @override
  FutureOr<void> disposeAsync(W widget, T value);

  @override
  Widget buildOnState(ScopeInitializerState<T> state);

  @override
  Future<void> _runInitAsync() async {
    await super._runInitAsync();

    try {
      if (!mounted) return;

      _subscription = initAsync().asyncMap((state) async {
        switch (notifier.state) {
          case ScopeInitializerWaitingForPrevious<T>():
          case ScopeInitializerProgress<T>():
            break;

          case ScopeInitializerReady<T>():
            throw StateError('$W already initialized');

          case ScopeInitializerError<T>():
            throw StateError('$W initialization failed');
        }

        switch (state) {
          case ScopeProgress<Object, T>():
            notifier.update(state.toScopeInitializerState());

          case ScopeReady<Object, T>():
            if (pauseAfterInitialization case final pauseAfterInitialization?) {
              await Future<void>.delayed(pauseAfterInitialization);
              if (mounted) {
                notifier.update(state.toScopeInitializerState());
              }
            } else {
              notifier.update(state.toScopeInitializerState());
            }
        }
      }).listen(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          final progress = switch (notifier.state) {
            ScopeInitializerProgress<T>(:final progress) => progress,
            _ => null,
          };
          notifier.update(
            ScopeInitializerError(error, stackTrace, progress: progress),
          );
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
}
