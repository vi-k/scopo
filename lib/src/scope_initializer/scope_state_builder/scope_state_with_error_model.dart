part of '../scope_initializer.dart';

abstract interface class ScopeStateWithErrorModel<S extends Object>
    implements ScopeStateModel<S> {
  @override
  S get state;

  (Object, StackTrace)? get error;
}

final class ScopeStateWithErrorNotifier<S extends Object>
    extends ScopeStateNotifier<S> implements ScopeStateWithErrorModel<S> {
  (Object, StackTrace)? _error;

  ScopeStateWithErrorNotifier(super.initialState);

  @override
  (Object, StackTrace)? get error => _error;

  bool get isError => _error != null;

  @override
  S get state => switch (_error) {
        null => super.state,
        (final Object error, final StackTrace stackTrace) =>
          Error.throwWithStackTrace(error, stackTrace),
      };

  void setError(Object error, StackTrace stackTrace) {
    _error = (error, stackTrace);
    notifyListeners();
  }
}
