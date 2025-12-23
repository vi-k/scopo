part of '../scope.dart';

abstract base class ScopeStateBuilderBase<W extends ScopeStateBuilderBase<W, S>,
        S extends Object>
    extends ScopeStateBuilderBottom<W, ScopeStateBuilderElement<W, S>, S> {
  final bool autoSelfDependence;

  const ScopeStateBuilderBase({
    super.key,
    super.tag,
    this.autoSelfDependence = true,
    required super.initialState,
  });

  Widget build(BuildContext context, ScopeStateNotifier<S> notifier);

  @override
  ScopeStateBuilderElement<W, S> createScopeElement() =>
      ScopeStateBuilderElement<W, S>(this as W);

  static ScopeModelContext<W, ScopeStateModel<S>>?
      maybeOf<W extends ScopeStateBuilderBase<W, S>, S extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.maybeOf<W, ScopeModelContext<W, ScopeStateModel<S>>>(
            context,
            listen: listen,
          );

  static ScopeModelContext<W, ScopeStateModel<S>>
      of<W extends ScopeStateBuilderBase<W, S>, S extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeContext.of<W, ScopeModelContext<W, ScopeStateModel<S>>>(
            context,
            listen: listen,
          );

  static V select<W extends ScopeStateBuilderBase<W, S>, S extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(ScopeModelContext<W, ScopeStateModel<S>> context) selector,
  ) =>
      ScopeContext.select<W, ScopeModelContext<W, ScopeStateModel<S>>, V>(
        context,
        selector,
      );
}

final class ScopeStateBuilderElement<W extends ScopeStateBuilderBase<W, S>,
        S extends Object>
    extends ScopeStateBuilderElementBase<W, ScopeStateBuilderElement<W, S>, S> {
  ScopeStateBuilderElement(super.widget);

  @override
  bool get autoSelfDependence => widget.autoSelfDependence;

  @override
  Widget buildBranch() => widget.build(this, notifier);
}
