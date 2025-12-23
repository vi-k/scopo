part of '../scope.dart';

abstract interface class ScopeModelContext<W extends ScopeInheritedWidget,
    M extends Object> implements BuildContext {
  @override
  W get widget;

  M get model;
}
