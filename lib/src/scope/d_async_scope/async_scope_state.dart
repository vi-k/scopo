part of '../scope.dart';

sealed class AsyncScopeState {
  AsyncScopeState();
}

final class AsyncScopeWaiting extends AsyncScopeState {
  AsyncScopeWaiting();
}

sealed class AsyncScopeInitState extends AsyncScopeState {
  AsyncScopeInitState();
}

final class AsyncScopeProgress extends AsyncScopeInitState {
  final Object? progress;

  AsyncScopeProgress([this.progress]);
}

final class AsyncScopeReady extends AsyncScopeInitState {
  AsyncScopeReady();
}

final class AsyncScopeError extends AsyncScopeState {
  final Object error;
  final StackTrace stackTrace;
  final Object? progress;

  AsyncScopeError(this.error, this.stackTrace, {this.progress});
}
