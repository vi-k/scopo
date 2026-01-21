sealed class AsyncInitializerState {
  const AsyncInitializerState();
}

sealed class AsyncInitializerInitializedStates extends AsyncInitializerState {
  const AsyncInitializerInitializedStates();
}

sealed class AsyncInitializerSuccessStates extends AsyncInitializerState {
  const AsyncInitializerSuccessStates();
}

sealed class AsyncInitializerFailedStates extends AsyncInitializerState {
  final Object error;
  final StackTrace stackTrace;

  const AsyncInitializerFailedStates(this.error, this.stackTrace);
}

final class AsyncInitializerInitial extends AsyncInitializerSuccessStates {
  const AsyncInitializerInitial();
}

final class AsyncInitializerWaitingForInitialization
    extends AsyncInitializerSuccessStates {
  const AsyncInitializerWaitingForInitialization();
}

final class AsyncInitializerInitializing extends AsyncInitializerSuccessStates {
  const AsyncInitializerInitializing();
}

final class AsyncInitializerInitializationFailed
    extends AsyncInitializerFailedStates {
  const AsyncInitializerInitializationFailed(super.error, super.stackTrace);
}

final class AsyncInitializerInitialized extends AsyncInitializerSuccessStates
    implements AsyncInitializerInitializedStates {
  const AsyncInitializerInitialized();
}

final class AsyncInitializerWaitingForDisposal
    extends AsyncInitializerSuccessStates {
  const AsyncInitializerWaitingForDisposal();
}

final class AsyncInitializerDisposing extends AsyncInitializerSuccessStates
    implements AsyncInitializerInitializedStates {
  const AsyncInitializerDisposing();
}

final class AsyncInitializerDisposalFailed extends AsyncInitializerFailedStates
    implements AsyncInitializerInitializedStates {
  const AsyncInitializerDisposalFailed(super.error, super.stackTrace);
}

final class AsyncInitializerDisposed extends AsyncInitializerSuccessStates
    implements AsyncInitializerInitializedStates {
  const AsyncInitializerDisposed();
}
