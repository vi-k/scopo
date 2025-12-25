part of '../scope.dart';

typedef _ScopeDependency<T extends Object, V extends Object?> = (
  V,
  V Function(T),
);

abstract base class ScopeWidgetCore<W extends ScopeWidgetCore<W, E>,
    E extends ScopeWidgetElementBase<W, E>> extends ScopeInheritedWidget {
  const ScopeWidgetCore({
    super.key,
    super.tag,
  });

  E createScopeElement();

  @override
  InheritedElement createElement() => createScopeElement();

  @override
  bool updateShouldNotify(ScopeWidgetCore<W, E> oldWidget) => true;

  @override
  String toStringShort() => '$W${tag == null ? '' : '($tag)'}';

  static E? maybeOf<W extends ScopeWidgetCore<W, E>,
          E extends ScopeWidgetElementBase<W, E>>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<W, E>(context, listen: listen);

  static E of<W extends ScopeWidgetCore<W, E>,
          E extends ScopeWidgetElementBase<W, E>>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<W, E>(context, listen: listen);

  static V select<W extends ScopeWidgetCore<W, E>,
          E extends ScopeWidgetElementBase<W, E>, V extends Object?>(
    BuildContext context,
    V Function(E element) selector,
  ) =>
      ScopeContext.select<W, E, V>(context, selector);
}

abstract base class ScopeWidgetElementBase<W extends ScopeWidgetCore<W, E>,
        E extends ScopeWidgetElementBase<W, E>> extends InheritedElement
    implements ScopeInheritedElement<W> {
  var _shouldNotify = false;
  var _updateChild = true;

  ScopeWidgetElementBase(W super.widget) {
    init();
  }

  @override
  W get widget => super.widget as W;

  @override
  void unmount() {
    dispose();
    super.unmount();
  }

  bool get autoSelfDependence;

  @override
  Set<InheritedElement>? get dependencies =>
      autoSelfDependence ? {...?super.dependencies, this} : super.dependencies;

  @override
  void init() {}

  @override
  void dispose() {}

  List<_ScopeDependency<E, Object?>> _createDependencies() => [];

  @override
  void updateDependencies(Element dependent, Object? aspect) {
    final dependencies =
        getDependencies(dependent) as List<_ScopeDependency<E, Object?>>?;

    /// Уже подписались на все изменения.
    if (dependencies != null && dependencies.isEmpty) {
      return;
    }

    if (aspect == null) {
      // Подписываемся на все изменения.
      setDependencies(dependent, _createDependencies());
    } else if (aspect case _ScopeDependency<E, Object?>()) {
      setDependencies(
        dependent,
        (dependencies ?? _createDependencies())..add(aspect),
      );
    } else {
      assert(false, '`aspect` must be ${_ScopeDependency<E, Object?>}');
    }
  }

  @override
  void notifyDependent(W oldWidget, Element dependent) {
    final dependencies =
        getDependencies(dependent) as List<_ScopeDependency<E, Object?>>?;
    if (dependencies == null) {
      return;
    }

    if (dependencies.isEmpty) {
      dependent.didChangeDependencies();
      return;
    }

    for (final (value, selector) in dependencies) {
      if (selector(this as E) != value) {
        setDependencies(dependent, null);
        dependent.didChangeDependencies();
        return;
      }
    }
  }

  /// [InheritedElement.notifyClients] does not support self-subscription,
  /// although this is required in our case.
  @override
  void notifyClients(W oldWidget) {
    try {
      for (final dependent in dependents.keys) {
        assert(() {
          // check that it really is our descendant
          if (dependent == this) {
            return true;
          }

          Element? ancestor = dependent;
          dependent.visitAncestorElements((element) {
            ancestor = element;
            return element != this;
          });

          return ancestor == this;
        }());
        // check that it really depends on us
        assert(dependent.dependencies!.contains(this));
        notifyDependent(oldWidget, dependent);
      }
    } finally {
      _shouldNotify = false;
    }
  }

  void notifyDependents() {
    _shouldNotify = true;
    markNeedsBuild();
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

  @nonVirtual
  @override
  Widget build() => buildChild();
}
