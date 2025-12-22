// part of 'scope.dart';

// @immutable
// sealed class _ScopeDepsState<P extends Object, D extends ScopeDeps> {}

// /// The base class for the state of the scope initialization stream. It has two
// /// subclasses:
// ///
// /// - `ScopeProgress<P, D>`: Emitted to report progress. It carries a value of
// ///    type `P` (e.g., `double`, `String`, `int`).
// /// - `ScopeReady<P, D>`: Emitted when initialization is complete. It carries
// ///    the initialized dependencies of type `D extends ScopeDeps`.
// ///
// /// ```dart
// /// static Stream<ScopeInitState<double, MyFeatureDeps>> init() async* {
// ///   // Report progress
// ///   yield ScopeProgress(0.5);
// ///
// ///   // Report readiness
// ///   yield ScopeReady(MyFeatureDeps(...));
// /// }
// sealed class ScopeInitState<P extends Object, D extends ScopeDeps>
//     extends _ScopeDepsState<P, D> {}

// final class _ScopeError<P extends Object, D extends ScopeDeps>
//     extends _ScopeDepsState<P, D> {
//   final Object error;
//   final StackTrace stackTrace;

//   _ScopeError(this.error, this.stackTrace);

//   @override
//   int get hashCode => Object.hash(error, stackTrace);

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is _ScopeError<P, D> &&
//           error == other.error &&
//           stackTrace == other.stackTrace;

//   @override
//   String toString() => '${_ScopeError<P, D>}($error)';
// }

// final class _ScopeInitial<P extends Object, D extends ScopeDeps>
//     extends _ScopeDepsState<P, D> {
//   P? get value => null;
// }

// final class ScopeProgress<P extends Object, D extends ScopeDeps>
//     extends ScopeInitState<P, D> {
//   final P value;

//   ScopeProgress(this.value);

//   @override
//   int get hashCode => value.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is ScopeProgress<P, D> && value == other.value;

//   @override
//   String toString() => '${ScopeProgress<P, D>}($value)';
// }

// final class ScopeReady<P extends Object, D extends ScopeDeps>
//     extends ScopeInitState<P, D> {
//   final D deps;

//   ScopeReady(this.deps);

//   @override
//   int get hashCode => deps.hashCode;

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) || other is ScopeReady<P, D> && deps == other.deps;

//   @override
//   String toString() => '${ScopeReady<P, D>}()';
// }
