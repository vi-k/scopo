part of '../scope.dart';

final class ScopeAsyncInitializer<T extends Object?>
    extends ScopeAsyncInitializerBase<ScopeAsyncInitializer<T>, T> {
  final Future<T> Function() _init;
  final FutureOr<void> Function(T value) _dispose;
  final Widget Function(BuildContext context)? _buildOnWaitingForPrevious;
  final Widget Function(BuildContext context) _buildOnInitializing;
  final Widget Function(BuildContext context, T value) _buildOnReady;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) _buildOnError;

  const ScopeAsyncInitializer({
    super.key,
    super.tag,
    super.onlyOneInstance,
    required Future<T> Function() init,
    required FutureOr<void> Function(T value) dispose,
    super.disposeTimeout,
    super.onDisposeTimeout,
    Widget Function(BuildContext context)? buildOnWaitingForPrevious,
    required Widget Function(BuildContext context) buildOnInitializing,
    required Widget Function(BuildContext context, T value) buildOnReady,
    required Widget Function(
      BuildContext context,
      Object error,
      StackTrace stackTrace,
    ) buildOnError,
  })  : _init = init,
        _dispose = dispose,
        _buildOnWaitingForPrevious = buildOnWaitingForPrevious,
        _buildOnInitializing = buildOnInitializing,
        _buildOnReady = buildOnReady,
        _buildOnError = buildOnError;

  @override
  Future<T> init() => _init();

  @override
  FutureOr<void> dispose(T value) => _dispose(value);

  @override
  Widget Function(BuildContext context)? get buildOnWaitingForPrevious =>
      _buildOnWaitingForPrevious;

  @override
  Widget buildOnInitializing(BuildContext context) =>
      _buildOnInitializing(context);

  @override
  Widget buildOnReady(BuildContext context, T value) =>
      _buildOnReady(context, value);

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) =>
      _buildOnError(context, error, stackTrace);

  static ScopeInitializerContext<ScopeAsyncInitializer<T>, T>?
      maybeOf<T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeWidgetContext.maybeOf<ScopeAsyncInitializer<T>,
              ScopeInitializerContext<ScopeAsyncInitializer<T>, T>>(
            context,
            listen: listen,
          );

  static ScopeInitializerContext<ScopeAsyncInitializer<T>, T>
      of<T extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeWidgetContext.of<ScopeAsyncInitializer<T>,
              ScopeInitializerContext<ScopeAsyncInitializer<T>, T>>(
            context,
            listen: listen,
          );

  static V select<T extends Object, V extends Object?>(
    BuildContext context,
    V Function(ScopeInitializerContext<ScopeAsyncInitializer<T>, T> context)
        selector,
  ) =>
      ScopeWidgetContext.select<
          ScopeAsyncInitializer<T>,
          ScopeInitializerContext<ScopeAsyncInitializer<T>, T>,
          V>(context, selector);
}
