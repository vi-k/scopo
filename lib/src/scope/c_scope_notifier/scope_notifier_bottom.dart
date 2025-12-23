part of '../scope.dart';

abstract base class ScopeNotifierBottom<
    W extends ScopeNotifierBottom<W, E, M>,
    E extends ScopeNotifierElementBase<W, E, M>,
    M extends Listenable> extends ScopeModelBottom<W, E, M> {
  const ScopeNotifierBottom({
    super.key,
  });

  @override
  E createScopeElement();

  static E? maybeOf<W extends ScopeNotifierBottom<W, E, M>,
          E extends ScopeNotifierElementBase<W, E, M>, M extends Listenable>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeWidgetContext.maybeOf<W, E>(context, listen: listen);

  static E of<W extends ScopeNotifierBottom<W, E, M>,
          E extends ScopeNotifierElementBase<W, E, M>, M extends Listenable>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeWidgetContext.of<W, E>(context, listen: listen);

  static V select<
          W extends ScopeNotifierBottom<W, E, M>,
          E extends ScopeNotifierElementBase<W, E, M>,
          M extends Listenable,
          V extends Object?>(
    BuildContext context,
    V Function(E element) selector,
  ) =>
      ScopeWidgetContext.select<W, E, V>(context, selector);
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
