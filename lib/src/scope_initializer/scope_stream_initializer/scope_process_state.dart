part of '../scope_initializer.dart';

sealed class ScopeProcessState<P extends Object?, T extends Object?> {
  ScopeProcessState();

  ScopeInitializerState<T> toScopeInitializerState();
}

final class ScopeProgressV2<P extends Object?, T extends Object?>
    extends ScopeProcessState<P, T> {
  final P progress;

  ScopeProgressV2(this.progress);

  @override
  ScopeInitializerProgress<T> toScopeInitializerState() =>
      ScopeInitializerProgress(progress);
}

final class ScopeReadyV2<P extends Object?, T extends Object?>
    extends ScopeProcessState<P, T> {
  final T value;

  ScopeReadyV2(this.value);

  @override
  ScopeInitializerReady<T> toScopeInitializerState() =>
      ScopeInitializerReady(value);
}
