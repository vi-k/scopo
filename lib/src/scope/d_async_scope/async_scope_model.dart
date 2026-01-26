part of '../scope.dart';

abstract interface class AsyncScopeModel<T extends Object?>
    implements ScopeStateModel<AsyncScopeState<T>> {}

final class _AsyncScopeNotifier<T extends Object?>
    extends ScopeStateNotifier<AsyncScopeState<T>>
    implements AsyncScopeModel<T> {
  _AsyncScopeNotifier() : super(const AsyncScopeWaiting());

  @override
  _AsyncScopeModelView<T> asUnmodifiable() => _AsyncScopeModelView(this);
}

final class _AsyncScopeModelView<T extends Object?>
    extends ScopeStateModelView<AsyncScopeState<T>>
    implements AsyncScopeModel<T> {
  _AsyncScopeModelView(_AsyncScopeNotifier<T> super.notifier);
}
