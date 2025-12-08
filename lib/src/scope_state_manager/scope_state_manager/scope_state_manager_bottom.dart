part of '../scope_state_manager.dart';

abstract base class ScopeStateManagerBottom<
        W extends ScopeStateManagerBottom<W, E, S>,
        E extends ScopeStateManagerElementBase<W, E, S>,
        S extends Object?>
    extends ScopeNotifierBottom<W, E, ScopeStateManagerNotifier<S>> {
  final S initialState;

  const ScopeStateManagerBottom({
    super.key,
    required this.initialState,
    required super.builder,
    super.debugString,
  }) : super.raw();

  @override
  E createElement();

  static E? maybeGet<W extends ScopeStateManagerBottom<W, E, S>,
          E extends ScopeStateManagerElementBase<W, E, S>, S extends Object?>(
    BuildContext context,
  ) =>
      ScopeNotifierBottom.maybeGet<W, E, ScopeStateManagerNotifier<S>>(context);

  static E get<W extends ScopeStateManagerBottom<W, E, S>,
          E extends ScopeStateManagerElementBase<W, E, S>, S extends Object?>(
    BuildContext context,
  ) =>
      ScopeNotifierBottom.get<W, E, ScopeStateManagerNotifier<S>>(context);

  static E? maybeDepend<W extends ScopeStateManagerBottom<W, E, S>,
          E extends ScopeStateManagerElementBase<W, E, S>, S extends Object?>(
    BuildContext context,
  ) =>
      ScopeNotifierBottom.maybeDepend<W, E, ScopeStateManagerNotifier<S>>(
          context);

  static E depend<W extends ScopeStateManagerBottom<W, E, S>,
          E extends ScopeStateManagerElementBase<W, E, S>, S extends Object?>(
    BuildContext context,
  ) =>
      ScopeNotifierBottom.depend<W, E, ScopeStateManagerNotifier<S>>(context);

  static V? maybeSelect<
          W extends ScopeStateManagerBottom<W, E, S>,
          E extends ScopeStateManagerElementBase<W, E, S>,
          S extends Object?,
          V extends Object?>(
    BuildContext context,
    V Function(E) selector,
  ) =>
      ScopeNotifierBottom.maybeSelect<W, E, ScopeStateManagerNotifier<S>, V>(
          context, selector);

  static V select<
          W extends ScopeStateManagerBottom<W, E, S>,
          E extends ScopeStateManagerElementBase<W, E, S>,
          S extends Object?,
          V extends Object?>(
    BuildContext context,
    V Function(E) selector,
  ) =>
      ScopeNotifierBottom.select<W, E, ScopeStateManagerNotifier<S>, V>(
          context, selector);

  static E? maybeOf<W extends ScopeStateManagerBottom<W, E, S>,
          E extends ScopeStateManagerElementBase<W, E, S>, S extends Object?>(
    BuildContext context, {
    bool listen = true,
  }) =>
      (listen ? maybeDepend<W, E, S> : maybeGet<W, E, S>)(context);

  static E of<W extends ScopeStateManagerBottom<W, E, S>,
          E extends ScopeStateManagerElementBase<W, E, S>, S extends Object?>(
    BuildContext context, {
    bool listen = true,
  }) =>
      (listen ? depend<W, E, S> : get<W, E, S>)(context);

  static S? maybeStateOf<W extends ScopeStateManagerBottom<W, E, S>,
          E extends ScopeStateManagerElementBase<W, E, S>, S extends Object?>(
    BuildContext context, {
    bool listen = true,
  }) =>
      listen
          ? maybeSelect<W, E, S, S>(context, (f) => f.model.state)
          : maybeGet<W, E, S>(context)?.model.state;

  static S stateOf<W extends ScopeStateManagerBottom<W, E, S>,
          E extends ScopeStateManagerElementBase<W, E, S>, S extends Object?>(
    BuildContext context, {
    bool listen = true,
  }) =>
      listen
          ? select<W, E, S, S>(context, (f) => f.model.state)
          : get<W, E, S>(context).model.state;

  @override
  String toStringShort() =>
      debugString?.call() ?? '${ScopeStateManagerBottom<W, E, S>}';
}

base class ScopeStateManagerElementBase<
        W extends ScopeStateManagerBottom<W, E, S>,
        E extends ScopeStateManagerElementBase<W, E, S>,
        S extends Object?>
    extends ScopeNotifierElementBase<W, E, ScopeStateManagerNotifier<S>> {
  ScopeStateManagerElementBase(super.widget);

  @override
  ScopeStateManagerNotifier<S> createModel() =>
      ScopeStateManagerNotifier(widget.initialState);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(MessageProperty('state', '${model.state}'));
  }
}
