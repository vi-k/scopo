part of '../scope_initializer.dart';

abstract base class ScopeStateBuilderBase<W extends ScopeStateBuilderBase<W, S>,
        S extends Object>
    extends ScopeStateBuilderBottom<W, ScopeStateBuilderElement<W, S>, S> {
  const ScopeStateBuilderBase({
    super.key,
    super.selfDependence = true,
    required super.initialState,
  });

  Widget build(BuildContext context, ScopeStateNotifier<S> notifier);

  @override
  ScopeStateBuilderElement<W, S> createScopeElement() =>
      ScopeStateBuilderElement<W, S>(this as W);

  static ScopeContext<W, ScopeStateModel<S>>?
      maybeOf<W extends ScopeStateBuilderBase<W, S>, S extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeProviderBottom.maybeOf<W, ScopeContext<W, ScopeStateModel<S>>,
              ScopeStateModel<S>>(context, listen: listen);

  static ScopeContext<W, ScopeStateModel<S>>
      of<W extends ScopeStateBuilderBase<W, S>, S extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
          ScopeProviderBottom.of<W, ScopeContext<W, ScopeStateModel<S>>,
              ScopeStateModel<S>>(context, listen: listen);

  static V select<W extends ScopeStateBuilderBase<W, S>, S extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(ScopeContext<W, ScopeStateModel<S>> context) selector,
  ) =>
      ScopeProviderBottom.select<W, ScopeContext<W, ScopeStateModel<S>>,
          ScopeStateModel<S>, V>(context, selector);
}

final class ScopeStateBuilderElement<W extends ScopeStateBuilderBase<W, S>,
        S extends Object>
    extends ScopeStateBuilderElementBase<W, ScopeStateBuilderElement<W, S>, S> {
  ScopeStateBuilderElement(super.widget);

  @override
  Widget buildBranch() => widget.build(this, _notifier);
}
