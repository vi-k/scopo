part of '../scope.dart';

final class ScopeStreamInitializer<T extends Object?>
    extends ScopeStreamInitializerBase<ScopeStreamInitializer<T>, T> {
  final Stream<ScopeInitState<Object, T>> Function() _init;
  final FutureOr<void> Function(T value) _dispose;
  final Widget Function(BuildContext context)? _buildOnWaitingForPrevious;
  final Widget Function(BuildContext context, Object? progress)
      _buildOnInitializing;
  final Widget Function(BuildContext context, T value) _buildOnReady;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) _buildOnError;

  const ScopeStreamInitializer({
    super.key,
    required Stream<ScopeInitState<Object, T>> Function() init,
    required FutureOr<void> Function(T value) dispose,
    super.disposeKey,
    super.disposeTimeout,
    super.onDisposeTimeout,
    Widget Function(BuildContext context)? buildOnWaitingForPrevious,
    required Widget Function(BuildContext context, Object? progress)
        buildOnInitializing,
    required Widget Function(BuildContext context, T value) buildOnReady,
    required Widget Function(
      BuildContext context,
      Object error,
      StackTrace stackTrace,
      Object? progress,
    ) buildOnError,
  })  : _init = init,
        _dispose = dispose,
        _buildOnWaitingForPrevious = buildOnWaitingForPrevious,
        _buildOnInitializing = buildOnInitializing,
        _buildOnReady = buildOnReady,
        _buildOnError = buildOnError;

  @override
  Stream<ScopeInitState<Object, T>> init() => _init();

  @override
  FutureOr<void> dispose(T value) => _dispose(value);

  @override
  Widget Function(BuildContext context)? get buildOnWaitingForPrevious =>
      _buildOnWaitingForPrevious;

  @override
  Widget buildOnInitializing(BuildContext context, Object? progress) =>
      _buildOnInitializing(context, progress);

  @override
  Widget buildOnReady(BuildContext context, T value) =>
      _buildOnReady(context, value);

  @override
  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) =>
      _buildOnError(context, error, stackTrace, progress);

  static ScopeInitializerContext<ScopeStreamInitializer<T>, T>?
      maybeOf<T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeModelBottom.maybeOf<
              ScopeStreamInitializer<T>,
              ScopeInitializerContext<ScopeStreamInitializer<T>, T>,
              ScopeStateModel<ScopeInitializerState<T>>>(
            context,
            listen: listen,
          );

  static ScopeInitializerContext<ScopeStreamInitializer<T>, T>
      of<T extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeModelBottom.of<
              ScopeStreamInitializer<T>,
              ScopeInitializerContext<ScopeStreamInitializer<T>, T>,
              ScopeStateModel<ScopeInitializerState<T>>>(
            context,
            listen: listen,
          );

  static V select<T extends Object, V extends Object?>(
    BuildContext context,
    V Function(ScopeInitializerContext<ScopeStreamInitializer<T>, T> context)
        selector,
  ) =>
      ScopeModelBottom.select<
          ScopeStreamInitializer<T>,
          ScopeInitializerContext<ScopeStreamInitializer<T>, T>,
          ScopeStateModel<ScopeInitializerState<T>>,
          V>(context, selector);
}
