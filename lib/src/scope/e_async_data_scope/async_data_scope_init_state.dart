part of '../scope.dart';

sealed class AsyncDataScopeInitState<P extends Object, T extends Object?> {
  AsyncDataScopeInitState();
}

final class AsyncDataScopeProgress<P extends Object, T extends Object?>
    extends AsyncDataScopeInitState<P, T> {
  final P? progress;

  AsyncDataScopeProgress([this.progress]);
}

final class AsyncDataScopeReady<P extends Object, T extends Object?>
    extends AsyncDataScopeInitState<P, T> {
  final T data;

  AsyncDataScopeReady(this.data);
}
