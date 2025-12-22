part of '../scope_model.dart';

abstract base class ScopeNotifierBottom<
    W extends ScopeNotifierBottom<W, E, M>,
    E extends ScopeNotifierElementBase<W, E, M>,
    M extends Listenable> extends ScopeModelBottom<W, E, M> {
  const ScopeNotifierBottom({
    super.key,
  });

  @override
  E createScopeElement();

  static C? maybeOf<W extends ScopeInheritedWidget,
          C extends ScopeModelContext<W, M>, M extends Listenable>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeModelBottom.maybeOf<W, C, M>(context, listen: listen);

  static C of<W extends ScopeInheritedWidget, C extends ScopeModelContext<W, M>,
          M extends Listenable>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeModelBottom.of<W, C, M>(context, listen: listen);

  static V select<
          W extends ScopeInheritedWidget,
          C extends ScopeModelContext<W, M>,
          M extends Listenable,
          V extends Object?>(
    BuildContext context,
    V Function(C context) selector,
  ) =>
      ScopeModelBottom.select<W, C, M, V>(context, selector);
}

abstract base class ScopeNotifierElementBase<
        W extends ScopeModelBottom<W, E, M>,
        E extends ScopeNotifierElementBase<W, E, M>,
        M extends Listenable> extends ScopeModelElementBase<W, E, M>
    implements ScopeModelContext<W, M> {
  ScopeNotifierElementBase(super.widget);

  @override
  void init() {
    model.addListener(notifyDependents);
    super.init();
  }

  @override
  void dispose() {
    super.dispose();
    model.removeListener(notifyDependents);
  }
}
