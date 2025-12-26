part of '../scope.dart';

abstract interface class ScopeInitializerModel<T extends Object?>
    implements ScopeStateModel<ScopeInitializerState<T>> {}

final class _ScopeInitializerNotifier<T extends Object?>
    extends ScopeStateNotifier<ScopeInitializerState<T>>
    implements ScopeInitializerModel<T> {
  _ScopeInitializerNotifier()
      : super(const ScopeInitializerWaitingForPrevious());

  @override
  _ScopeInitializerModelView<T> asUnmodifiable() =>
      _ScopeInitializerModelView(this);
}

final class _ScopeInitializerModelView<T extends Object?>
    extends UnmodifiableScopeStateModel<ScopeInitializerState<T>>
    implements ScopeInitializerModel<T> {
  _ScopeInitializerModelView(_ScopeInitializerNotifier<T> super.notifier);
}
