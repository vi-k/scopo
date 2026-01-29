part of '../scope.dart';

final class AsyncScopeParentEntry {
  AsyncScopeParent? _parent;

  final completer = Completer<void>();

  AsyncScopeParentEntry(this._parent);

  void unregister() {
    assert(_parent != null);
    assert(!completer.isCompleted);

    completer.complete();
    _parent?._children.remove(completer.future);
    _parent = null;
  }
}

mixin AsyncScopeParent {
  final _children = <Future<void>>[];

  bool get hasChildren => _children.isNotEmpty;

  int get childrenCount => _children.length;

  Future<void> waitForChildren() => _children.wait;

  AsyncScopeParentEntry registerChild() {
    final entry = AsyncScopeParentEntry(this);
    _children.add(entry.completer.future);
    return entry;
  }
}
