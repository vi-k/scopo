part of '../scope.dart';

abstract base class ScopeStateBuilderCore<
    W extends ScopeStateBuilderCore<W, E, S>,
    E extends ScopeStateBuilderElementBase<W, E, S>,
    S extends Object> extends ScopeNotifierCore<W, E, ScopeStateModel<S>> {
  final S initialState;

  const ScopeStateBuilderCore({
    super.key,
    super.tag,
    required this.initialState,
  });

  @override
  E createScopeElement();

  static E? maybeOf<W extends ScopeStateBuilderCore<W, E, S>,
          E extends ScopeStateBuilderElementBase<W, E, S>, S extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<W, E>(
        context,
        listen: listen,
      );

  static E of<W extends ScopeStateBuilderCore<W, E, S>,
          E extends ScopeStateBuilderElementBase<W, E, S>, S extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<W, E>(context, listen: listen);

  static V select<
          W extends ScopeStateBuilderCore<W, E, S>,
          E extends ScopeStateBuilderElementBase<W, E, S>,
          S extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(E element) selector,
  ) =>
      ScopeContext.select<W, E, V>(
        context,
        selector,
      );
}

abstract base class ScopeStateBuilderElementBase<
        W extends ScopeStateBuilderCore<W, E, S>,
        E extends ScopeStateBuilderElementBase<W, E, S>,
        S extends Object>
    extends ScopeNotifierElementBase<W, E, ScopeStateModel<S>> {
  late final ScopeStateNotifier<S> notifier;

  @override
  late final ScopeStateModel<S> model;

  ScopeStateBuilderElementBase(super.widget);

  @override
  void init() {
    notifier = ScopeStateNotifier(widget.initialState);
    model = notifier.asUnmodifiable();
    super.init();
  }

  @override
  void dispose() {
    super.dispose();
    notifier.dispose();
  }

  @override
  Set<InheritedElement>? get dependencies =>
      autoSelfDependence ? {...?super.dependencies, this} : super.dependencies;
}
