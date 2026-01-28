part of '../scope.dart';

final class AsyncScope extends AsyncScopeBase<AsyncScope> {
  final Stream<AsyncScopeInitState> Function(BuildContext context) init;
  final FutureOr<void> Function() dispose;
  final Widget Function(BuildContext context)? waitBuilder;
  final Widget Function(BuildContext context) initBuilder;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) errorBuilder;
  final Widget Function(BuildContext context) builder;

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
  Stream<AsyncScopeInitState> initAsync(BuildContext context) => init(context);

  @override
  FutureOr<void> disposeAsync() => dispose();

  @override
  Widget? buildOnWaiting(BuildContext context) => waitBuilder?.call(context);

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
  Widget buildOnReady(BuildContext context) => builder(context);

  static AsyncScopeContext<AsyncScope>? maybeOf(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<AsyncScope, AsyncScopeContext<AsyncScope>>(
        context,
        listen: listen,
      );

  static AsyncScopeContext<AsyncScope> of(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<AsyncScope, AsyncScopeContext<AsyncScope>>(
        context,
        listen: listen,
      );

  static V select<V extends Object?>(
    BuildContext context,
    V Function(AsyncScopeContext<AsyncScope> context) selector,
  ) =>
      ScopeContext.select<AsyncScope, AsyncScopeContext<AsyncScope>, V>(
        context,
        selector,
      );
}
