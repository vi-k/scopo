part of '../scope.dart';

/// {@category AsyncDataScope}
final class AsyncDataScope<T extends Object?>
    extends AsyncDataScopeBase<AsyncDataScope<T>, T> {
  final Stream<AsyncDataScopeInitState<Object, T>> Function(
    BuildContext context,
  ) init;
  final FutureOr<void> Function(T data) dispose;
  final Widget Function(BuildContext context)? waitingBuilder;
  final Widget Function(BuildContext context, Object? progress) initBuilder;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) errorBuilder;
  final Widget Function(BuildContext context, T data) builder;

  const AsyncDataScope({
    super.key,
    super.tag,
    super.scopeKey,
    required this.init,
    required this.dispose,
    this.waitingBuilder,
    required this.initBuilder,
    required this.builder,
    required this.errorBuilder,
  });

  @override
  Stream<AsyncDataScopeInitState<Object, T>> initData(BuildContext context) =>
      init(context);

  @override
  FutureOr<void> disposeData(T data) => dispose(data);

  @override
  Widget? buildOnWaiting(BuildContext context) => waitingBuilder?.call(context);

  @override
  Widget buildOnInitializing(BuildContext context, Object? progress) =>
      initBuilder(context, progress);

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) =>
      errorBuilder(context, error, stackTrace);

  @override
  Widget buildOnReady(BuildContext context, T data) => builder(context, data);

  static AsyncDataScopeContext<AsyncDataScope<T>, T>?
      maybeOf<T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.maybeOf<AsyncDataScope<T>,
              AsyncDataScopeContext<AsyncDataScope<T>, T>>(
            context,
            listen: listen,
          );

  static AsyncDataScopeContext<AsyncDataScope<T>, T> of<T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<AsyncDataScope<T>,
          AsyncDataScopeContext<AsyncDataScope<T>, T>>(
        context,
        listen: listen,
      );

  static V select<V extends Object?, T extends Object?>(
    BuildContext context,
    V Function(AsyncDataScopeContext<AsyncDataScope<T>, T> context) selector,
  ) =>
      ScopeContext.select<AsyncDataScope<T>,
          AsyncDataScopeContext<AsyncDataScope<T>, T>, V>(
        context,
        selector,
      );
}
