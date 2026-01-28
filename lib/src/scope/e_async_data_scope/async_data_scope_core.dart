part of '../scope.dart';

abstract base class AsyncDataScopeCore<
    W extends AsyncDataScopeCore<W, E, T>,
    E extends AsyncDataScopeElementBase<W, E, T>,
    T extends Object?> extends AsyncScopeCore<W, E> {
  const AsyncDataScopeCore({
    super.key,
    super.tag,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  static E? maybeOf<W extends AsyncDataScopeCore<W, E, T>,
          E extends AsyncDataScopeElementBase<W, E, T>, T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<W, E>(
        context,
        listen: listen,
      );

  static E of<W extends AsyncDataScopeCore<W, E, T>,
          E extends AsyncDataScopeElementBase<W, E, T>, T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<W, E>(
        context,
        listen: listen,
      );

  static V select<
          W extends AsyncDataScopeCore<W, E, T>,
          E extends AsyncDataScopeElementBase<W, E, T>,
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

abstract base class AsyncDataScopeElementBase<
        W extends AsyncDataScopeCore<W, E, T>,
        E extends AsyncDataScopeElementBase<W, E, T>,
        T extends Object?> extends AsyncScopeElementBase<W, E>
    implements AsyncDataScopeContext<W, T> {
  //
  // Overriding block
  //

  @override
  Object? get scopeKey => null;

  @override
  Duration? get pauseAfterInitialization => null;

  Stream<AsyncDataScopeInitState<Object, T>> initDataAsync();

  @override
  FutureOr<void> disposeAsync() {}

  @override
  Widget buildOnState(AsyncScopeState state);

  //
  // End of overriding block
  //

  @override
  T get data => _data ?? (throw StateError('Not initialized'));
  T? _data;

  @override
  T? get dataOrNull => _data;

  AsyncDataScopeElementBase(super.widget);

  @override
  Stream<AsyncScopeInitState> initAsync() => initDataAsync().map(
        (state) {
          switch (state) {
            case AsyncDataScopeProgress(:final progress):
              return AsyncScopeProgress(progress);
            case AsyncDataScopeReady(:final data):
              _data = data;
              return AsyncScopeReady();
          }
        },
      );
}
