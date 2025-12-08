part of 'scope_fork.dart';

sealed class _ScopeForkState<S extends Object> {
  const _ScopeForkState();
}

final class _ScopeForkError<S extends Object> extends _ScopeForkState<S> {
  final Object error;
  final StackTrace stackTrace;

  _ScopeForkError(this.error, this.stackTrace);

  @override
  String toString() => '${_ScopeForkError<S>}($error)';
}

final class _ScopeForkSuccess<S extends Object> extends _ScopeForkState<S> {
  final S state;

  const _ScopeForkSuccess(this.state);

  @override
  String toString() => '${_ScopeForkSuccess<S>}($state)';
}
