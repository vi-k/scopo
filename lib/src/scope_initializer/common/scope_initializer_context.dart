part of '../scope_initializer.dart';

abstract interface class ScopeInitializerContext<W extends ScopeInheritedWidget,
        T extends Object?>
    implements ScopeModelContext<W, ScopeStateModel<ScopeInitializerState<T>>> {
  @override
  W get widget;

  @override
  ScopeStateModel<ScopeInitializerState<T>> get model;

  bool get isInitialized;

  T get value;

  T? get valueOrNull;

  bool get isError;

  Object get error;

  StackTrace get stackTrace;
}
