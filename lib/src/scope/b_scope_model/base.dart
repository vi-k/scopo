part of '../scope.dart';

abstract interface class ScopeModelContext<W extends ScopeInheritedWidget,
    M extends Object> implements ScopeContext<W> {
  @override
  W get widget;

  M get model;
}

abstract interface class ScopeModelInheritedElement<
        W extends ScopeInheritedWidget, M extends Object>
    implements ScopeInheritedElement<W>, ScopeModelContext<W, M> {
  @override
  W get widget;

  @override
  M get model;

  @override
  void init();

  @override
  void dispose();

  @override
  Widget buildChild();
}

base mixin ScopeModelBaseMixin<M extends Object> on ScopeInheritedWidget {
  M? get value;
  bool get hasValue;
  M Function(BuildContext context)? get create;
  void Function(M model)? get dispose;

  Widget build(BuildContext context);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (hasValue) {
      properties.add(MessageProperty('value', '$value'));
    }
    if (create != null) {
      properties
        ..add(MessageProperty('create', '$create'))
        ..add(MessageProperty('dispose', '$dispose'));
    }
  }
}

base mixin ScopeModelMixin<M extends Object> on ScopeModelBaseMixin<M> {
  Widget Function(BuildContext context) get builder;
  String? get debugName;

  @override
  Widget build(BuildContext context) => builder(context);

  @override
  String toStringShort() => debugName ?? super.toStringShort();
}

base mixin ScopeModelElementMixin<W extends ScopeModelBaseMixin<M>,
    M extends Object> on InheritedElement, ScopeInheritedElement<W> {
  M? _model;

  M get model => _model ?? widget.value!;

  bool get autoSelfDependence => false;

  @override
  void init() {
    if (!widget.hasValue) {
      assert(widget.create != null);
      _model = widget.create!(this);
    }
    super.init();
  }

  @override
  void dispose() {
    super.dispose();
    assert(widget.dispose == null || _model != null);
    if ((widget.dispose, _model) case (final dispose?, final model?)) {
      dispose(model);
    }
  }

  @override
  Widget buildChild() => widget.build(this);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (_model != null) {
      properties.add(MessageProperty('model', '$_model'));
    }
  }
}
