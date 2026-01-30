part of '../scope.dart';

/// {@category Scope}
typedef ScopeInitFunction<P extends Object, D extends ScopeDependencies>
    = Stream<ScopeInitState<P, D>> Function(BuildContext context);

/// {@category Scope}
typedef ScopeWaitingBuilder = Widget? Function(BuildContext context);

/// {@category Scope}
typedef ScopeInitBuilder<P extends Object> = Widget Function(
  BuildContext context,
  P? progress,
);

/// {@category Scope}
typedef ScopeErrorBuilder<P extends Object> = Widget Function(
  BuildContext context,
  Object error,
  StackTrace stackTrace,
  P? progress,
);

/// {@category Scope}
abstract base class Scope<W extends Scope<W, D, S>, D extends ScopeDependencies,
        S extends ScopeState<W, D, S>>
    extends ScopeCore<W, _ScopeElement<W, D, S>, D, S> {
  final Object? scopeKey;
  final Duration? scopeKeyTimeout;
  final void Function()? onScopeKeyTimeout;
  final Duration? waitForChildrenTimeout;
  final void Function()? onWaitForChildrenTimeout;
  final Duration? pauseAfterInitialization;

  const Scope({
    super.key,
    super.tag,
    this.scopeKey,
    this.scopeKeyTimeout,
    this.onScopeKeyTimeout,
    this.waitForChildrenTimeout,
    this.onWaitForChildrenTimeout,
    this.pauseAfterInitialization,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  Stream<ScopeInitState<Object, D>> initDependencies(BuildContext context);

  Widget? buildOnWaiting(BuildContext context) => null;

  Widget buildOnInitializing(BuildContext context, Object? progress);

  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  );

  S createState();

  /// Wraps state.
  Widget wrapState(BuildContext context, D dependencies, Widget child) => child;

  Widget? buildOnClosing(BuildContext context) => null;

  @override
  // ignore: library_private_types_in_public_api
  _ScopeElement<W, D, S> createScopeElement() => _ScopeElement(this as W);

  static W paramsOf<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>>(
    BuildContext context, {
    required bool listen,
  }) =>
      listen
          ? ScopeContext.select<W, _ScopeElement<W, D, S>, W>(
              context,
              (element) => element.widget,
            )
          : ScopeContext.of<W, _ScopeElement<W, D, S>>(
              context,
              listen: false,
            ).widget;

  static V selectParam<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>, V extends Object?>(
    BuildContext context,
    V Function(W widget) selector,
  ) =>
      ScopeContext.select<W, _ScopeElement<W, D, S>, V>(
        context,
        (element) => selector(element.widget),
      );

  static S? maybeOf<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>>(BuildContext context) =>
      ScopeContext.maybeOf<W, _ScopeElement<W, D, S>>(
        context,
        listen: false,
      )?._globalStateKey.currentState;

  static S of<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>>(BuildContext context) =>
      ScopeContext.of<W, _ScopeElement<W, D, S>>(
        context,
        listen: false,
      )._globalStateKey.currentState!;

  static V select<W extends Scope<W, D, S>, D extends ScopeDependencies,
          S extends ScopeState<W, D, S>, V extends Object?>(
    BuildContext context,
    V Function(S scope) selector,
  ) =>
      ScopeContext.select<W, _ScopeElement<W, D, S>, V>(
        context,
        (element) => selector(element._globalStateKey.currentState!),
      );
}

final class _ScopeElement<W extends Scope<W, D, S>, D extends ScopeDependencies,
        S extends ScopeState<W, D, S>>
    extends ScopeElementBase<W, _ScopeElement<W, D, S>, D, S> {
  _ScopeElement(super.widget);

  @override
  Object? get scopeKey => widget.scopeKey;

  @override
  Duration? get scopeKeyTimeout => widget.scopeKeyTimeout;

  @override
  void onScopeKeyTimeout() => widget.onScopeKeyTimeout?.call();

  @override
  Duration? get waitForChildrenTimeout => widget.waitForChildrenTimeout;

  @override
  void onWaitForChildrenTimeout() => widget.onWaitForChildrenTimeout?.call();

  @override
  Duration? get pauseAfterInitialization => widget.pauseAfterInitialization;

  @override
  Stream<ScopeInitState<Object, D>> initDependencies() =>
      widget.initDependencies(this);

  @override
  Widget buildOnWaiting() =>
      widget.buildOnWaiting(this) ?? widget.buildOnInitializing(this, null);

  @override
  Widget buildOnInitializing(Object? progress) =>
      widget.buildOnInitializing(this, progress);

  @override
  Widget buildOnError(
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) =>
      widget.buildOnError(this, error, stackTrace, progress);

  @override
  S createState() => widget.createState();

  @override
  Widget wrapState(Widget child) => widget.wrapState(this, dependencies, child);

  @override
  Widget? buildOnClosing() => widget.buildOnClosing(this);
}

abstract base class ScopeState<W extends Scope<W, D, S>,
        D extends ScopeDependencies, S extends ScopeState<W, D, S>>
    extends ScopeCoreState<W, _ScopeElement<W, D, S>, D, S> {
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
