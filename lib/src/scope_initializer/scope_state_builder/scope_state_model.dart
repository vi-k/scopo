part of '../scope_initializer.dart';

abstract interface class ScopeStateModel<S extends Object>
    implements Listenable {
  S get state;
}

final class ScopeStateNotifier<S extends Object> extends ChangeNotifier
    implements ScopeStateModel<S> {
  S _state;

  ScopeStateNotifier(S initialState) : _state = initialState;

  @override
  S get state => _state;

  void update(S value) {
    if (!equals(_state, value)) {
      _state = value;
      notifyListeners();
    }
  }

  bool equals(S previous, S current) => false;

  ScopeStateUnmodifiableView<S> asUnmodifiable() =>
      ScopeStateUnmodifiableView(this);
}

final class ScopeStateUnmodifiableView<S extends Object>
    implements ScopeStateModel<S> {
  final ScopeStateNotifier<S> _notifier;

  ScopeStateUnmodifiableView(ScopeStateNotifier<S> notifier)
      : _notifier = notifier;

  @override
  S get state => _notifier.state;

  @override
  void addListener(VoidCallback listener) => _notifier.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _notifier.removeListener(listener);
}
