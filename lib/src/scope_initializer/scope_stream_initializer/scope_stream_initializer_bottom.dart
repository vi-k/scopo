part of '../scope_initializer.dart';

abstract base class ScopeStreamInitializerBottom<
        W extends ScopeStreamInitializerBottom<W, E, T>,
        E extends ScopeStreamInitializerElementBase<W, E, T>,
        T extends Object?>
    extends ScopeStateBuilderBottom<W, E, ScopeInitializerState<T>> {
  const ScopeStreamInitializerBottom({
    super.key,
  }) : super(initialState: const ScopeInitializerWaitingForPrevious());

  static E? maybeOf<
          W extends ScopeStreamInitializerBottom<W, E, T>,
          E extends ScopeStreamInitializerElementBase<W, E, T>,
          T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeModelBottom.maybeOf<W, E, ScopeStateModel<ScopeInitializerState<T>>>(
        context,
        listen: listen,
      );

  static E of<
          W extends ScopeStreamInitializerBottom<W, E, T>,
          E extends ScopeStreamInitializerElementBase<W, E, T>,
          T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeModelBottom.of<W, E, ScopeStateModel<ScopeInitializerState<T>>>(
        context,
        listen: listen,
      );

  static V select<
          W extends ScopeStreamInitializerBottom<W, E, T>,
          E extends ScopeStreamInitializerElementBase<W, E, T>,
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

abstract base class ScopeStreamInitializerElementBase<
        W extends ScopeStreamInitializerBottom<W, E, T>,
        E extends ScopeStreamInitializerElementBase<W, E, T>,
        T extends Object?>
    extends ScopeStateBuilderElementBase<W, E, ScopeInitializerState<T>>
    with ScopeInitializerElementMixin<W, T> {
  StreamSubscription<void>? _subscription;

  ScopeStreamInitializerElementBase(super.widget);

  @override
  Key? get disposeKey;

  @override
  Duration? get disposeTimeout;

  @override
  void Function()? get onDisposeTimeout;

  Stream<ScopeProcessState<Object, T>> initAsync();

  @override
  FutureOr<void> disposeAsync(W widget, T value);

  @override
  Widget buildOnState(ScopeInitializerState<T> state);

  @override
  Future<void> runInitAsync() async {
    await super.runInitAsync();

    try {
      if (!mounted) return;

      _subscription = initAsync().listen(
        (state) {
          switch (_notifier.state) {
            case ScopeInitializerWaitingForPrevious<T>():
            case ScopeInitializerProgress<T>():
              break;

            case ScopeInitializerReady<T>():
              throw StateError('$W already initialized');

            case ScopeInitializerError<T>():
              throw StateError('$W initialization failed');
          }

          _notifier.update(state.toScopeInitializerState());
        },
        onError: (Object error, StackTrace stackTrace) {
          final progress = switch (_notifier.state) {
            ScopeInitializerProgress<T>(:final progress) => progress,
            _ => null,
          };
          _notifier.update(
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
