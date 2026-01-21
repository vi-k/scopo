part of '../scope.dart';

final class ScopeStreamInitializer<T extends Object?>
    extends ScopeStreamInitializerBase<ScopeStreamInitializer<T>, T> {
  final Stream<ScopeInitState<Object, T>> Function(BuildContext context) _init;
  final FutureOr<void> Function(T value) _dispose;
  final Widget Function(BuildContext context)? waitingForPreviousBuilder;
  final Widget Function(BuildContext context, Object? progress)
      initializingBuilder;
  final Widget Function(BuildContext context, T value) readyBuilder;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) errorBuilder;

  const ScopeStreamInitializer({
    super.key,
    super.tag,
    super.exclusiveCoordinator,
    super.exclusiveCoordinatorKey,
    super.disposeCoordinator,
    super.disposeCoordinatorKey,
    required Stream<ScopeInitState<Object, T>> Function(BuildContext context)
        init,
    required FutureOr<void> Function(T value) dispose,
    this.waitingForPreviousBuilder,
    required this.initializingBuilder,
    required this.readyBuilder,
    required this.errorBuilder,
  })  : _init = init,
        _dispose = dispose;

  @override
  Stream<ScopeInitState<Object, T>> init(BuildContext context) =>
      _init(context);

  @override
  FutureOr<void> dispose(T value) => _dispose(value);

  @override
  Widget Function(BuildContext context)? get buildOnWaitingForPrevious =>
      waitingForPreviousBuilder;

  @override
  Widget buildOnInitializing(BuildContext context, Object? progress) =>
      initializingBuilder(context, progress);

  @override
  Widget buildOnReady(BuildContext context, T value) =>
      readyBuilder(context, value);

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) =>
      errorBuilder(context, error, stackTrace, progress);

  static ScopeInitializerContext<ScopeStreamInitializer<T>, T>?
      maybeOf<T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.maybeOf<ScopeStreamInitializer<T>,
              ScopeInitializerContext<ScopeStreamInitializer<T>, T>>(
            context,
            listen: listen,
          );

  static ScopeInitializerContext<ScopeStreamInitializer<T>, T>
      of<T extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.of<ScopeStreamInitializer<T>,
              ScopeInitializerContext<ScopeStreamInitializer<T>, T>>(
            context,
            listen: listen,
          );

  static V select<T extends Object, V extends Object?>(
    BuildContext context,
    V Function(ScopeInitializerContext<ScopeStreamInitializer<T>, T> context)
        selector,
  ) =>
      ScopeContext.select<
          ScopeStreamInitializer<T>,
          ScopeInitializerContext<ScopeStreamInitializer<T>, T>,
          V>(context, selector);
}
