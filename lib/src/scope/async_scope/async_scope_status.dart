part of '../scope.dart';

/// {@category AsyncScope}
sealed class AsyncScopeStatus {
  AsyncScopeStatus();
}

/// {@category AsyncScope}
final class AsyncScopeWaiting extends AsyncScopeStatus {
  /// Creates the waiting status.
  AsyncScopeWaiting();

  @override
  String toString() => '$AsyncScopeWaiting';
}

/// {@category AsyncScope}
final class AsyncScopeProgress extends AsyncScopeStatus {
  /// Whatever the initialization reported — a caption, a fraction, a step.
  final Object? progress;

  /// Reports that the initialization has advanced.
  AsyncScopeProgress([this.progress]);

  @override
  String toString() =>
      '$AsyncScopeProgress${progress == null ? '' : '($progress)'}';
}

/// {@category AsyncScope}
final class AsyncScopeReady extends AsyncScopeStatus {
  /// Reports that the initialization is over.
  AsyncScopeReady();

  @override
  String toString() => '$AsyncScopeReady';
}

/// {@category AsyncScope}
final class AsyncScopeFailed extends AsyncScopeStatus {
  /// What the initialization failed with.
  final Object error;

  /// The stack trace of [error].
  final StackTrace stackTrace;

  /// The last progress reported before the failure.
  final Object? progress;

  /// Creates the failed status.
  AsyncScopeFailed(this.error, this.stackTrace, {this.progress});

  @override
  String toString() =>
      '$AsyncScopeFailed($error, $stackTrace'
      '${progress == null ? '' : ', progress: $progress'})';
}
