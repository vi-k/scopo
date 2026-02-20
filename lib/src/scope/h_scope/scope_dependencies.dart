part of '../scope.dart';

/// A container for dependencies (e.g., repositories, services).
///
/// {@category Scope}
// ignore: one_member_abstracts
abstract interface class ScopeDependencies {
  void unmount();

  FutureOr<void> dispose();
}

extension ScopeDependenciesExtension on ScopeDependencies {
  Stream<ScopeInitState<P, T>>
      asStream<P extends Object, T extends ScopeDependencies>() =>
          Stream.value(ScopeReady(this as T));
}
