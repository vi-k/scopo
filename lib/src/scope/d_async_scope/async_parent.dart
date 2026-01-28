part of '../scope.dart';

final class AsyncParentEntry {
  AsyncParent? _parent;

  final completer = Completer<void>();

  AsyncParentEntry(this._parent);

  void unregister() {
    assert(_parent != null);
    assert(!completer.isCompleted);

    completer.complete();
    _parent?._children.remove(completer.future);
    _parent = null;
  }
}

mixin AsyncParent {
  final _children = <Future<void>>[];

  bool get hasChildren => _children.isNotEmpty;

  int get childrenCount => _children.length;

  Future<void> get waitForChildren => _children.wait;

  AsyncParentEntry registerChild() {
    final entry = AsyncParentEntry(this);
    _children.add(entry.completer.future);
    return entry;
  }
}
