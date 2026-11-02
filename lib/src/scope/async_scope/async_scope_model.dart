part of '../scope.dart';

/// The state of an asynchronous scope, written by the scope alone.
///
/// The element hands out [_AsyncScopeModelView], a read-only view of this
/// notifier, as `AsyncScopeElementBase.model`.
final class _AsyncScopeNotifier extends ScopeStateNotifier<AsyncScopeState> {
  _AsyncScopeNotifier() : super(AsyncScopeWaiting());
}

/// A view of [_AsyncScopeNotifier] that can be read and listened to, not set.
///
/// The notifier itself, handed out as a [ScopeStateModel], would be one
/// downcast away from its `update`.
final class _AsyncScopeModelView implements ScopeStateModel<AsyncScopeState> {
  final _AsyncScopeNotifier _notifier;

  _AsyncScopeModelView(this._notifier);

  @override
  AsyncScopeState get state => _notifier.state;

  @override
  void addListener(VoidCallback listener) => _notifier.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _notifier.removeListener(listener);
}
