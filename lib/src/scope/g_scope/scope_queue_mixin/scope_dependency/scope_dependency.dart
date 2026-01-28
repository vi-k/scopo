part of '../../../scope.dart';

final class ScopeDependency extends ScopeDependencyBase {
  @override
  final String name;

  final FutureOr<void> Function() onInit;
  final FutureOr<void> Function()? onDispose;

  ScopeDependency(
    this.name,
    this.onInit, {
    this.onDispose,
  });

  @override
  FutureOr<void> init() => onInit();

  @override
  FutureOr<void> dispose() => onDispose?.call();
}
