part of '../scope_provider.dart';

base mixin _ScopeInheritedWidgetBaseMixin<M extends Object>
    on ScopeInheritedWidget {
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

base mixin _ScopeInheritedElementMixin<
    W extends _ScopeInheritedWidgetBaseMixin<M>,
    M extends Object> on ScopeInheritedElement<W, M> {
  M? _model;

  @override
  M get model => _model ?? widget.value!;

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
  Widget buildBranch() => widget.build(this);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (_model != null) {
      properties.add(MessageProperty('model', '$_model'));
    }
  }
}

base mixin _ScopeInheritedWidgetMixin<M extends Object>
    on _ScopeInheritedWidgetBaseMixin<M> {
  Widget Function(BuildContext context) get builder;
  String? get debugName;

  @override
  Widget build(BuildContext context) => builder(context);

  @override
  String toStringShort() => debugName ?? super.toStringShort();
}
