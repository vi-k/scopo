part of '../scope.dart';

/// {@category Scope}
abstract base class ScopeCore<
    W extends ScopeCore<W, E, D, S>,
    E extends ScopeElementBase<W, E, D, S>,
    D extends ScopeDependencies,
    S extends ScopeCoreState<W, E, D, S>> extends LiteScopeCore<W, E, S> {
  const ScopeCore({
    super.key,
    super.tag,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  static W paramsOf<
          W extends ScopeCore<W, E, D, S>,
          E extends ScopeElementBase<W, E, D, S>,
          D extends ScopeDependencies,
          S extends ScopeCoreState<W, E, D, S>>(
    BuildContext context, {
    required bool listen,
  }) =>
      listen
          ? ScopeContext.select<W, E, W>(
              context,
              (element) => element.widget,
            )
          : ScopeContext.of<W, E>(
              context,
              listen: false,
            ).widget;

  static V selectParam<
          W extends ScopeCore<W, E, D, S>,
          E extends ScopeElementBase<W, E, D, S>,
          D extends ScopeDependencies,
          S extends ScopeCoreState<W, E, D, S>,
          V extends Object?>(
    BuildContext context,
    V Function(W widget) selector,
  ) =>
      ScopeContext.select<W, E, V>(
        context,
        (element) => selector(element.widget),
      );

  static S? maybeOf<
          W extends ScopeCore<W, E, D, S>,
          E extends ScopeElementBase<W, E, D, S>,
          D extends ScopeDependencies,
          S extends ScopeCoreState<W, E, D, S>>(BuildContext context) =>
      ScopeContext.maybeOf<W, E>(
        context,
        listen: false,
      )?._globalStateKey.currentState;

  static S of<
          W extends ScopeCore<W, E, D, S>,
          E extends ScopeElementBase<W, E, D, S>,
          D extends ScopeDependencies,
          S extends ScopeCoreState<W, E, D, S>>(BuildContext context) =>
      ScopeContext.of<W, E>(
        context,
        listen: false,
      )._globalStateKey.currentState!;

  static V select<
          W extends ScopeCore<W, E, D, S>,
          E extends ScopeElementBase<W, E, D, S>,
          D extends ScopeDependencies,
          S extends ScopeCoreState<W, E, D, S>,
          V extends Object?>(
    BuildContext context,
    V Function(S scope) selector,
  ) =>
      ScopeContext.select<W, E, V>(
        context,
        (element) => selector(element._globalStateKey.currentState!),
      );
}

/// {@category Scope}
abstract base class ScopeElementBase<
        W extends ScopeCore<W, E, D, S>,
        E extends ScopeElementBase<W, E, D, S>,
        D extends ScopeDependencies,
        S extends ScopeCoreState<W, E, D, S>>
    extends LiteScopeElementBase<W, E, S> {
  ScopeElementBase(super.widget);

  D get dependencies => _dependencies ?? (throw StateError('Not initialized'));
  D? _dependencies;

  //
  // Overriding block
  //

  Stream<ScopeInitState<Object, D>> initDependencies();

  @override
  Widget? buildOnWaiting();

  @override
  Widget buildOnInitializing(Object? progress);

  @override
  Widget buildOnError(
    Object error,
    StackTrace stackTrace,
    Object? progress,
  );

  @override
  S createState();

  @override
  Widget wrapState(Widget child) => child;

  @override
  Widget? buildOnClosing() => null;

  //
  // End of overriding block
  //

  @override
  Stream<AsyncScopeInitState> initAsync() => initDependencies().map(
        (state) {
          switch (state) {
            case ScopeProgress(:final progress):
              return AsyncScopeProgress(progress);
            case ScopeReady(:final dependencies):
              _dependencies = dependencies;
              return AsyncScopeReady();
          }
        },
      );

  @override
  void unmount() {
    _dependencies?.unmount();
    super.unmount();
  }

  @override
  Future<void> disposeAsync() async {
    await super.disposeAsync();
    final result = _dependencies?.dispose();
    if (result is Future<void>) {
      await result;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<D?>('dependencies', _dependencies));
  }
}

abstract base class ScopeCoreState<
    W extends ScopeCore<W, E, D, S>,
    E extends ScopeElementBase<W, E, D, S>,
    D extends ScopeDependencies,
    S extends ScopeCoreState<W, E, D, S>> extends LiteScopeCoreState<W, E, S> {
  D get dependencies => _scopeElement.dependencies;

  //
  // Overriding block
  //

  @override
  FutureOr<void> initAsync() {}

  @override
  FutureOr<void> disposeAsync() {}

  @override
  Widget build(BuildContext context);

  //
  // End of overriding block
  //
}
