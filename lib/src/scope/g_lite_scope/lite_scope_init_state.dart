part of '../scope.dart';

/// Represents the initialization state of a [LiteScope].
///
/// This is a sealed class extended by state classes [LiteScopeWaiting],
/// [LiteScopeProgress] and [LiteScopeReady] to indicate the current phase of
/// initialization.
///
/// {@category LiteScope}
sealed class LiteScopeInitState {
  LiteScopeInitState();
}

/// Represents the wait state before initialization starts.
///
/// {@category LiteScope}
final class LiteScopeWaiting extends LiteScopeInitState {
  /// Creates a [LiteScopeWaiting] state.
  LiteScopeWaiting();
}

/// Represents the progress state during the initialization of a [LiteScope].
///
/// {@category LiteScope}
final class LiteScopeProgress extends LiteScopeInitState {
  /// Creates a [LiteScopeProgress] state.
  LiteScopeProgress();
}

/// Represents the ready state of a [LiteScope] when initialization is complete.
///
/// {@category LiteScope}
final class LiteScopeReady extends LiteScopeInitState {
  /// Creates a [LiteScopeReady] state.
  LiteScopeReady();
}
