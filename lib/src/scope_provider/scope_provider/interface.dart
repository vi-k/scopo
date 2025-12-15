// ignore_for_file: avoid_implementing_value_types

part of '../scope_provider.dart';

abstract interface class ScopeInheritedWidget implements InheritedWidget {}

abstract interface class ScopeContext<W extends ScopeInheritedWidget, M>
    implements BuildContext {
  @override
  W get widget;

  M get model;
}

abstract interface class ScopeInheritedElement<W extends ScopeInheritedWidget,
    M extends Object> implements ScopeContext<W, M>, InheritedElement {
  @mustCallSuper
  void init();

  @mustCallSuper
  void dispose();

  Widget buildBranch();
}
