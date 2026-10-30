part of '../scope.dart';

/// The state of an asynchronous scope, written by the scope alone.
///
/// The element hands out [ScopeStateNotifier.asUnmodifiable], a read-only view
/// of this notifier, as `AsyncScopeElementBase.model`.
final class _AsyncScopeNotifier extends ScopeStateNotifier<AsyncScopeState> {
  _AsyncScopeNotifier() : super(AsyncScopeWaiting());
}
