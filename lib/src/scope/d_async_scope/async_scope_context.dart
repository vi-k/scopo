part of '../scope.dart';

abstract interface class AsyncScopeContext<W extends ScopeInheritedWidget,
    T extends Object?> implements ScopeContext<W> {
  @override
  W get widget;

  AsyncScopeState<T> get state;

  bool get isInitialized;

  T get data;

  T? get dataOrNull;

  bool get hasError;

  Object get error;

  StackTrace get stackTrace;
}
