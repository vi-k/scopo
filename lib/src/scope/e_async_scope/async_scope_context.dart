part of '../scope.dart';

/// {@category AsyncScope}
abstract interface class AsyncScopeContext<W extends ScopeInheritedWidget>
    implements ScopeContext<W> {
  AsyncScopeState get state;

  bool get isInitialized;

  bool get hasError;

  Object get error;

  StackTrace get stackTrace;
}
