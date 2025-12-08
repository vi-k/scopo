part of '../scope_provider.dart';

abstract base class ScopeListenableProviderBottom<
    W extends ScopeListenableProviderBottom<W, E, T>,
    E extends ScopeListenableProviderElementBase<W, E, T>,
    T extends Listenable> extends ScopeProviderBottom<W, E, T> {
  const ScopeListenableProviderBottom({
    super.key,
    required super.create,
    super.dispose,
    super.debugString,
    required super.builder,
  });

  // @override
  // bool updateShouldNotify(ScopeProviderBottom<W, E, T> oldWidget) => false;

  const ScopeListenableProviderBottom.value({
    super.key,
    required super.value,
    super.debugString,
    required super.builder,
  }) : super.value();

  const ScopeListenableProviderBottom.raw({
    super.key,
    super.debugString,
    required super.builder,
  }) : super.raw();

  @override
  E createElement();

  static E? maybeGet<
          W extends ScopeListenableProviderBottom<W, E, T>,
          E extends ScopeListenableProviderElementBase<W, E, T>,
          T extends Listenable>(
    BuildContext context,
  ) =>
      ScopeProviderBottom.maybeGet<W, E, T>(context);

  static E get<
          W extends ScopeListenableProviderBottom<W, E, T>,
          E extends ScopeListenableProviderElementBase<W, E, T>,
          T extends Listenable>(
    BuildContext context,
  ) =>
      ScopeProviderBottom.get<W, E, T>(context);

  static E? maybeDepend<
          P extends ScopeListenableProviderBottom<P, E, T>,
          E extends ScopeListenableProviderElementBase<P, E, T>,
          T extends Listenable>(
    BuildContext context,
  ) =>
      ScopeProviderBottom.maybeDepend<P, E, T>(context);

  static E depend<
          P extends ScopeListenableProviderBottom<P, E, T>,
          E extends ScopeListenableProviderElementBase<P, E, T>,
          T extends Listenable>(
    BuildContext context,
  ) =>
      ScopeProviderBottom.depend<P, E, T>(context);

  static V? maybeSelect<
          P extends ScopeListenableProviderBottom<P, E, T>,
          E extends ScopeListenableProviderElementBase<P, E, T>,
          T extends Listenable,
          V extends Object?>(
    BuildContext context,
    V Function(E) selector,
  ) =>
      ScopeProviderBottom.maybeSelect<P, E, T, V>(context, selector);

  static V select<
          P extends ScopeListenableProviderBottom<P, E, T>,
          E extends ScopeListenableProviderElementBase<P, E, T>,
          T extends Listenable,
          V extends Object?>(
    BuildContext context,
    V Function(E) selector,
  ) =>
      ScopeProviderBottom.select<P, E, T, V>(context, selector);

  @override
  String toStringShort() =>
      debugString?.call() ?? '${ScopeListenableProviderBottom<W, E, T>}';
}

base class ScopeListenableProviderElementBase<
    W extends ScopeListenableProviderBottom<W, E, T>,
    E extends ScopeListenableProviderElementBase<W, E, T>,
    T extends Listenable> extends ScopeProviderElementBase<W, E, T> {
  var _shouldNotify = false;
  var _updateChild = true;

  ScopeListenableProviderElementBase(super.widget) {
    model.addListener(_listener);
  }

  @override
  void unmount() {
    model.removeListener(_listener);
    super.unmount();
  }

  @override
  void update(W newWidget) {
    if (widget.value != newWidget.value) {
      widget.value?.removeListener(_listener);
      newWidget.value?.removeListener(_listener);
    }
    super.update(newWidget);
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
      _updateChild = false;
    }
    super.performRebuild();
    _updateChild = true;
  }

  @override
  Element? updateChild(Element? child, Widget? newWidget, Object? newSlot) =>
      _updateChild ? super.updateChild(child, newWidget, newSlot) : child;

  @override
  Widget build() => widget.builder(this);
}
