part of '../scope_initializer.dart';

abstract base class ScopeStreamInitializerBase<
        W extends ScopeStreamInitializerBase<W, T>, T extends Object?>
    extends ScopeStreamInitializerBottom<W, ScopeStreamInitializerElement<W, T>,
        T> {
  final Key? disposeKey;
  final Duration? disposeTimeout;
  final void Function()? onDisposeTimeout;

  const ScopeStreamInitializerBase({
    super.key,
    this.disposeKey,
    this.disposeTimeout,
    this.onDisposeTimeout,
  });

  @override
  ScopeStreamInitializerElement<W, T> createScopeElement() =>
      ScopeStreamInitializerElement<W, T>(this as W);

  Stream<ScopeProcessState<T>> init();

  FutureOr<void> dispose(T value);

  Widget Function(BuildContext context)? get buildOnWaitingForPrevious => null;

  Widget buildOnInitializing(BuildContext context, Object? progress);

  Widget buildOnReady(BuildContext context, T value);

  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  );
}

final class ScopeStreamInitializerElement<
        W extends ScopeStreamInitializerBase<W, T>, T extends Object?>
    extends ScopeStreamInitializerElementBase<W,
        ScopeStreamInitializerElement<W, T>, T> {
  ScopeStreamInitializerElement(super.widget);

  @override
  Key? get _disposeKey => widget.disposeKey;

  @override
  Duration? get _disposeTimeout => widget.disposeTimeout;

  @override
  void Function()? get _onDisposeTimeout => widget.onDisposeTimeout;

  @override
  Stream<ScopeProcessState<T>> initAsync() => widget.init();

  @override
  FutureOr<void> disposeAsync(W widget, T value) => widget.dispose(value);

  @override
  Widget buildState(ScopeInitializerState<T> state) => switch (state) {
        ScopeInitializerWaitingForPrevious() =>
          widget.buildOnWaitingForPrevious?.call(this) ??
              widget.buildOnInitializing(this, null),
        ScopeProgressV2(:final progress) =>
          widget.buildOnInitializing(this, progress),
        ScopeReadyV2(:final value) => widget.buildOnReady(this, value),
        ScopeInitializerError(:final error, :final stackTrace) =>
          widget.buildOnError(this, error, stackTrace),
      };
}
