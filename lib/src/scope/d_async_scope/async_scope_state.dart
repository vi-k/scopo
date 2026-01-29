part of '../scope.dart';

sealed class AsyncScopeState {
  AsyncScopeState();
}

final class AsyncScopeWaiting extends AsyncScopeState {
  AsyncScopeWaiting();

  @override
  String toString() => '$AsyncScopeWaiting';
}

sealed class AsyncScopeInitState extends AsyncScopeState {
  AsyncScopeInitState();

  @override
  String toString() => '$AsyncScopeInitState';
}

final class AsyncScopeProgress extends AsyncScopeInitState {
  final Object? progress;

  AsyncScopeProgress([this.progress]);

  @override
  String toString() =>
      '$AsyncScopeProgress${progress == null ? '' : '($progress)'}';
}

final class AsyncScopeReady extends AsyncScopeInitState {
  AsyncScopeReady();

  @override
  String toString() => '$AsyncScopeReady';
}

final class AsyncScopeError extends AsyncScopeState {
  final Object error;
  final StackTrace stackTrace;
  final Object? progress;

  AsyncScopeError(this.error, this.stackTrace, {this.progress});

  @override
  String toString() => '$AsyncScopeError($error, $stackTrace'
      '${progress == null ? '' : ', progress: $progress)'})';
}
