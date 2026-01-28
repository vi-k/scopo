part of '../scope.dart';

abstract base class LiteScope<W extends LiteScope<W, S>,
        S extends LiteScopeState<W, S>>
    extends LiteScopeCore<W, LiteScopeElement<W, S>, S> {
  final Object? scopeKey;
  final Duration? pauseAfterInitialization;

  const LiteScope({
    super.key,
    super.tag,
    this.scopeKey,
    this.pauseAfterInitialization,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  //
  // Overriding block
  //

  Stream<AsyncScopeInitState> init() => Stream.value(AsyncScopeReady());

  Widget? buildOnWaiting(BuildContext context);

  Widget buildOnInitializing(BuildContext context, Object? progress) =>
      throw UnimplementedError();

  Widget buildOnError(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
    Object? progress,
  ) =>
      throw UnimplementedError();

  S createState();

  /// Wraps state.
  Widget wrapState(BuildContext context, Widget child) => child;

  Widget? buildOnClosing(BuildContext context) => null;

  //
  // End of overriding block
  //

  @override
  LiteScopeElement<W, S> createScopeElement() => LiteScopeElement(this as W);

  static W paramsOf<W extends LiteScope<W, S>, S extends LiteScopeState<W, S>>(
    BuildContext context, {
    required bool listen,
  }) =>
      listen
          ? ScopeContext.select<W, LiteScopeElement<W, S>, W>(
              context,
              (element) => element.widget,
            )
          : ScopeContext.of<W, LiteScopeElement<W, S>>(
              context,
              listen: false,
            ).widget;

  static V selectParam<W extends LiteScope<W, S>,
          S extends LiteScopeState<W, S>, V extends Object?>(
    BuildContext context,
    V Function(W widget) selector,
  ) =>
      ScopeContext.select<W, LiteScopeElement<W, S>, V>(
        context,
        (element) => selector(element.widget),
      );

  static S? maybeOf<W extends LiteScope<W, S>, S extends LiteScopeState<W, S>>(
    BuildContext context,
  ) =>
      ScopeContext.maybeOf<W, LiteScopeElement<W, S>>(
        context,
        listen: false,
      )?._globalStateKey.currentState;

  static S of<W extends LiteScope<W, S>, S extends LiteScopeState<W, S>>(
    BuildContext context,
  ) =>
      ScopeContext.of<W, LiteScopeElement<W, S>>(
        context,
        listen: false,
      )._globalStateKey.currentState!;

  static V select<W extends LiteScope<W, S>, S extends LiteScopeState<W, S>,
          V extends Object?>(
    BuildContext context,
    V Function(S scope) selector,
  ) =>
      ScopeContext.select<W, LiteScopeElement<W, S>, V>(
        context,
        (element) => selector(element._globalStateKey.currentState!),
      );
}

final class LiteScopeElement<W extends LiteScope<W, S>,
        S extends LiteScopeState<W, S>>
    extends LiteScopeElementBase<W, LiteScopeElement<W, S>, S> {
  LiteScopeElement(super.widget);

  @override
  Object? get scopeKey => widget.scopeKey;

  @override
  Duration? get pauseAfterInitialization => widget.pauseAfterInitialization;

  @override
  Stream<AsyncScopeInitState> initAsync() => widget.init();

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
  Widget? buildOnClosing() => widget.buildOnClosing(this);
}

abstract base class LiteScopeState<W extends LiteScope<W, S>,
        S extends LiteScopeState<W, S>>
    extends LiteScopeCoreState<W, LiteScopeElement<W, S>, S> {
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
