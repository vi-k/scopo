part of '../scope.dart';

/// {@category AsyncDataScope}
abstract base class AsyncDataScopeBase<W extends AsyncDataScopeBase<W, T>,
        T extends Object?>
    extends AsyncDataScopeCore<W, _AsyncDataScopeElement<W, T>, T> {
  final Object? scopeKey;
  final Duration? scopeKeyTimeout;
  final void Function()? onScopeKeyTimeout;
  final Duration? waitForChildrenTimeout;
  final void Function()? onWaitForChildrenTimeout;
  final Duration? pauseAfterInitialization;

  const AsyncDataScopeBase({
    super.key,
    super.tag,
    this.scopeKey,
    this.scopeKeyTimeout,
    this.onScopeKeyTimeout,
    this.waitForChildrenTimeout,
    this.onWaitForChildrenTimeout,
    this.pauseAfterInitialization,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  //
  // Overriding block
  //

  Stream<AsyncDataScopeInitState<Object, T>> initData(BuildContext context);

  FutureOr<void> disposeData(T data);

  Widget? buildOnWaiting(BuildContext context) => null;

  Widget buildOnInitializing(BuildContext context, Object? progress);

  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  );

  Widget buildOnReady(BuildContext context, T data);

  //
  // End of overriding block
  //

  @override
  // ignore: library_private_types_in_public_api
  _AsyncDataScopeElement<W, T> createScopeElement() =>
      _AsyncDataScopeElement<W, T>(this as W);

  static AsyncDataScopeContext<W, T>?
      maybeOf<W extends AsyncDataScopeBase<W, T>, T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.maybeOf<W, AsyncDataScopeContext<W, T>>(
            context,
            listen: listen,
          );

  static AsyncDataScopeContext<W, T>
      of<W extends AsyncDataScopeBase<W, T>, T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.of<W, AsyncDataScopeContext<W, T>>(
            context,
            listen: listen,
          );

  static V select<W extends AsyncDataScopeBase<W, T>, T extends Object?,
          V extends Object?>(
    BuildContext context,
    V Function(AsyncDataScopeContext<W, T> context) selector,
  ) =>
      ScopeContext.select<W, AsyncDataScopeContext<W, T>, V>(
        context,
        selector,
      );
}

final class _AsyncDataScopeElement<W extends AsyncDataScopeBase<W, T>,
        T extends Object?>
    extends AsyncDataScopeElementBase<W, _AsyncDataScopeElement<W, T>, T> {
  _AsyncDataScopeElement(super.widget);

  @override
  Object? get scopeKey => widget.scopeKey;

  @override
  Duration? get scopeKeyTimeout => widget.scopeKeyTimeout;

  @override
  void onScopeKeyTimeout() => widget.onScopeKeyTimeout?.call();

  @override
  Duration? get waitForChildrenTimeout => widget.waitForChildrenTimeout;

  @override
  void onWaitForChildrenTimeout() => widget.onWaitForChildrenTimeout?.call();

  @override
  Duration? get pauseAfterInitialization => widget.pauseAfterInitialization;

  @override
  Stream<AsyncDataScopeInitState<Object, T>> initDataAsync() =>
      widget.initData(this);

  @override
  FutureOr<void> disposeAsync() => widget.disposeData(data);

  @override
  Widget buildOnState(AsyncScopeState state) => switch (state) {
        AsyncScopeWaiting() =>
          widget.buildOnWaiting(this) ?? widget.buildOnInitializing(this, null),
        AsyncScopeProgress(:final progress) =>
          widget.buildOnInitializing(this, progress),
        AsyncScopeReady() => widget.buildOnReady(this, data),
        AsyncScopeError(:final error, :final stackTrace) =>
          widget.buildOnError(this, error, stackTrace),
      };

  @override
  void mount(Element? parent, Object? newSlot) {
    _d('mount');
    super.mount(parent, newSlot);
  }

  @override
  void unmount() {
    _d('unmount');
    super.unmount();
  }

  @override
  void activate() {
    _d('activate');
    super.activate();
  }

  @override
  void deactivate() {
    _d('deactivate');
    super.deactivate();
  }
}
