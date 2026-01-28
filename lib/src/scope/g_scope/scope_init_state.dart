part of '../scope.dart';

sealed class ScopeInitState<P extends Object, D extends ScopeDependencies> {
  ScopeInitState();
}

final class ScopeProgress<P extends Object, D extends ScopeDependencies>
    extends ScopeInitState<P, D> {
  final P? progress;

  ScopeProgress([this.progress]);
}

final class ScopeReady<P extends Object, D extends ScopeDependencies>
    extends ScopeInitState<P, D> {
  final D dependencies;

  ScopeReady(this.dependencies);
}
