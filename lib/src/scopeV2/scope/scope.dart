part of '../scope.dart';

abstract base class ScopeV2<W extends ScopeV2<W, D, S>,
        D extends ScopeDependencies, S extends ScopeState<W, D, S>>
    extends ScopeStreamInitializerBottom<W, ScopeElement<W, D, S>, D> {
  const ScopeV2({super.key});

  Key? get disposeKey => null;

  Duration? get disposeTimeout => null;

  void Function()? get onDisposeTimeout => null;

  Stream<ScopeProcessState<Object, D>> init();

  Widget Function(BuildContext context)? get buildOnWaitingForPrevious => null;

  Widget buildOnInitializing(BuildContext context, Object? progress);

  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  );

  S createState();

  @override
  ScopeElement<W, D, S> createScopeElement() => ScopeElement(this as W);

  /// Wraps all states.
  Widget wrap(BuildContext context, Widget child) => child;

  /// Wraps [ScopeState].
  Widget wrapState(BuildContext context, D dependencies, Widget child) => child;

  static W paramsOf<W extends ScopeV2<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeModelBottom.of<W, ScopeElement<W, D, S>,
          ScopeStateModel<ScopeInitializerState<D>>>(
        context,
        listen: listen,
      ).widget;

  static V selectParam<W extends ScopeV2<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>, V extends Object?>(
    BuildContext context,
    V Function(W widget) selector,
  ) =>
      ScopeModelBottom.select<
          W,
          ScopeElement<W, D, S>,
          ScopeStateModel<ScopeInitializerState<D>>,
          V>(context, (element) => selector(element.widget));

  static S of<W extends ScopeV2<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>>(BuildContext context) =>
      ScopeModelBottom.of<W, ScopeElement<W, D, S>,
          ScopeStateModel<ScopeInitializerState<D>>>(
        context,
        listen: false,
      )._globalStateKey.currentState!;

  static V select<W extends ScopeV2<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>, V extends Object?>(
    BuildContext context,
    V Function(S state) selector,
  ) =>
      ScopeModelBottom.select<W, ScopeElement<W, D, S>,
          ScopeStateModel<ScopeInitializerState<D>>, V>(
        context,
        (element) => selector(element._globalStateKey.currentState!),
      );
}

final class ScopeElement<W extends ScopeV2<W, D, S>,
        D extends ScopeDependencies, S extends ScopeState<W, D, S>>
    extends ScopeStreamInitializerElementBase<W, ScopeElement<W, D, S>, D> {
  final _globalStateKey = GlobalKey<S>();

  ScopeElement(super.widget);

  @override
  Key? get disposeKey => widget.disposeKey;

  @override
  Duration? get disposeTimeout => widget.disposeTimeout;

  @override
  void Function()? get onDisposeTimeout => widget.onDisposeTimeout;

  @override
  Stream<ScopeProcessState<Object, D>> initAsync() => widget.init();

  @override
  FutureOr<void> disposeAsync(W widget, D value) => value.dispose();

  @override
  Widget buildOnState(ScopeInitializerState<D> state) => widget.wrap(
        this,
        switch (state) {
          ScopeInitializerWaitingForPrevious() =>
            widget.buildOnWaitingForPrevious?.call(this) ??
                widget.buildOnInitializing(this, null),
          ScopeInitializerProgress(:final progress) =>
            widget.buildOnInitializing(this, progress),
          ScopeInitializerReady(:final value) => buildOnReady(this, value),
          ScopeInitializerError(
            :final error,
            :final stackTrace,
            :final progress
          ) =>
            widget.buildOnError(this, error, stackTrace, progress),
        },
      );

  Widget buildOnReady(BuildContext context, D dependencies) => widget.wrapState(
        this,
        dependencies,
        _ScopeStateWidget<W, D, S>(
          key: _globalStateKey,
          createState: _createState,
        ),
      );

  S _createState() => widget.createState().._scopeElement = this;
}
