part of '../scope.dart';

abstract base class AsyncScopeBase<W extends AsyncScopeBase<W>>
    extends AsyncScopeCore<W, AsyncScopeElement<W>> {
  final Object? scopeKey;
  final Duration? scopeKeyTimeout;
  final void Function()? onScopeKeyTimeout;
  final Duration? waitForChildrenTimeout;
  final void Function()? onWaitForChildrenTimeout;
  final Duration? pauseAfterInitialization;

  const AsyncScopeBase({
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

  Stream<AsyncScopeInitState> initAsync(BuildContext context);

  FutureOr<void> disposeAsync();

  Widget? buildOnWaiting(BuildContext context) => null;

  Widget buildOnInitializing(BuildContext context);

  Widget buildOnReady(BuildContext context);

  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  );

  @override
  AsyncScopeElement<W> createScopeElement() => AsyncScopeElement<W>(this as W);

  static AsyncScopeContext<W>? maybeOf<W extends AsyncScopeBase<W>>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<W, AsyncScopeContext<W>>(
        context,
        listen: listen,
      );

  static AsyncScopeContext<W> of<W extends AsyncScopeBase<W>>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<W, AsyncScopeContext<W>>(
        context,
        listen: listen,
      );

  static V select<W extends AsyncScopeBase<W>, V extends Object?>(
    BuildContext context,
    V Function(AsyncScopeContext<W> context) selector,
  ) =>
      ScopeContext.select<W, AsyncScopeContext<W>, V>(
        context,
        selector,
      );
}

final class AsyncScopeElement<W extends AsyncScopeBase<W>>
    extends AsyncScopeElementBase<W, AsyncScopeElement<W>> {
  AsyncScopeElement(super.widget);

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
  Stream<AsyncScopeInitState> initAsync() => widget.initAsync(this);

  @override
  FutureOr<void> disposeAsync() => widget.disposeAsync();

  @override
  Widget buildOnState(AsyncScopeState state) => switch (state) {
        AsyncScopeWaiting() =>
          widget.buildOnWaiting(this) ?? widget.buildOnInitializing(this),
        AsyncScopeProgress() => widget.buildOnInitializing(this),
        AsyncScopeReady() => widget.buildOnReady(this),
        AsyncScopeError(:final error, :final stackTrace) =>
          widget.buildOnError(this, error, stackTrace),
      };
}
