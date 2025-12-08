import 'package:flutter/foundation.dart';

abstract interface class ScopeStateManagerModel<S extends Object?> {
  S get state;
}

final class ScopeStateManagerNotifier<S extends Object?> extends ChangeNotifier
    implements ScopeStateManagerModel<S> {
  S _state;

  ScopeStateManagerNotifier(S initialState) : _state = initialState;

  @override
  S get state => _state;

  void setState(S value) {
    _state = value;
    notifyListeners();
  }

  @override
  String toString() => '${ScopeStateManagerNotifier<S>}';
}
