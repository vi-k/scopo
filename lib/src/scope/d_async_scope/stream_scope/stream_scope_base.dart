part of '../../scope.dart';

abstract base class StreamScopeBase<W extends StreamScopeBase<W, T>,
    T extends Object?> extends StreamScopeCore<W, StreamScopeElement<W, T>, T> {
  final Object? scopeKey;
  final Duration? pauseAfterInitialization;

  const StreamScopeBase({
    super.key,
    super.tag,
    this.scopeKey,
    this.pauseAfterInitialization,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  Stream<ScopeInitState<Object, T>> asyncInit(BuildContext context);

  Future<void> asyncDispose(T data);

  Widget Function(BuildContext context)? get buildOnWaitingForPrevious => null;

  Widget buildOnInitializing(BuildContext context, Object? progress);

  Widget buildOnReady(BuildContext context, T data);

  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  );

  @override
  StreamScopeElement<W, T> createScopeElement() =>
      StreamScopeElement<W, T>(this as W);

  static AsyncScopeContext<W, T>?
      maybeOf<W extends StreamScopeBase<W, T>, T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.maybeOf<W, AsyncScopeContext<W, T>>(
            context,
            listen: listen,
          );

  static AsyncScopeContext<W, T>
      of<W extends StreamScopeBase<W, T>, T extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.of<W, AsyncScopeContext<W, T>>(
            context,
            listen: listen,
          );

  static V select<W extends StreamScopeBase<W, T>, T extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(AsyncScopeContext<W, T> context) selector,
  ) =>
      ScopeContext.select<W, AsyncScopeContext<W, T>, V>(
        context,
        selector,
      );
}

final class StreamScopeElement<W extends StreamScopeBase<W, T>,
        T extends Object?>
    extends StreamScopeElementBase<W, StreamScopeElement<W, T>, T> {
  // Создаём копию, чтобы позже использовать в dispose.
  @override
  final Object? scopeKey;

  StreamScopeElement(super.widget) : scopeKey = widget.scopeKey;

  @override
  Duration? get pauseAfterInitialization => widget.pauseAfterInitialization;

  @override
  Stream<ScopeInitState<Object, T>> asyncInit() => widget.asyncInit(this);

  @override
  Future<void> asyncDispose(W widget, T data) => widget.asyncDispose(data);

  @override
  Widget buildOnState(AsyncScopeState<T> state) => switch (state) {
        AsyncScopeWaiting() => widget.buildOnWaitingForPrevious?.call(this) ??
            widget.buildOnInitializing(this, null),
        AsyncScopeProgress(:final progress) =>
          widget.buildOnInitializing(this, progress),
        AsyncScopeReady(:final data) => widget.buildOnReady(this, data),
        AsyncScopeError(:final error, :final stackTrace, :final progress) =>
          widget.buildOnError(this, error, stackTrace, progress),
      };
}
