part of '../scope_initializer.dart';

abstract base class ScopeAsyncInitializerBase<
        W extends ScopeAsyncInitializerBase<W, T>, T extends Object?>
    extends ScopeAsyncInitializerBottom<W, ScopeAsyncInitializerElement<W, T>,
        T> {
  final Key? disposeKey;
  final Duration? disposeTimeout;
  final void Function()? onDisposeTimeout;

  const ScopeAsyncInitializerBase({
    super.key,
    this.disposeKey,
    this.disposeTimeout,
    this.onDisposeTimeout,
  });

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
}

final class ScopeAsyncInitializerElement<
        W extends ScopeAsyncInitializerBase<W, T>, T extends Object?>
    extends ScopeAsyncInitializerElementBase<W,
        ScopeAsyncInitializerElement<W, T>, T> {
  ScopeAsyncInitializerElement(super.widget);

  @override
  Key? get _disposeKey => widget.disposeKey;

  @override
  Duration? get _disposeTimeout => widget.disposeTimeout;

  @override
  void Function()? get _onDisposeTimeout => widget.onDisposeTimeout;

  @override
  Future<T> initAsync() => widget.init();

  @override
  FutureOr<void> disposeAsync(W widget, T value) => widget.dispose(value);

  @override
  Widget buildState(ScopeInitializerState<T> state) => switch (state) {
        ScopeInitializerWaitingForPrevious() =>
          widget.buildOnWaitingForPrevious?.call(this) ??
              widget.buildOnInitializing(this),
        ScopeProgressV2() => widget.buildOnInitializing(this),
        ScopeReadyV2(:final value) => widget.buildOnReady(this, value),
        ScopeInitializerError(:final error, :final stackTrace) =>
          widget.buildOnError(this, error, stackTrace),
      };
}
