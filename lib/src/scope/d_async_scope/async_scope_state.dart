part of '../scope.dart';

sealed class AsyncScopeState<T extends Object?> {
  const AsyncScopeState();
}

final class AsyncScopeWaiting<T extends Object?> extends AsyncScopeState<T> {
  const AsyncScopeWaiting();
}

final class AsyncScopeProgress<T extends Object?> extends AsyncScopeState<T> {
  final Object? progress;

  const AsyncScopeProgress([this.progress]);
}

final class AsyncScopeReady<T extends Object?> extends AsyncScopeState<T> {
  final T data;

  const AsyncScopeReady(this.data);
}

final class AsyncScopeError<T extends Object?> extends AsyncScopeState<T> {
  final Object error;
  final StackTrace stackTrace;
  final Object? progress;

  const AsyncScopeError(this.error, this.stackTrace, {this.progress});
}
