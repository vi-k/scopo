sealed class LiteScopeInitState {
  LiteScopeInitState();
}

final class LiteScopeWaiting extends LiteScopeInitState {
  LiteScopeWaiting();
}

final class LiteScopeProgress extends LiteScopeInitState {
  LiteScopeProgress();
}

final class LiteScopeReady extends LiteScopeInitState {
  LiteScopeReady();
}
