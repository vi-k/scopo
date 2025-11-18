import 'scope_deps.dart';

sealed class ScopeDepsState<P extends Object?, D extends ScopeDeps> {}

sealed class ScopeInitState<P extends Object?, D extends ScopeDeps>
    extends ScopeDepsState<P, D> {}

base class ScopeError<P extends Object?, D extends ScopeDeps>
    extends ScopeDepsState<P, D> {
  final Object error;
  final StackTrace stackTrace;

  ScopeError(this.error, this.stackTrace);

  @override
  int get hashCode => Object.hash(error, stackTrace);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScopeError<P, D> &&
          error == other.error &&
          stackTrace == other.stackTrace;

  @override
  String toString() => '${ScopeError<P, D>}($error)';
}

base class ScopeProgress<P extends Object?, D extends ScopeDeps>
    extends ScopeInitState<P, D> {
  final P value;

  ScopeProgress(this.value);

  @override
  int get hashCode => value.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScopeProgress<P, D> && value == other.value;

  @override
  String toString() => '${ScopeProgress<P, D>}($value)';
}

base class ScopeReady<P extends Object?, D extends ScopeDeps>
    extends ScopeInitState<P, D> {
  final D deps;

  ScopeReady(this.deps);

  @override
  int get hashCode => deps.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ScopeReady<P, D> && deps == other.deps;

  @override
  String toString() => '${ScopeReady<P, D>}()';
}
