part of '../../scope.dart';

typedef StreamScopeInitFunction<P extends Object, T extends Object?>
    = Stream<ScopeInitState<P, T>> Function(BuildContext context);

final class StreamScope<T extends Object?>
    extends StreamScopeBase<StreamScope<T>, T> {
  final StreamScopeInitFunction<Object, T> init;
  final FutureOr<void> Function(T data) dispose;
  final Widget Function(BuildContext context)? waitBuilder;
  final Widget Function(BuildContext context, Object? progress) initBuilder;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) errorBuilder;
  final Widget Function(BuildContext context, T data) builder;

  const StreamScope({
    super.key,
    super.tag,
    super.scopeKey,
    required this.init,
    required this.dispose,
    this.waitBuilder,
    required this.initBuilder,
    required this.builder,
    required this.errorBuilder,
  });

  @override
  Stream<ScopeInitState<Object, T>> asyncInit(BuildContext context) =>
      init(context);

  @override
  Future<void> asyncDispose(T data) async => dispose(data);

  @override
  Widget Function(BuildContext context)? get buildOnWaitingForPrevious =>
      waitBuilder;

  @override
  Widget buildOnInitializing(BuildContext context, Object? progress) =>
      initBuilder(context, progress);

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) =>
      errorBuilder(context, error, stackTrace, progress);

  @override
  Widget buildOnReady(BuildContext context, T data) => builder(context, data);

  static AsyncScopeContext<StreamScope<T>, T>? maybeOf<T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<StreamScope<T>,
          AsyncScopeContext<StreamScope<T>, T>>(
        context,
        listen: listen,
      );

  static AsyncScopeContext<StreamScope<T>, T> of<T extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<StreamScope<T>, AsyncScopeContext<StreamScope<T>, T>>(
        context,
        listen: listen,
      );

  static V select<T extends Object, V extends Object?>(
    BuildContext context,
    V Function(AsyncScopeContext<StreamScope<T>, T> context) selector,
  ) =>
      ScopeContext.select<StreamScope<T>, AsyncScopeContext<StreamScope<T>, T>,
          V>(context, selector);
}
