part of '../scope.dart';

sealed class ScopeInitState<P extends Object?, T extends Object?> {
  ScopeInitState();

  ScopeInitializerState<T> toScopeInitializerState();
}

final class ScopeProgress<P extends Object?, T extends Object?>
    extends ScopeInitState<P, T> {
  final P progress;

  ScopeProgress(this.progress);

  @override
  ScopeInitializerProgress<T> toScopeInitializerState() =>
      ScopeInitializerProgress(progress);
}

final class ScopeReady<P extends Object?, T extends Object?>
    extends ScopeInitState<P, T> {
  final T value;

  ScopeReady(this.value);

  @override
  ScopeInitializerReady<T> toScopeInitializerState() =>
      ScopeInitializerReady(value);
}
