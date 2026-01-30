part of '../scope.dart';

/// {@category AsyncDataScope}
sealed class AsyncDataScopeInitState<P extends Object, T extends Object?> {
  AsyncDataScopeInitState();
}

/// {@category AsyncDataScope}
final class AsyncDataScopeProgress<P extends Object, T extends Object?>
    extends AsyncDataScopeInitState<P, T> {
  final P? progress;

  AsyncDataScopeProgress([this.progress]);
}

/// {@category AsyncDataScope}
final class AsyncDataScopeReady<P extends Object, T extends Object?>
    extends AsyncDataScopeInitState<P, T> {
  final T data;

  AsyncDataScopeReady(this.data);
}
