import 'package:flutter/foundation.dart';

import 'model.dart';

final class ListenableModel with ChangeNotifier implements Model {
  var _a = 0;
  var _b = 0;

  ListenableModel();

  @override
  int get a => _a;

  @override
  int get b => _b;

  @override
  void incrementA() {
    _a++;
    notifyListeners();
  }

  @override
  void incrementB() {
    _b++;
    notifyListeners();
  }

  @override
  int get hashCode => Object.hash(_a, _b);

  @override
  operator ==(Object other) =>
      identical(this, other) ||
      other is ListenableModel && other._a == _a && other._b == _b;
}
