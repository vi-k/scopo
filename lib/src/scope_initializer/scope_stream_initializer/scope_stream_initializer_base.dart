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

  Stream<ScopeProcessState<Object, T>> init();

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
          ScopeModelBottom.maybeOf<W, ScopeInitializerContext<W, T>,
              ScopeStateModel<ScopeInitializerState<T>>>(
            context,
            listen: listen,
          );

  static ScopeInitializerContext<W, T>
      of<W extends ScopeStreamInitializerBase<W, T>, T extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeModelBottom.of<W, ScopeInitializerContext<W, T>,
              ScopeStateModel<ScopeInitializerState<T>>>(
            context,
            listen: listen,
          );

  static V select<W extends ScopeStreamInitializerBase<W, T>, T extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(ScopeInitializerContext<W, T> context) selector,
  ) =>
      ScopeModelBottom.select<W, ScopeInitializerContext<W, T>,
          ScopeStateModel<ScopeInitializerState<T>>, V>(context, selector);
}

final class ScopeStreamInitializerElement<
        W extends ScopeStreamInitializerBase<W, T>, T extends Object?>
    extends ScopeStreamInitializerElementBase<W,
        ScopeStreamInitializerElement<W, T>, T> {
  ScopeStreamInitializerElement(super.widget);

  @override
  Key? get disposeKey => widget.disposeKey;

  @override
  Duration? get disposeTimeout => widget.disposeTimeout;

  @override
  void Function()? get onDisposeTimeout => widget.onDisposeTimeout;

  @override
  Stream<ScopeProcessState<Object, T>> initAsync() => widget.init();

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
