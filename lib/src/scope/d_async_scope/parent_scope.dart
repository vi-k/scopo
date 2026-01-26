part of '../scope.dart';

// ignore: one_member_abstracts
abstract interface class ParentScope {
  bool get hasChildren;

  int get childrenCount;

  void registerChild(Future<void> lifecycleFuture);

  Future<void> get waitForChildren;
}

mixin ParentScopeMixin implements ParentScope {
  final _children = <Future<void>>[];

  @override
  bool get hasChildren => _children.isNotEmpty;

  @override
  int get childrenCount => _children.length;

  @override
  void registerChild(Future<void> lifecycleFuture) {
    _children.add(lifecycleFuture);
  }

  @override
  Future<void> get waitForChildren => _children.wait;
}
