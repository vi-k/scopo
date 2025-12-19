part of '../scope_model.dart';

abstract base class ScopeInheritedWidget extends InheritedWidget {
  const ScopeInheritedWidget({
    super.key,
    required super.child,
  });
}

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

base mixin _ScopeInheritedWidgetMixin<M extends Object>
    on _ScopeInheritedWidgetBaseMixin<M> {
  Widget Function(BuildContext context) get builder;
  String? get debugName;

  @override
  Widget build(BuildContext context) => builder(context);

  @override
  String toStringShort() => debugName ?? super.toStringShort();
}
