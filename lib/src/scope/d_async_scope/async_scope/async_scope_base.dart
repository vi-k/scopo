part of '../../scope.dart';

abstract base class AsyncScopeBase<W extends AsyncScopeBase<W, T>,
    T extends Object?> extends AsyncScopeCore<W, AsyncScopeElement<W, T>, T> {
  final Object? scopeKey;

  const AsyncScopeBase({
    super.key,
    super.tag,
    this.scopeKey,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  Future<T> asyncInit(BuildContext context);

  Future<void> asyncDispose(T data);

  Widget Function(BuildContext context)? get buildOnWaitingForPrevious => null;

  Widget buildOnInitializing(BuildContext context);

  Widget buildOnReady(BuildContext context, T data);

  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  );

  @override
  AsyncScopeElement<W, T> createScopeElement() =>
      AsyncScopeElement<W, T>(this as W);

  static AsyncScopeContext<W, T>?
      maybeOf<W extends AsyncScopeBase<W, T>, T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.maybeOf<W, AsyncScopeContext<W, T>>(
            context,
            listen: listen,
          );

  static AsyncScopeContext<W, T>
      of<W extends AsyncScopeBase<W, T>, T extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.of<W, AsyncScopeContext<W, T>>(
            context,
            listen: listen,
          );

  static V select<W extends AsyncScopeBase<W, T>, T extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(AsyncScopeContext<W, T> context) selector,
  ) =>
      ScopeContext.select<W, AsyncScopeContext<W, T>, V>(
        context,
        selector,
      );
}

final class AsyncScopeElement<W extends AsyncScopeBase<W, T>, T extends Object?>
    extends AsyncScopeElementBase<W, AsyncScopeElement<W, T>, T> {
  // Создаём копию, чтобы позже использовать в dispose.
  @override
  final Object? scopeKey;

  AsyncScopeElement(super.widget) : scopeKey = widget.scopeKey;

  @override
  Future<T> asyncInit() => widget.asyncInit(this);

  @override
  Future<void> asyncDispose(W widget, T data) => widget.asyncDispose(data);

  @override
  Widget buildOnState(AsyncScopeState<T> state) => switch (state) {
        AsyncScopeWaiting() => widget.buildOnWaitingForPrevious?.call(this) ??
            widget.buildOnInitializing(this),
        AsyncScopeProgress() => widget.buildOnInitializing(this),
        AsyncScopeReady(:final data) => widget.buildOnReady(this, data),
        AsyncScopeError(:final error, :final stackTrace) =>
          widget.buildOnError(this, error, stackTrace),
      };
}
