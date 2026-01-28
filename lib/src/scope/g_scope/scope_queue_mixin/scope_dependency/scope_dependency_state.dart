part of '../../../scope.dart';

sealed class _ScopeDependencyState {
  const _ScopeDependencyState();

  String get description;
}

sealed class _ScopeDependencySuccessStates extends _ScopeDependencyState {
  const _ScopeDependencySuccessStates();
}

sealed class _ScopeDependencyFailedStates extends _ScopeDependencyState {
  final Object error;
  final StackTrace stackTrace;

  const _ScopeDependencyFailedStates(this.error, this.stackTrace);
}

final class _ScopeDependencyStateInitial extends _ScopeDependencySuccessStates {
  const _ScopeDependencyStateInitial();

  @override
  String get description => 'not initialized';
}

final class _ScopeDependencyStateInitializationFailed
    extends _ScopeDependencyFailedStates {
  const _ScopeDependencyStateInitializationFailed(
    super.error,
    super.stackTrace,
  );

  @override
  String get description => 'initialization failed';
}

final class _ScopeDependencyStateInitialized
    extends _ScopeDependencySuccessStates {
  const _ScopeDependencyStateInitialized();

  @override
  String get description => 'initialized';
}

final class _ScopeDependencyStateDisposed
    extends _ScopeDependencySuccessStates {
  const _ScopeDependencyStateDisposed();

  @override
  String get description => 'disposed';
}

final class _ScopeDependencyStateDisposalFailed
    extends _ScopeDependencyFailedStates {
  const _ScopeDependencyStateDisposalFailed(
    super.error,
    super.stackTrace,
  );

  @override
  String get description => 'disposal failed';
}
