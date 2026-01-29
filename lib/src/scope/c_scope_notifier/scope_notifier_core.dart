part of '../scope.dart';

abstract base class ScopeNotifierCore<
    W extends ScopeNotifierCore<W, E, M>,
    E extends ScopeNotifierElementBase<W, E, M>,
    M extends Listenable> extends ScopeModelCore<W, E, M> {
  const ScopeNotifierCore({
    super.key,
    super.tag,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  @override
  InheritedElement createScopeElement();

  static E? maybeOf<W extends ScopeNotifierCore<W, E, M>,
          E extends ScopeNotifierElementBase<W, E, M>, M extends Listenable>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<W, E>(context, listen: listen);

  static E of<W extends ScopeNotifierCore<W, E, M>,
          E extends ScopeNotifierElementBase<W, E, M>, M extends Listenable>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<W, E>(context, listen: listen);

  static V select<
          W extends ScopeNotifierCore<W, E, M>,
          E extends ScopeNotifierElementBase<W, E, M>,
          M extends Listenable,
          V extends Object?>(
    BuildContext context,
    V Function(E element) selector,
  ) =>
      ScopeContext.select<W, E, V>(context, selector);
}

abstract base class ScopeNotifierElementBase<W extends ScopeModelCore<W, E, M>,
        E extends ScopeNotifierElementBase<W, E, M>, M extends Listenable>
    extends ScopeModelElementBase<W, E, M> implements ScopeModelContext<W, M> {
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
