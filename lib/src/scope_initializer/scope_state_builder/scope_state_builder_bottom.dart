part of '../scope_initializer.dart';

abstract base class ScopeStateBuilderBottom<
    W extends ScopeStateBuilderBottom<W, E, S>,
    E extends ScopeStateBuilderElementBase<W, E, S>,
    S extends Object> extends ScopeNotifierBottom<W, E, ScopeStateModel<S>> {
  final S initialState;
  final bool selfDependence;

  const ScopeStateBuilderBottom({
    super.key,
    this.selfDependence = true,
    required this.initialState,
  });

  @override
  E createScopeElement();

  static E? maybeOf<W extends ScopeStateBuilderBottom<W, E, S>,
          E extends ScopeStateBuilderElementBase<W, E, S>, S extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeModelBottom.maybeOf<W, E, ScopeStateModel<S>>(
        context,
        listen: listen,
      );

  static E of<W extends ScopeStateBuilderBottom<W, E, S>,
          E extends ScopeStateBuilderElementBase<W, E, S>, S extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeModelBottom.of<W, E, ScopeStateModel<S>>(context, listen: listen);

  static V select<
          W extends ScopeStateBuilderBottom<W, E, S>,
          E extends ScopeStateBuilderElementBase<W, E, S>,
          S extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(E element) selector,
  ) =>
      ScopeModelBottom.select<W, E, ScopeStateModel<S>, V>(
        context,
        selector,
      );
}

abstract base class ScopeStateBuilderElementBase<
        W extends ScopeStateBuilderBottom<W, E, S>,
        E extends ScopeStateBuilderElementBase<W, E, S>,
        S extends Object>
    extends ScopeNotifierElementBase<W, E, ScopeStateModel<S>> {
  late final ScopeStateNotifier<S> _notifier;

  @override
  late final ScopeStateModel<S> model;

  ScopeStateBuilderElementBase(super.widget);

  @override
  void init() {
    _notifier = ScopeStateNotifier(widget.initialState);
    model = _notifier.asUnmodifiable();
    super.init();
  }

  @override
  void dispose() {
    super.dispose();
    _notifier.dispose();
  }

  @override
  Set<InheritedElement>? get dependencies => widget.selfDependence
      ? {...?super.dependencies, this}
      : super.dependencies;
}
