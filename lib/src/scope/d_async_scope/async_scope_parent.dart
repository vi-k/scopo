part of '../scope.dart';

final class ScopeChildEntry {
  final String _debugName;
  AsyncScopeParent? _parent;
  final _completer = Completer<void>();

  ScopeChildEntry(this._debugName, this._parent);

  void unregister() {
    assert(_parent != null);
    assert(!_completer.isCompleted);

    _completer.complete();
    _parent?._children.remove(this);
    _parent = null;
  }

  @override
  String toString() => '$_debugName'
      ' ${_completer.isCompleted ? 'completed' : 'not completed'}';
}

mixin AsyncScopeParent on Diagnosticable {
  final _children = <ScopeChildEntry>[];

  bool get hasChildren => _children.isNotEmpty;

  int get childrenCount => _children.length;

  Future<void> waitForChildren() =>
      _children.map((e) => e._completer.future).wait;

  ScopeChildEntry registerChild(String debugName) {
    final entry = ScopeChildEntry(debugName, this);
    _children.add(entry);
    return entry;
  }
}
