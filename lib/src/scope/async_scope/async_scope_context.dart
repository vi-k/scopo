part of '../scope.dart';

/// {@category AsyncScope}
abstract interface class AsyncScopeContext<W extends ScopeInheritedWidget>
    implements ScopeInheritedContext<W> {
  /// Closes this scope and waits for its resources to be released.
  ///
  /// The closing branch replaces the subtree before the release begins, so
  /// descendants finish their disposal while their resources are still usable.
  /// The scope stays mounted in that branch after closing; its `scopeKey` is
  /// released before this future completes, without waiting for tree removal.
  ///
  /// Repeated calls join the same teardown and receive the same outcome,
  /// including the first disposal failure and its stack trace.
  Future<void> close();

  /// Where in its lifecycle the scope is.
  AsyncScopeStatus get status;

  /// Whether the scope has reached [AsyncScopeReady].
  bool get isReady;

  /// Whether the initialization failed.
  bool get hasError;

  /// The error of a failed initialization.
  ///
  /// Throws a [StateError] when there is none.
  Object get error;

  /// The stack trace of [error].
  ///
  /// Throws a [StateError] when there is no error.
  StackTrace get stackTrace;
}
