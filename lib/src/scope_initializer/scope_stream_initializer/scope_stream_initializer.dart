part of '../scope_initializer.dart';

final class ScopeStreamInitializer<T extends Object?>
    extends ScopeStreamInitializerBase<ScopeStreamInitializer<T>, T> {
  final Stream<ScopeProcessState<T>> Function() _init;
  final FutureOr<void> Function(T value) _dispose;
  final Widget Function(BuildContext context)? _buildOnWaitingForPrevious;
  final Widget Function(BuildContext context, Object? progress)
      _buildOnInitializing;
  final Widget Function(BuildContext context, T value) _buildOnReady;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  ) _buildOnError;

  const ScopeStreamInitializer({
    super.key,
    required Stream<ScopeProcessState<T>> Function() init,
    required FutureOr<void> Function(T value) dispose,
    Widget Function(BuildContext context)? buildOnWaitingForPrevious,
    required Widget Function(BuildContext context, Object? progress)
        buildOnInitializing,
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
  Stream<ScopeProcessState<T>> init() => _init();

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
  ) =>
      _buildOnError(context, error, stackTrace);
}
