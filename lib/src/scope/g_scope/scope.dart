part of '../scope.dart';

typedef ScopeInitFunction<P extends Object, D extends ScopeDependencies>
    = Stream<ScopeInitState<P, D>> Function();

typedef ScopeOnInitCallback<P extends Object> = Widget Function(
  BuildContext context,
  P? progress,
);

typedef ScopeOnErrorCallback = Widget Function(
  BuildContext context,
  Object error,
  StackTrace stackTrace,
  Object? progress,
);

abstract base class Scope<W extends Scope<W, D, S>, D extends ScopeDependencies,
        S extends ScopeState<W, D, S>>
    extends ScopeStreamInitializerBottom<W, ScopeElement<W, D, S>, D> {
  @override
  final String? tag;

  final bool onlyOneInstance;

  final Duration? pauseAfterInitialization;

  const Scope({
    super.key,
    this.tag,
    this.onlyOneInstance = false,
    this.pauseAfterInitialization,
  });

  Stream<ScopeInitState<Object, D>> init();

  Widget Function(BuildContext context)? get buildOnWaitingForPrevious => null;

  Widget buildOnInitializing(BuildContext context, Object? progress);

  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  );

  /// Wraps all states.
  Widget wrap(BuildContext context, Widget child) => child;

  S createState();

  /// Wraps [ScopeState].
  Widget wrapState(BuildContext context, D dependencies, Widget child) => child;

  Duration? get disposeTimeout => null;

  void Function()? get onDisposeTimeout => null;

  @override
  ScopeElement<W, D, S> createScopeElement() => ScopeElement(this as W);

  static W paramsOf<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeModelBottom.of<W, ScopeElement<W, D, S>,
          ScopeStateModel<ScopeInitializerState<D>>>(
        context,
        listen: listen,
      ).widget;

  static V selectParam<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>, V extends Object?>(
    BuildContext context,
    V Function(W widget) selector,
  ) =>
      ScopeModelBottom.select<
          W,
          ScopeElement<W, D, S>,
          ScopeStateModel<ScopeInitializerState<D>>,
          V>(context, (element) => selector(element.widget));

  static S? maybeOf<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>>(BuildContext context) =>
      ScopeModelBottom.maybeOf<W, ScopeElement<W, D, S>,
          ScopeStateModel<ScopeInitializerState<D>>>(
        context,
        listen: false,
      )?._globalStateKey.currentState;

  static S of<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>>(BuildContext context) =>
      ScopeModelBottom.of<W, ScopeElement<W, D, S>,
          ScopeStateModel<ScopeInitializerState<D>>>(
        context,
        listen: false,
      )._globalStateKey.currentState!;

  static V select<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>, V extends Object?>(
    BuildContext context,
    V Function(S scope) selector,
  ) =>
      ScopeModelBottom.select<W, ScopeElement<W, D, S>,
          ScopeStateModel<ScopeInitializerState<D>>, V>(
        context,
        (element) => selector(element._globalStateKey.currentState!),
      );
}

final class ScopeElement<W extends Scope<W, D, S>, D extends ScopeDependencies,
        S extends ScopeState<W, D, S>>
    extends ScopeStreamInitializerElementBase<W, ScopeElement<W, D, S>, D> {
  var _autoSelfDependence = true;
  final _globalStateKey = GlobalKey<S>();

  ScopeElement(super.widget);

  @override
  bool get autoSelfDependence => _autoSelfDependence;

  @override
  Duration? get pauseAfterInitialization => widget.pauseAfterInitialization;

  @override
  Key? get instanceKey => widget.onlyOneInstance
      ? ValueKey(widget.tag)
      : switch (widget.tag) {
          null => null,
          final tag => Key(tag),
        };

  @override
  Duration? get disposeTimeout => widget.disposeTimeout;

  @override
  void Function()? get onDisposeTimeout => widget.onDisposeTimeout;

  @override
  Stream<ScopeInitState<Object, D>> initAsync() => widget.init();

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

  Widget buildOnReady(BuildContext context, D dependencies) {
    _autoSelfDependence = false;

    return widget.wrapState(
      this,
      dependencies,
      _ScopeStateWidget<W, D, S>(
        key: _globalStateKey,
        createState: _createState,
      ),
    );
  }

  S _createState() => widget.createState().._scopeElement = this;
}
