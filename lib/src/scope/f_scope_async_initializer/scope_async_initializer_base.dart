part of '../scope.dart';

abstract base class ScopeAsyncInitializerBase<
        W extends ScopeAsyncInitializerBase<W, T>, T extends Object?>
    extends ScopeAsyncInitializerCore<W, ScopeAsyncInitializerElement<W, T>,
        T> {
  final LifecycleCoordinator<Object>? exclusiveCoordinator;
  final Key? exclusiveCoordinatorKey;
  final LifecycleCoordinator<Object>? disposeCoordinator;
  final Key? disposeCoordinatorKey;

  const ScopeAsyncInitializerBase({
    super.key,
    super.tag,
    this.exclusiveCoordinator,
    this.exclusiveCoordinatorKey,
    this.disposeCoordinator,
    this.disposeCoordinatorKey,
  })  : assert(
          exclusiveCoordinatorKey == null || exclusiveCoordinator == null,
          '`exclusiveCoordinator` and `exclusiveCoordinatorKey` cannot be both set',
        ),
        assert(
          disposeCoordinatorKey == null || disposeCoordinator == null,
          '`disposeCoordinator` and `disposeCoordinatorKey` cannot be both set',
        );

  Future<T> init();

  FutureOr<void> dispose(T value);

  Widget Function(BuildContext context)? get buildOnWaitingForPrevious => null;

  Widget buildOnInitializing(BuildContext context);

  Widget buildOnReady(BuildContext context, T value);

  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  );

  @override
  ScopeAsyncInitializerElement<W, T> createScopeElement() =>
      ScopeAsyncInitializerElement<W, T>(this as W);

  static ScopeInitializerContext<W, T>?
      maybeOf<W extends ScopeAsyncInitializerBase<W, T>, T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.maybeOf<W, ScopeInitializerContext<W, T>>(
            context,
            listen: listen,
          );

  static ScopeInitializerContext<W, T>
      of<W extends ScopeAsyncInitializerBase<W, T>, T extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.of<W, ScopeInitializerContext<W, T>>(
            context,
            listen: listen,
          );

  static V select<W extends ScopeAsyncInitializerBase<W, T>, T extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(ScopeInitializerContext<W, T> context) selector,
  ) =>
      ScopeContext.select<W, ScopeInitializerContext<W, T>, V>(
        context,
        selector,
      );
}

final class ScopeAsyncInitializerElement<
        W extends ScopeAsyncInitializerBase<W, T>, T extends Object?>
    extends ScopeAsyncInitializerElementBase<W,
        ScopeAsyncInitializerElement<W, T>, T> {
  ScopeAsyncInitializerElement(super.widget);

  @override
  LifecycleCoordinator<Object>? get exclusiveCoordinator =>
      widget.exclusiveCoordinator;

  @override
  Key? get exclusiveCoordinatorKey => widget.exclusiveCoordinatorKey;

  @override
  LifecycleCoordinator<Object>? get disposeCoordinator =>
      widget.disposeCoordinator;

  @override
  Key? get disposeCoordinatorKey => widget.disposeCoordinatorKey;

  @override
  Future<T> initAsync() => widget.init();

  @override
  FutureOr<void> disposeAsync(W widget, T value) => widget.dispose(value);

  @override
  Widget buildOnState(ScopeInitializerState<T> state) => switch (state) {
        ScopeInitializerWaitingForPrevious() =>
          widget.buildOnWaitingForPrevious?.call(this) ??
              widget.buildOnInitializing(this),
        ScopeInitializerProgress() => widget.buildOnInitializing(this),
        ScopeInitializerReady(:final value) => widget.buildOnReady(this, value),
        ScopeInitializerError(:final error, :final stackTrace) =>
          widget.buildOnError(this, error, stackTrace),
      };
}
