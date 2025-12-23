part of '../scope.dart';

abstract base class ScopeInheritedElement<W extends ScopeInheritedWidget,
        M extends Object> extends InheritedElement
    implements ScopeModelContext<W, M> {
  ScopeInheritedElement(super.widget);

  @mustCallSuper
  void init();

  @mustCallSuper
  void dispose();

  Widget buildBranch();
}

base mixin ScopeInheritedElementMixin<W extends ScopeModelBaseMixin<M>,
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
