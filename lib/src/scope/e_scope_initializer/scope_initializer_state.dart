part of '../scope.dart';

sealed class ScopeInitializerState<T extends Object?> {
  const ScopeInitializerState();
}

final class ScopeInitializerWaitingForPrevious<T extends Object?>
    extends ScopeInitializerState<T> {
  const ScopeInitializerWaitingForPrevious();
}

final class ScopeInitializerProgress<T extends Object?>
    extends ScopeInitializerState<T> {
  final Object? progress;

  const ScopeInitializerProgress([this.progress]);
}

final class ScopeInitializerReady<T extends Object?>
    extends ScopeInitializerState<T> {
  final T value;

  const ScopeInitializerReady(this.value);
}

final class ScopeInitializerError<T extends Object?>
    extends ScopeInitializerState<T> {
  final Object error;
  final StackTrace stackTrace;
  final Object? progress;

  const ScopeInitializerError(this.error, this.stackTrace, {this.progress});
}
