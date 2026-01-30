part of '../scope.dart';

/// {@category Scope}
sealed class ScopeInitState<P extends Object, D extends ScopeDependencies> {
  ScopeInitState();
}

/// {@category Scope}
final class ScopeProgress<P extends Object, D extends ScopeDependencies>
    extends ScopeInitState<P, D> {
  final P? progress;

  ScopeProgress([this.progress]);
}

/// {@category Scope}
final class ScopeReady<P extends Object, D extends ScopeDependencies>
    extends ScopeInitState<P, D> {
  final D dependencies;

  ScopeReady(this.dependencies);
}
