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
    extends ScopeStreamInitializerCore<W, ScopeElement<W, D, S>, D> {
  final bool onlyOneInstance;

  final Duration? pauseAfterInitialization;

  const Scope({
    super.key,
    super.tag,
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
      ScopeModelCore.of<W, ScopeElement<W, D, S>,
          ScopeStateModel<ScopeInitializerState<D>>>(
        context,
        listen: listen,
      ).widget;

  static V selectParam<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>, V extends Object?>(
    BuildContext context,
    V Function(W widget) selector,
  ) =>
      ScopeModelCore.select<
          W,
          ScopeElement<W, D, S>,
          ScopeStateModel<ScopeInitializerState<D>>,
          V>(context, (element) => selector(element.widget));

  static S? maybeOf<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>>(BuildContext context) =>
      ScopeModelCore.maybeOf<W, ScopeElement<W, D, S>,
          ScopeStateModel<ScopeInitializerState<D>>>(
        context,
        listen: false,
      )?._globalStateKey.currentState;

  static S of<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>>(BuildContext context) =>
      ScopeModelCore.of<W, ScopeElement<W, D, S>,
          ScopeStateModel<ScopeInitializerState<D>>>(
        context,
        listen: false,
      )._globalStateKey.currentState!;

  static V select<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>, V extends Object?>(
    BuildContext context,
    V Function(S scope) selector,
  ) =>
      ScopeModelCore.select<W, ScopeElement<W, D, S>,
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
  Completer<void>? _closeCompleter;
  Completer<void>? _screenshotCompleter;

  ScopeElement(super.widget);

  @override
  bool get onlyOneInstance => widget.onlyOneInstance;

  @override
  bool get autoSelfDependence => _autoSelfDependence;

  @override
  Duration? get pauseAfterInitialization => widget.pauseAfterInitialization;

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

    final child = _ScopeStateWidget<W, D, S>(
      key: _globalStateKey,
      createState: _createState,
    );

    return widget.wrapState(
      this,
      dependencies,
      switch (_closeCompleter) {
        null => child,
        _ => Stack(
            children: [
              ScreenshotReplacer(
                onCompleted: () {
                  _screenshotCompleter?.complete();
                },
                child: child,
              ),
              Positioned.fill(
                child: ColoredBox(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.8),
                  child: const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                ),
              ),
            ],
          ),
      },
    );
  }

  S _createState() => widget.createState().._scopeElement = this;

  @override
  Future<void> _runDisposeAsync(W widget) async {
    if (_closeCompleter case final closeCompleter?) {
      return closeCompleter.future;
    }

    final completer = Completer<void>();
    _closeCompleter = completer;
    final screenshotCompleter = Completer<void>();
    _screenshotCompleter = screenshotCompleter;
    markNeedsBuild();
    await screenshotCompleter.future;

    try {
      await super._runDisposeAsync(widget);
    } finally {
      completer.complete();
    }
  }

  Future<void> close() async {
    await _runDisposeAsync(widget);
  }
}
