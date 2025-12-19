part of '../scope.dart';

final class ScopeOfContext<W extends ScopeV2<W, D, S>,
    D extends ScopeDependencies, S extends ScopeState<W, D, S>> {
  final W widget;
  final D dependencies;
  final S state;

  const ScopeOfContext._(this.widget, this.dependencies, this.state);
}

final class ScopeSelectContext<W extends ScopeV2<W, D, S>,
    D extends ScopeDependencies, S extends ScopeState<W, D, S>> {
  final W widget;
  final S state;

  const ScopeSelectContext._(this.widget, this.state);
}
