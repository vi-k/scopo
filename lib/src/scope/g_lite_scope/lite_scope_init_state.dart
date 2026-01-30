/// {@category LiteScope}
sealed class LiteScopeInitState {
  LiteScopeInitState();
}

/// {@category LiteScope}
final class LiteScopeWaiting extends LiteScopeInitState {
  LiteScopeWaiting();
}

/// {@category LiteScope}
final class LiteScopeProgress extends LiteScopeInitState {
  LiteScopeProgress();
}

/// {@category LiteScope}
final class LiteScopeReady extends LiteScopeInitState {
  LiteScopeReady();
}
