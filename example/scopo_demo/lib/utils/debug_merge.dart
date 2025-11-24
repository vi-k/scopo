import 'package:flutter/material.dart';

class DebugMerge extends ProxyWidget {
  const DebugMerge({super.key, required super.child});

  @override
  Element createElement() => DebugElement(this);
}

class DebugElement extends ProxyElement {
  DebugElement(super.widget);

  @override
  void notifyClients(covariant ProxyWidget oldWidget) {}
}
