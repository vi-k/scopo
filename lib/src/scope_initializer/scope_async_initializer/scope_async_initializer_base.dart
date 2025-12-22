part of '../scope_initializer.dart';

abstract base class ScopeAsyncInitializerBase<
        W extends ScopeAsyncInitializerBase<W, T>, T extends Object?>
    extends ScopeAsyncInitializerBottom<W, ScopeAsyncInitializerElement<W, T>,
        T> {
  final bool selfDependence;
  final Key? disposeKey;
  final Duration? disposeTimeout;
  final void Function()? onDisposeTimeout;

  const ScopeAsyncInitializerBase({
    super.key,
    this.selfDependence = true,
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

  static ScopeInitializerContext<W, T>?
      maybeOf<W extends ScopeAsyncInitializerBase<W, T>, T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeModelBottom.maybeOf<W, ScopeInitializerContext<W, T>,
              ScopeStateModel<ScopeInitializerState<T>>>(
            context,
            listen: listen,
          );

  static ScopeInitializerContext<W, T>
      of<W extends ScopeAsyncInitializerBase<W, T>, T extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeModelBottom.of<W, ScopeInitializerContext<W, T>,
              ScopeStateModel<ScopeInitializerState<T>>>(
            context,
            listen: listen,
          );

  static V select<W extends ScopeAsyncInitializerBase<W, T>, T extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(ScopeInitializerContext<W, T> context) selector,
  ) =>
      ScopeModelBottom.select<W, ScopeInitializerContext<W, T>,
          ScopeStateModel<ScopeInitializerState<T>>, V>(context, selector);
}

final class ScopeAsyncInitializerElement<
        W extends ScopeAsyncInitializerBase<W, T>, T extends Object?>
    extends ScopeAsyncInitializerElementBase<W,
        ScopeAsyncInitializerElement<W, T>, T> {
  ScopeAsyncInitializerElement(super.widget);

  @override
  bool get selfDependence => widget.selfDependence;

  @override
  Key? get disposeKey => widget.disposeKey;

  @override
  Duration? get disposeTimeout => widget.disposeTimeout;

  @override
  void Function()? get onDisposeTimeout => widget.onDisposeTimeout;

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
