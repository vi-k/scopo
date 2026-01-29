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
    super.child, // Not used by default. You can use it at your own discretion.
  });

  InheritedElement createScopeElement();

  @override
  InheritedElement createElement() => createScopeElement();

  @override
  bool updateShouldNotify(ScopeWidgetCore<W, E> oldWidget) => true;

  @override
  String toStringShort({bool showHashCode = false}) =>
      '$W${tag == null ? showHashCode //
          ? '(#${shortHash(this)})' : '' : '($tag)'}';

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
  /// Список зависимостей при подписке элемента на самого себя.
  ///
  /// [InheritedElement] не поддерживает подписку на самого себя (блокируется
  /// assert-ом в [notifyClients]). Обходим это ограничение через отдельное
  /// поле.
  List<_ScopeDependency<E, Object?>>? _selfDependencies;

  /// Флаг, показывающий, что во время перестроения ([performRebuild])
  /// необходимо только уведомить подписчиков, а не перестраивать поддерево.
  bool _shouldOnlyNotify = false;

  /// Флаг, показывающий, что элемент должен принудительно перестроиться,
  /// игнорируя флаг [_shouldOnlyNotify].
  bool _forceRebuild = true;

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

  bool get autoSelfDependence => false;

  @override
  void init() {}

  @override
  void dispose() {}

  List<_ScopeDependency<E, Object?>> _createDependencies() => [];

  List<_ScopeDependency<E, Object?>>? _updateDependencies(
    List<_ScopeDependency<E, Object?>>? dependencies,
    Object? aspect,
  ) {
    /// Уже подписались на все изменения.
    if (dependencies != null && dependencies.isEmpty) {
      return null;
    }

    if (aspect == null) {
      // Подписываемся на все изменения.
      return _createDependencies();
    }

    if (aspect case _ScopeDependency<E, Object?>()) {
      return (dependencies ?? _createDependencies())..add(aspect);
    }

    assert(false, '`aspect` must be ${_ScopeDependency<E, Object?>}');

    return null;
  }

  @override
  void updateDependencies(Element dependent, Object? aspect) {
    final newDependencies = _updateDependencies(
      getDependencies(dependent) as List<_ScopeDependency<E, Object?>>?,
      aspect,
    );
    if (newDependencies != null) {
      setDependencies(dependent, newDependencies);
    }
  }

  void _notifyDependent(
    W oldWidget,
    Element dependent,
    List<_ScopeDependency<E, Object?>>? dependencies,
  ) {
    if (dependencies == null) {
      return;
    }

    var dependenciesChanged = false;

    if (dependencies.isEmpty) {
      dependenciesChanged = true;
    } else {
      for (final (value, selector) in dependencies) {
        if (selector(this as E) != value) {
          dependenciesChanged = true;
          break;
        }
      }
    }

    if (dependenciesChanged) {
      if (identical(dependent, this)) {
        _selfDependencies = null;
        _forceRebuild = true;
      } else {
        setDependencies(dependent, null);
      }
      dependent.didChangeDependencies();
    }
  }

  @override
  void notifyDependent(W oldWidget, Element dependent) {
    _notifyDependent(
      oldWidget,
      dependent,
      getDependencies(dependent) as List<_ScopeDependency<E, Object?>>?,
    );
  }

  @override
  InheritedWidget dependOnInheritedElement(
    InheritedElement ancestor, {
    Object? aspect,
  }) {
    if (identical(this, ancestor)) {
      _selfDependencies = _updateDependencies(_selfDependencies, aspect);
      return widget;
    }

    return super.dependOnInheritedElement(ancestor, aspect: aspect);
  }

  /// [InheritedElement.notifyClients] does not support self-subscription,
  /// although this is required in our case.
  @override
  void notifyClients(W oldWidget) {
    if (_selfDependencies case final dependencies?) {
      _notifyDependent(oldWidget, this, dependencies);
    }

    super.notifyClients(oldWidget);
  }

  /// Уведомляет подписчиков об изменениях.
  ///
  /// Уведомление работает через метод [didChangeDependencies], который может
  /// быть запущен только во время построения кадра. Поэтому единственным
  /// вариантом остаётся принудительное обновление дерева и уведомление
  /// подписчиков из [performRebuild].
  @protected
  void notifyDependents() {
    _shouldOnlyNotify = true;
    markNeedsBuild();
  }

  /// Если мы находимся в режиме только уведомления ([notifyDependents]), но
  /// элемент параллельно обновляется сверху родителем, то принудительно
  /// перестраиваем поддерево.
  @override
  void update(covariant ProxyWidget newWidget) {
    _forceRebuild = true;
    super.update(newWidget);
  }

  /// Суть этого кода в том, чтобы не обновлять всё дерево (не запускать
  /// [build]), если нужно только уведомить подписчиков об изменениях
  /// ([notifyDependents]).
  ///
  /// Обновление принудительно срабатывает в случаях:
  /// 1. [autoSelfDependence] - элемент объявил об автоматической подписке на
  ///    изменения самого себя (используется в инициализаторах на этапах
  ///    инициализации).
  /// 2. [_forceRebuild] - принудительное перестроение поддерева, если
  ///    элемент обновляется родителем или элемент подписался на самого
  ///    себя.
  @override
  void performRebuild() {
    if (_shouldOnlyNotify) {
      notifyClients(widget);
      _shouldOnlyNotify = !autoSelfDependence && !_forceRebuild;
    }
    super.performRebuild();
    _forceRebuild = false;
    _shouldOnlyNotify = false;
  }

  @override
  Element? updateChild(Element? child, Widget? newWidget, Object? newSlot) =>
      _shouldOnlyNotify ? child : super.updateChild(child, newWidget, newSlot);

  @nonVirtual
  @override
  Widget build() => buildChild();

  String _buildMessage(String? method, Object? message) {
    final text = ScopeLog.objToString(message);
    return '${method == null ? '' : '[$method] '}${text ?? ''}';
  }

  void _d(String? method, [Object? message]) {
    assert(method != null || message != null);
    d(
      () => widget.toStringShort(showHashCode: true),
      () => _buildMessage(method, message),
    );
  }

  void _i(String? method, [Object? message]) {
    assert(method != null || message != null);
    i(
      () => widget.toStringShort(showHashCode: true),
      () => _buildMessage(method, message),
    );
  }

  void _e(
    String? method,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    assert(method != null || message != null);
    e(
      () => widget.toStringShort(showHashCode: true),
      () => _buildMessage(method, message),
      error: error,
      stackTrace: stackTrace,
    );
  }
}
