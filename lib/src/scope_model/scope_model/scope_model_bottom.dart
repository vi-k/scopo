part of '../scope_model.dart';

typedef _ScopeDependency<T extends Object, V extends Object?> = (
  V,
  V Function(T),
);

abstract base class ScopeModelBottom<
    W extends ScopeModelBottom<W, E, M>,
    E extends ScopeModelElementBase<W, E, M>,
    M extends Object> extends ScopeInheritedWidget {
  const ScopeModelBottom({
    super.key,
  }) : super(child: const _NullWidget());

  E createScopeElement();

  @override
  InheritedElement createElement() => createScopeElement();

  @override
  bool updateShouldNotify(ScopeModelBottom<W, E, M> oldWidget) => true;

  @override
  String toStringShort() => '$W';

  static C? maybeOf<W extends ScopeInheritedWidget,
          C extends ScopeModelContext<W, M>, M extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      _find<W, C, M, void>(context, listen: listen)?.$1;

  static C of<W extends ScopeInheritedWidget, C extends ScopeModelContext<W, M>,
          M extends Object>(
    BuildContext context, {
    required bool listen,
  }) =>
      _find<W, C, M, void>(context, listen: listen)?.$1 ?? _throwNotFound<W>();

  static V select<
          W extends ScopeInheritedWidget,
          C extends ScopeModelContext<W, M>,
          M extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(C context) selector,
  ) =>
      (_find<W, C, M, V>(context, listen: true, selector: selector) ??
              _throwNotFound<W>())
          .$2 as V;

  static (C, V?)? _find<W extends ScopeInheritedWidget,
      C extends ScopeModelContext<W, M>, M extends Object, V extends Object?>(
    BuildContext context, {
    required bool listen,
    V Function(C)? selector,
  }) {
    final element = context.getElementForInheritedWidgetOfExactType<W>();
    if (element == null) {
      return null;
    }

    final scopeContext = element is C
        ? element as C
        : throw Exception('The element of $W is not $C');

    if (!listen) {
      return (scopeContext, null);
    }

    V? value;
    if (selector == null) {
      context.dependOnInheritedElement(element);
    } else {
      value = selector(scopeContext);
      context.dependOnInheritedElement(element, aspect: (value, selector));
    }

    return (scopeContext, value);
  }

  static Never _throwNotFound<W extends InheritedWidget>() {
    throw Exception('$W not found in the context');
  }
}

abstract base class ScopeModelElementBase<
    W extends ScopeModelBottom<W, E, M>,
    E extends ScopeModelElementBase<W, E, M>,
    M extends Object> extends ScopeInheritedElement<W, M> {
  var _shouldNotify = false;
  var _updateChild = true;

  ScopeModelElementBase(W super.widget) {
    init();
  }

  @override
  void unmount() {
    dispose();
    super.unmount();
  }

  @override
  W get widget => super.widget as W;

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

  void notifyDependents({bool updateChild = true}) {
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

  @override
  Widget build() => buildBranch();
}

class _NullWidget extends Widget {
  const _NullWidget();

  @override
  Element createElement() => throw UnimplementedError();
}
