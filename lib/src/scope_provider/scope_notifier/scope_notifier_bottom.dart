part of '../scope_provider.dart';

abstract base class ScopeNotifierBottom<
    W extends ScopeNotifierBottom<W, E, M>,
    E extends ScopeNotifierElementBase<W, E, M>,
    M extends Listenable> extends ScopeProviderBottom<W, E, M> {
  const ScopeNotifierBottom({
    super.key,
  });

  // +++
  // @override
  // bool updateShouldNotify(ScopeNotifierBottom<W, E, T> oldWidget) => false;

  @override
  E createScopeElement();

  static C? maybeOf<W extends ScopeInheritedWidget,
          C extends ScopeContext<W, M>, M extends Listenable>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeProviderBottom.maybeOf<W, C, M>(context, listen: listen);

  static C of<W extends ScopeInheritedWidget, C extends ScopeContext<W, M>,
          M extends Listenable>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeProviderBottom.of<W, C, M>(context, listen: listen);

  static V select<W extends ScopeInheritedWidget, C extends ScopeContext<W, M>,
          M extends Listenable, V extends Object?>(
    BuildContext context,
    V Function(C context) selector,
  ) =>
      ScopeProviderBottom.select<W, C, M, V>(context, selector);
}

abstract base class ScopeNotifierElementBase<
        W extends ScopeProviderBottom<W, E, M>,
        E extends ScopeNotifierElementBase<W, E, M>,
        M extends Listenable> extends ScopeProviderElementBase<W, E, M>
    implements ScopeContext<W, M> {
  ScopeNotifierElementBase(super.widget);
  var _shouldNotify = false;
  var _updateChild = true;

  @override
  void init() {
    model.addListener(_listener);
    super.init();
  }

  @override
  void dispose() {
    super.dispose();
    model.removeListener(_listener);
  }

  void _listener() {
    _shouldNotify = true;
    markNeedsBuild();
  }

  @override
  void notifyClients(W oldWidget) {
    super.notifyClients(oldWidget);
    _shouldNotify = false;
  }

  @override
  void performRebuild() {
    if (_shouldNotify) {
      notifyClients(widget);
      _updateChild = dependencies?.contains(this) ?? false;
    }
    super.performRebuild();
    _updateChild = true;
  }

  @override
  Element? updateChild(Element? child, Widget? newWidget, Object? newSlot) =>
      _updateChild ? super.updateChild(child, newWidget, newSlot) : child;
}
