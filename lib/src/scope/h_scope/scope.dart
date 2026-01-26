part of '../scope.dart';

typedef ScopeInitFunction<P extends Object, D extends ScopeDependencies>
    = Stream<ScopeInitState<P, D>> Function(BuildContext context);

typedef ScopeInitBuilder<P extends Object> = Widget Function(
  BuildContext context,
  P? progress,
);

typedef ScopeErrorBuilder<P extends Object> = Widget Function(
  BuildContext context,
  Object error,
  StackTrace stackTrace,
  P? progress,
);

abstract base class Scope<W extends Scope<W, D, S>, D extends ScopeDependencies,
        S extends ScopeState<W, D, S>>
    extends StreamScopeCore<W, ScopeElement<W, D, S>, D> {
  final Object? scopeKey;
  final Duration? pauseAfterInitialization;

  const Scope({
    super.key,
    super.tag,
    this.scopeKey,
    this.pauseAfterInitialization,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  Stream<ScopeInitState<Object, D>> initDependencies(BuildContext context);

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
      listen
          ? ScopeModelCore.select<
              W,
              ScopeElement<W, D, S>,
              ScopeStateModel<AsyncScopeState<D>>,
              W>(context, (element) => element.widget)
          : ScopeModelCore.of<W, ScopeElement<W, D, S>,
              ScopeStateModel<AsyncScopeState<D>>>(
              context,
              listen: false,
            ).widget;

  static V selectParam<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>, V extends Object?>(
    BuildContext context,
    V Function(W widget) selector,
  ) =>
      ScopeModelCore.select<
          W,
          ScopeElement<W, D, S>,
          ScopeStateModel<AsyncScopeState<D>>,
          V>(context, (element) => selector(element.widget));

  static S? maybeOf<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>>(BuildContext context) =>
      ScopeModelCore.maybeOf<W, ScopeElement<W, D, S>,
          ScopeStateModel<AsyncScopeState<D>>>(
        context,
        listen: false,
      )?._globalStateKey.currentState;

  static S of<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>>(BuildContext context) =>
      ScopeModelCore.of<W, ScopeElement<W, D, S>,
          ScopeStateModel<AsyncScopeState<D>>>(
        context,
        listen: false,
      )._globalStateKey.currentState!;

  static V select<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>, V extends Object?>(
    BuildContext context,
    V Function(S scope) selector,
  ) =>
      ScopeModelCore.select<W, ScopeElement<W, D, S>,
          ScopeStateModel<AsyncScopeState<D>>, V>(
        context,
        (element) => selector(element._globalStateKey.currentState!),
      );
}

final class ScopeElement<W extends Scope<W, D, S>, D extends ScopeDependencies,
        S extends ScopeState<W, D, S>>
    extends StreamScopeElementBase<W, ScopeElement<W, D, S>, D> {
  var _autoSelfDependence = true;
  final _globalStateKey = GlobalKey<S>();
  S? _state;
  Completer<void>? _closeCompleter;
  Completer<void>? _screenshotCompleter;

  // Создаём копию, чтобы позже использовать в dispose.
  @override
  final Object? scopeKey;

  ScopeElement(super.widget) : scopeKey = widget.scopeKey;

  @override
  bool get autoSelfDependence => _autoSelfDependence;

  @override
  Duration? get pauseAfterInitialization => widget.pauseAfterInitialization;

  @override
  Stream<ScopeInitState<Object, D>> asyncInit() =>
      widget.initDependencies(this);

  @override
  Future<void> asyncDispose(W widget, D data) async {
    if (_state case final state?) {
      await state._performAsyncDispose();
    }
    await data.dispose();
  }

  @override
  Widget buildOnState(AsyncScopeState<D> state) => widget.wrap(
        this,
        switch (state) {
          AsyncScopeWaiting() => widget.buildOnWaitingForPrevious?.call(this) ??
              widget.buildOnInitializing(this, null),
          AsyncScopeProgress(:final progress) =>
            widget.buildOnInitializing(this, progress),
          AsyncScopeReady(:final data) => buildOnReady(this, data),
          AsyncScopeError(:final error, :final stackTrace, :final progress) =>
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
      switch (_screenshotCompleter) {
        null => child,
        final screenshotCompleter => Stack(
            children: [
              ScreenshotReplacer(
                onCompleted: () {
                  if (!screenshotCompleter.isCompleted) {
                    screenshotCompleter.complete();
                  }
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

  S _createState() => _state = widget.createState().._scopeElement = this;

  @override
  Future<void> _performAsyncDispose(W widget) async {
    if (_closeCompleter case final closeCompleter?) {
      return closeCompleter.future;
    }

    final closeCompleter = Completer<void>();
    _closeCompleter = closeCompleter;

    markNeedsBuild();

    if (_screenshotCompleter case final screenshotCompleter?) {
      await screenshotCompleter.future;
    }

    try {
      await super._performAsyncDispose(widget);
    } finally {
      closeCompleter.complete();
    }
  }

  /// Закрывает скоуп до вызова dispose.
  ///
  /// Даёт возможность показать экран закрытия скоупа, заменяя содержимое
  /// виджета скриншотом.
  Future<void> close() async {
    _screenshotCompleter = Completer<void>();
    await _performAsyncDispose(widget);
  }
}
