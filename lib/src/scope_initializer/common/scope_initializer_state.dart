part of '../scope_initializer.dart';

sealed class ScopeInitializerState<T extends Object?> {
  const ScopeInitializerState();
}

final class ScopeInitializerWaitingForPrevious<T extends Object?>
    extends ScopeInitializerState<T> {
  const ScopeInitializerWaitingForPrevious();
}

/// Public name.
sealed class ScopeProcessState<T extends Object?>
    extends ScopeInitializerState<T> {
  const ScopeProcessState();
}

final class ScopeProgressV2<T extends Object?> extends ScopeProcessState<T> {
  final Object? progress;

  const ScopeProgressV2([this.progress]);
}

final class ScopeReadyV2<T extends Object?> extends ScopeProcessState<T> {
  final T value;

  const ScopeReadyV2(this.value);
}

final class ScopeInitializerError<T extends Object?>
    extends ScopeInitializerState<T> {
  final Object error;
  final StackTrace stackTrace;

  const ScopeInitializerError(this.error, this.stackTrace);
}
