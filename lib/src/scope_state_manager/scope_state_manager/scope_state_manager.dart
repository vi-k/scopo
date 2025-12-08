part of '../scope_state_manager.dart';

final class ScopeStateManager<S extends Object?>
    extends ScopeStateManagerBase<ScopeStateManager<S>, S> {
  const ScopeStateManager({
    super.key,
    required super.initialState,
    required super.builder,
    super.debugString,
  });

  static ScopeStateManagerElement<ScopeStateManager<S>, S>?
      maybeGet<S extends Object?>(
    BuildContext context,
  ) =>
          ScopeStateManagerBase.maybeGet<ScopeStateManager<S>, S>(context);

  static ScopeStateManagerElement<ScopeStateManager<S>, S>
      get<S extends Object?>(
    BuildContext context,
  ) =>
          ScopeStateManagerBase.get<ScopeStateManager<S>, S>(context);

  static ScopeStateManagerElement<ScopeStateManager<S>, S>?
      maybeDepend<S extends Object?>(
    BuildContext context,
  ) =>
          ScopeStateManagerBase.maybeDepend<ScopeStateManager<S>, S>(context);

  static ScopeStateManagerElement<ScopeStateManager<S>, S>
      depend<S extends Object?>(
    BuildContext context,
  ) =>
          ScopeStateManagerBase.depend<ScopeStateManager<S>, S>(context);

  static V? maybeSelect<S extends Object?, V extends Object?>(
    BuildContext context,
    V Function(ScopeStateManagerElement<ScopeStateManager<S>, S>) selector,
  ) =>
      ScopeStateManagerBase.maybeSelect<ScopeStateManager<S>, S, V>(
          context, selector);

  static V select<S extends Object?, V extends Object?>(
    BuildContext context,
    V Function(ScopeStateManagerElement<ScopeStateManager<S>, S>) selector,
  ) =>
      ScopeStateManagerBase.select<ScopeStateManager<S>, S, V>(
          context, selector);

  @override
  String toStringShort() => debugString?.call() ?? '${ScopeStateManager<S>}';
}
