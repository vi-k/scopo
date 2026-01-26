part of '../../scope.dart';

final class AsyncScope<T extends Object?>
    extends AsyncScopeBase<AsyncScope<T>, T> {
  final Future<T> Function(BuildContext context) init;
  final FutureOr<void> Function(T data) dispose;
  final Widget Function(BuildContext context)? waitBuilder;
  final Widget Function(BuildContext context) initBuilder;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) errorBuilder;
  final Widget Function(BuildContext context, T data) builder;

  const AsyncScope({
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
  Future<T> asyncInit(BuildContext context) => init(context);

  @override
  Future<void> asyncDispose(T data) async => dispose(data);

  @override
  Widget Function(BuildContext context)? get buildOnWaitingForPrevious =>
      waitBuilder;

  @override
  Widget buildOnInitializing(BuildContext context) => initBuilder(context);

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) =>
      errorBuilder(context, error, stackTrace);

  @override
  Widget buildOnReady(BuildContext context, T data) => builder(context, data);

  static AsyncScopeContext<AsyncScope<T>, T>? maybeOf<T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<AsyncScope<T>, AsyncScopeContext<AsyncScope<T>, T>>(
        context,
        listen: listen,
      );

  static AsyncScopeContext<AsyncScope<T>, T> of<T extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<AsyncScope<T>, AsyncScopeContext<AsyncScope<T>, T>>(
        context,
        listen: listen,
      );

  static V select<T extends Object, V extends Object?>(
    BuildContext context,
    V Function(AsyncScopeContext<AsyncScope<T>, T> context) selector,
  ) =>
      ScopeContext.select<AsyncScope<T>, AsyncScopeContext<AsyncScope<T>, T>,
          V>(context, selector);
}
