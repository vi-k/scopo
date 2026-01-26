part of '../../scope.dart';

sealed class ScopeInitState<P extends Object?, T extends Object?> {
  ScopeInitState();

  AsyncScopeState<T> toScopeInitializerState();
}

final class ScopeProgress<P extends Object?, T extends Object?>
    extends ScopeInitState<P, T> {
  final P progress;

  ScopeProgress(this.progress);

  @override
  AsyncScopeProgress<T> toScopeInitializerState() =>
      AsyncScopeProgress(progress);

  @override
  String toString() => '${typeToShortString(ScopeProgress)}($progress)';
}

final class ScopeReady<P extends Object?, T extends Object?>
    extends ScopeInitState<P, T> {
  final T data;

  ScopeReady(this.data);

  @override
  AsyncScopeReady<T> toScopeInitializerState() => AsyncScopeReady(data);

  @override
  String toString() => '${typeToShortString(ScopeReady)}($data)';
}
