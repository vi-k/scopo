import 'package:flutter/foundation.dart';

final class ListenableView implements Listenable {
  final Listenable _listenable;

  ListenableView(Listenable listenable) : _listenable = listenable;

  @override
  void addListener(VoidCallback listener) => _listenable.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _listenable.removeListener(listener);
}
