part of '../scope.dart';

/// {@category AsyncScope}
final class AsyncScope extends AsyncScopeBase<AsyncScope> {
  final void Function(BuildContext context)? mount;
  final Stream<AsyncScopeInitState> Function(BuildContext context) init;
  final void Function()? unmount;
  final FutureOr<void> Function() dispose;
  final Widget Function(BuildContext context)? waitingBuilder;
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
    this.mount,
    required this.init,
    this.unmount,
    required this.dispose,
    this.waitingBuilder,
    required this.initBuilder,
    required this.builder,
    required this.errorBuilder,
  });

  @override
  void onMount(BuildContext context) => mount?.call(context);

  @override
  Stream<AsyncScopeInitState> initAsync(BuildContext context) => init(context);

  @override
  void onUnmount() => unmount?.call();

  @override
  FutureOr<void> disposeAsync() => dispose();

  @override
  Widget? buildOnWaiting(BuildContext context) => waitingBuilder?.call(context);

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
