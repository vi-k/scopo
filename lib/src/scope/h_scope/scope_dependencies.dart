part of '../scope.dart';

/// A container for dependencies (e.g., repositories, services).
// ignore: one_member_abstracts
abstract base class ScopeDependencies {
  const ScopeDependencies();

  Stream<ScopeInitState<P, T>>
      asStream<P extends Object?, T extends ScopeDependencies>() =>
          Stream.value(ScopeReady(this as T));

  FutureOr<void> dispose();
}
