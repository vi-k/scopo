part of '../scope.dart';

abstract interface class AsyncDataScopeContext<W extends ScopeInheritedWidget,
    T extends Object?> implements AsyncScopeContext<W> {
  T get data;

  T? get dataOrNull;
}
