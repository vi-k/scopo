part of '../scope_provider.dart';

typedef _ScopeDependency<T extends Object, V extends Object?> = (
  V,
  V Function(T),
);

abstract base class ScopeProviderBottom<
    W extends ScopeProviderBottom<W, E, T>,
    E extends ScopeProviderElementBase<W, E, T>,
    T extends Object> extends InheritedWidget {
  final T? value;
  final bool hasValue;
  final T Function(BuildContext context)? create;
  final void Function(T model)? dispose;
  final String Function()? debugString;
  final Widget Function(BuildContext context) builder;

  const ScopeProviderBottom({
    super.key,
    required T Function(BuildContext context) this.create,
    this.dispose,
    this.debugString,
    required this.builder,
  })  : value = null,
        hasValue = false,
        super(child: const _NullWidget());

  const ScopeProviderBottom.value({
    super.key,
    required T this.value,
    this.debugString,
    required this.builder,
  })  : hasValue = true,
        create = null,
        dispose = null,
        super(child: const _NullWidget());

  const ScopeProviderBottom.raw({
    super.key,
    this.debugString,
    required this.builder,
  })  : value = null,
        hasValue = false,
        create = null,
        dispose = null,
        super(child: const _NullWidget());

  @override
  E createElement();

  @override
  bool updateShouldNotify(ScopeProviderBottom<W, E, T> oldWidget) => true;

  static E? maybeGet<W extends ScopeProviderBottom<W, E, T>,
          E extends ScopeProviderElementBase<W, E, T>, T extends Object>(
    BuildContext context,
  ) =>
      context.getElementForInheritedWidgetOfExactType<W>() as E?;

  static E get<W extends ScopeProviderBottom<W, E, T>,
          E extends ScopeProviderElementBase<W, E, T>, T extends Object>(
    BuildContext context,
  ) =>
      maybeGet<W, E, T>(context) ?? _throwNotFound<W, E, T>();

  static E? maybeDepend<W extends ScopeProviderBottom<W, E, T>,
          E extends ScopeProviderElementBase<W, E, T>, T extends Object>(
    BuildContext context,
  ) =>
      _depend<W, E, T, void>(context)?.$1;

  static E depend<W extends ScopeProviderBottom<W, E, T>,
          E extends ScopeProviderElementBase<W, E, T>, T extends Object>(
    BuildContext context,
  ) =>
      maybeDepend<W, E, T>(context) ?? _throwNotFound<W, E, T>();

  static V? maybeSelect<
          W extends ScopeProviderBottom<W, E, T>,
          E extends ScopeProviderElementBase<W, E, T>,
          T extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(E) selector,
  ) =>
      _depend<W, E, T, V>(context, selector)?.$2;

  static V select<
          W extends ScopeProviderBottom<W, E, T>,
          E extends ScopeProviderElementBase<W, E, T>,
          T extends Object,
          V extends Object?>(
    BuildContext context,
    V Function(E) selector,
  ) =>
      maybeSelect<W, E, T, V>(context, selector) ?? _throwNotFound<W, E, T>();

  static (E, V?)? _depend<
      W extends ScopeProviderBottom<W, E, T>,
      E extends ScopeProviderElementBase<W, E, T>,
      T extends Object,
      V extends Object?>(
    BuildContext context, [
    V Function(E)? selector,
  ]) {
    final element = context.getElementForInheritedWidgetOfExactType<W>() as E?;
    if (element == null) {
      return null;
    }

    V? value;
    if (selector == null) {
      context.dependOnInheritedElement(element);
    } else {
      value = selector(element);
      context.dependOnInheritedElement(element, aspect: (value, selector));
    }

    return (element, value);
  }

  static Never _throwNotFound<W extends ScopeProviderBottom<W, E, T>,
      E extends ScopeProviderElementBase<W, E, T>, T extends Object>() {
    throw Exception('$W not found in the context');
  }

  @override
  String toStringShort() =>
      debugString?.call() ?? '${ScopeProviderBottom<W, E, T>}';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (hasValue) {
      properties.add(MessageProperty('value', '$value'));
    }
    if (create != null) {
      properties.add(MessageProperty('create', '$create'));
      properties.add(MessageProperty('dispose', '$dispose'));
    }
  }
}

base class ScopeProviderElementBase<W extends ScopeProviderBottom<W, E, T>,
        E extends ScopeProviderElementBase<W, E, T>, T extends Object>
    extends InheritedElement implements ScopeProviderFacade<W, T> {
  T? _model;

  ScopeProviderElementBase(W super.widget) {
    if (!widget.hasValue) {
      _model = createModel();
    }
  }

  @override
  W get widget => super.widget as W;

  @override
  T get model => _model ?? widget.value!;

  @override
  void unmount() {
    assert(widget.dispose == null || _model != null);
    if ((widget.dispose, _model) case (final dispose?, final model?)) {
      dispose(model);
    }
    super.unmount();
  }

  T createModel() {
    if (widget.create case final create?) {
      return create(this);
    }

    throw Exception(
        'In raw mode, you need to override the `createModel` method');
  }

  List<_ScopeDependency<E, Object?>> _createDependencies() => [];

  @override
  void updateDependencies(Element dependent, Object? aspect) {
    var dependencies =
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

    for (var (value, selector) in dependencies) {
      if (selector(this as E) != value) {
        setDependencies(dependent, null);
        dependent.didChangeDependencies();
        return;
      }
    }
  }

  @override
  Widget build() => widget.builder(this);

  /// [InheritedElement.notifyClients] does not support self-subscription,
  /// although this is required in our case.
  @override
  void notifyClients(W oldWidget) {
    for (final Element dependent in dependents.keys) {
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
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (_model != null) {
      properties.add(MessageProperty('model', '$_model'));
    }
  }
}

class _NullWidget extends StatelessWidget {
  const _NullWidget();

  @override
  Widget build(BuildContext context) => throw UnimplementedError();
}
