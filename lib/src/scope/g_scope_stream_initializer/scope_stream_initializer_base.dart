part of '../scope.dart';

abstract base class ScopeStreamInitializerBase<
        W extends ScopeStreamInitializerBase<W, T>, T extends Object?>
    extends ScopeStreamInitializerCore<W, ScopeStreamInitializerElement<W, T>,
        T> {
  final LifecycleCoordinator<Object>? exclusiveCoordinator;
  final Key? exclusiveCoordinatorKey;
  final LifecycleCoordinator<Object>? disposeCoordinator;
  final Key? disposeCoordinatorKey;
  final Duration? pauseAfterInitialization;

  const ScopeStreamInitializerBase({
    super.key,
    super.tag,
    this.exclusiveCoordinator,
    this.exclusiveCoordinatorKey,
    this.disposeCoordinator,
    this.disposeCoordinatorKey,
    this.pauseAfterInitialization,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  Stream<ScopeInitState<Object, T>> init(BuildContext context);

  FutureOr<void> dispose(T value);

  Widget Function(BuildContext context)? get buildOnWaitingForPrevious => null;

  Widget buildOnInitializing(BuildContext context, Object? progress);

  Widget buildOnReady(BuildContext context, T value);

  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  );

  @override
  ScopeStreamInitializerElement<W, T> createScopeElement() =>
      ScopeStreamInitializerElement<W, T>(this as W);

  static ScopeInitializerContext<W, T>?
      maybeOf<W extends ScopeStreamInitializerBase<W, T>, T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.maybeOf<W, ScopeInitializerContext<W, T>>(
            context,
            listen: listen,
          );

  static ScopeInitializerContext<W, T>
      of<W extends ScopeStreamInitializerBase<W, T>, T extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.of<W, ScopeInitializerContext<W, T>>(
            context,
            listen: listen,
          );

  static V select<W extends ScopeStreamInitializerBase<W, T>, T extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(ScopeInitializerContext<W, T> context) selector,
  ) =>
      ScopeContext.select<W, ScopeInitializerContext<W, T>, V>(
        context,
        selector,
      );
}

final class ScopeStreamInitializerElement<
        W extends ScopeStreamInitializerBase<W, T>, T extends Object?>
    extends ScopeStreamInitializerElementBase<W,
        ScopeStreamInitializerElement<W, T>, T> {
  ScopeStreamInitializerElement(super.widget);

  // Создаём копию!
  @override
  late final LifecycleCoordinator<Object>? exclusiveCoordinator =
      widget.exclusiveCoordinator;

  // Создаём копию!
  @override
  late final Key? exclusiveCoordinatorKey = widget.exclusiveCoordinatorKey;

  // Создаём копию!
  @override
  late final LifecycleCoordinator<Object>? disposeCoordinator =
      widget.disposeCoordinator;

  // Создаём копию!
  @override
  late final Key? disposeCoordinatorKey = widget.disposeCoordinatorKey;

  @override
  Duration? get pauseAfterInitialization => widget.pauseAfterInitialization;

  @override
  Stream<ScopeInitState<Object, T>> initAsync() => widget.init(this);

  @override
  FutureOr<void> disposeAsync(W widget, T value) => widget.dispose(value);

  @override
  Widget buildOnState(ScopeInitializerState<T> state) => switch (state) {
        ScopeInitializerWaitingForPrevious() =>
          widget.buildOnWaitingForPrevious?.call(this) ??
              widget.buildOnInitializing(this, null),
        ScopeInitializerProgress(:final progress) =>
          widget.buildOnInitializing(this, progress),
        ScopeInitializerReady(:final value) => widget.buildOnReady(this, value),
        ScopeInitializerError(
          :final error,
          :final stackTrace,
          :final progress
        ) =>
          widget.buildOnError(this, error, stackTrace, progress),
      };
}
