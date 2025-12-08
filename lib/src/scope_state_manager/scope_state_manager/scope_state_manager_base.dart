part of '../scope_state_manager.dart';

abstract base class ScopeStateManagerBase<W extends ScopeStateManagerBase<W, S>,
        S extends Object?>
    extends ScopeStateManagerBottom<W, ScopeStateManagerElement<W, S>, S> {
  const ScopeStateManagerBase({
    super.key,
    required super.initialState,
    required super.builder,
    super.debugString,
  });

  @override
  ScopeStateManagerElement<W, S> createElement() =>
      ScopeStateManagerElement<W, S>(this as W);

  static ScopeStateManagerElement<W, S>?
      maybeGet<W extends ScopeStateManagerBase<W, S>, S extends Object?>(
    BuildContext context,
  ) =>
          ScopeStateManagerBottom.maybeGet<W, ScopeStateManagerElement<W, S>,
              S>(context);

  static ScopeStateManagerElement<W, S>
      get<W extends ScopeStateManagerBase<W, S>, S extends Object?>(
    BuildContext context,
  ) =>
          ScopeStateManagerBottom.get<W, ScopeStateManagerElement<W, S>, S>(
              context);

  static ScopeStateManagerElement<W, S>?
      maybeDepend<W extends ScopeStateManagerBase<W, S>, S extends Object?>(
    BuildContext context,
  ) =>
          ScopeStateManagerBottom.maybeDepend<W, ScopeStateManagerElement<W, S>,
              S>(context);

  static ScopeStateManagerElement<W, S>
      depend<W extends ScopeStateManagerBase<W, S>, S extends Object?>(
    BuildContext context,
  ) =>
          ScopeStateManagerBottom.depend<W, ScopeStateManagerElement<W, S>, S>(
              context);

  static V? maybeSelect<W extends ScopeStateManagerBase<W, S>,
          S extends Object?, V extends Object?>(
    BuildContext context,
    V Function(ScopeStateManagerElement<W, S>) selector,
  ) =>
      ScopeStateManagerBottom.maybeSelect<W, ScopeStateManagerElement<W, S>, S,
          V>(context, selector);

  static V select<W extends ScopeStateManagerBase<W, S>, S extends Object?,
          V extends Object?>(
    BuildContext context,
    V Function(ScopeStateManagerElement<W, S>) selector,
  ) =>
      ScopeStateManagerBottom.select<W, ScopeStateManagerElement<W, S>, S, V>(
          context, selector);

  static ScopeStateManagerElement<W, S>?
      maybeOf<W extends ScopeStateManagerBase<W, S>, S extends Object?>(
    BuildContext context, {
    bool listen = true,
  }) =>
          (listen ? maybeDepend<W, S> : maybeGet<W, S>)(context);

  static ScopeStateManagerElement<W, S>
      of<W extends ScopeStateManagerBase<W, S>, S extends Object?>(
    BuildContext context, {
    bool listen = true,
  }) =>
          (listen ? depend<W, S> : get<W, S>)(context);

  static S?
      maybeStateOf<W extends ScopeStateManagerBase<W, S>, S extends Object?>(
    BuildContext context, {
    bool listen = true,
  }) =>
          listen
              ? maybeSelect<W, S, S>(context, (f) => f.model.state)
              : maybeGet<W, S>(context)?.model.state;

  static S stateOf<W extends ScopeStateManagerBase<W, S>, S extends Object?>(
    BuildContext context, {
    bool listen = true,
  }) =>
      listen
          ? select<W, S, S>(context, (f) => f.model.state)
          : get<W, S>(context).model.state;

  @override
  String toStringShort() =>
      debugString?.call() ?? '${ScopeStateManagerBase<W, S>}';
}

base class ScopeStateManagerElement<W extends ScopeStateManagerBase<W, S>,
        S extends Object?>
    extends ScopeStateManagerElementBase<W, ScopeStateManagerElement<W, S>, S> {
  ScopeStateManagerElement(super.widget);
}
